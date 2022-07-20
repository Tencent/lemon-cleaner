 //
//  McLocalSoft.m
//  QMApplication
//
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "McLocalSoft.h"
#import "NSString+Extension.h"
#import "NSFileManager+Extension.h"

@implementation McLocalSoft
@synthesize bundleID;
@synthesize appName;
@synthesize executableName;
@synthesize version;
@synthesize buildVersion;
@synthesize copyright;
@synthesize bundlePath;
@synthesize minSystem;
@synthesize bundleSize;
@synthesize modifyDate;
@synthesize icon;
@synthesize type;

+ (id)softWithPath:(NSString *)filePath
{
    NSBundle *bundle = [NSBundle bundleWithPath:filePath];
    if (!bundle)
    {
        return nil;
    }
    return [self softWithBundle:bundle];
}

+ (NSString *)getAppNameWithInfo:(NSDictionary *)infoDict filePath:(NSString *)appFilePath {
    NSString *appNameString = [infoDict objectForKey:(NSString *)kCFBundleNameKey];
    if (![appNameString isKindOfClass:[NSString class]] || [appNameString length] == 0)
    {
        appNameString = [[appFilePath lastPathComponent] stringByDeletingPathExtension];
        if ([appNameString length] == 0)
        {
            return nil;
        }
    }
    return appNameString;
}

+ (void)setAppShortVersion:(NSString **)shortVersionRef buildVersion:(NSString **)buildVersionRef info:(NSDictionary *)infoDict{
    NSString *version = @"";
    NSString *buildVersion = @"";
    NSString *shortVersion = nil;
    NSString *shortVersionStr = [infoDict objectForKey:@"CFBundleShortVersionString"];
    if ([shortVersionStr isKindOfClass:[NSString class]] && shortVersionStr.length > 0)
        shortVersion = [shortVersionStr versionString];
    
    NSString *bundleVersion = nil;
    NSString *bundleVersionStr = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
    if ([bundleVersionStr isKindOfClass:[NSString class]] && bundleVersionStr.length > 0)
        bundleVersion = [bundleVersionStr versionString];
    
    //当两个版本号都不存在时，给定一个默认值
    if (!shortVersion && !bundleVersion)
        version = @"0.0";
    
    //当shortVersion不存在，采用bundleVersion
    if (!shortVersion)
        version = bundleVersion;
    
    //当bunleVerion不存在,采用shortVersion
    else if (!bundleVersion)
        version = shortVersion;
    
    //当两者相同时，仅保留shortVersion
    else if ([shortVersion isEqualToString:bundleVersion])
        version = shortVersion;
    
    //当shortVersion以bundleVersion开始或结尾，仅保留shortVersion
    else if ([shortVersion hasPrefix:bundleVersion] || [shortVersion hasSuffix:bundleVersion])
        version = shortVersion;
    
    //当bundleVersion以shortVersion开始或结尾，仅保留bundleVersion
    else if ([bundleVersion hasPrefix:shortVersion] || [bundleVersion hasSuffix:shortVersion])
        version = bundleVersion;
    
    //其它情况
    else
    {
        NSArray *shortItems = [shortVersion componentsSeparatedByString:@"."];
        NSArray *bundleItems = [bundleVersion componentsSeparatedByString:@"."];
        
        //处理写法不一样：3.00与3.0.XXX,取位数长的版本号
        BOOL numberSame = YES;
        for (int i=0; i<shortItems.count && i<bundleItems.count; i++)
        {
            if ([shortItems[i] intValue] != [bundleItems[i] intValue])
            {
                numberSame = NO;
                break;
            }
        }
        
        //如果是相同的表达方式，取位数长的版本号
        if (numberSame)
            version = shortItems.count>bundleItems.count?shortVersion:bundleVersion;
        
        //否则认定是版本号+编译号
        else
        {
            version = shortVersion;
            buildVersion = bundleVersion;
        }
    }
    *shortVersionRef = shortVersion;
    *buildVersionRef = buildVersion;
}

+ (NSString *)getCopyRightWithInfo:(NSDictionary *)infoDict {
    NSString *copyrightString = [infoDict objectForKey:@"CFBundleGetInfoString"];
    if (![copyrightString isKindOfClass:[NSString class]] || [copyrightString length] == 0)
    {
        copyrightString = [infoDict objectForKey:@"NSHumanReadableCopyright"];
    }
    if ([copyrightString isKindOfClass:[NSString class]] && [copyrightString length] != 0)
    {
        return copyrightString;
    }
    return nil;
}

+ (void)setBundleSize:(NSNumber **)bundleSizeRef createDate:(NSDate **)createDateRef modifyDate:(NSDate **)modifyDateRef filePath:(NSString *)appFilePath{
    NSNumber *bundleSize;
    NSDate *createDate;
    NSDate *modifyDate;
    //优先通过Spotlight来获取size和date
    MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef)appFilePath);
    if (item)
    {
        NSNumber *size = (__bridge_transfer NSNumber*)MDItemCopyAttribute(item,kMDItemFSSize);
        if (size && [size isKindOfClass:[NSNumber class]])
        {
            bundleSize = size;
        }
        
        //create date
        NSDate *tempCreateDate = (__bridge_transfer NSDate *)MDItemCopyAttribute(item, kMDItemDateAdded);
        if (tempCreateDate && [tempCreateDate isKindOfClass:[NSDate class]])
        {
            createDate = tempCreateDate;
        }
        //modity date
        NSDate *localModDate = (__bridge_transfer NSDate *)MDItemCopyAttribute(item, kMDItemLastUsedDate);
        if (localModDate && [localModDate isKindOfClass:[NSDate class]])
        {
            modifyDate = localModDate;
        }
        CFRelease(item);
    }else
    {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:appFilePath error:NULL];
        
        NSNumber *size = [attributes objectForKey:NSFileSize];
        if (size && [size isKindOfClass:[NSNumber class]])
        {
            bundleSize = size;
        }
        
        NSDate *tempCreateDate = [attributes objectForKey:NSFileCreationDate];
        if (tempCreateDate && [tempCreateDate isKindOfClass:[NSDate class]])
        {
            createDate = tempCreateDate;
        }
        
        NSDate *localModDate = [attributes objectForKey:NSFileModificationDate];
        if (localModDate && [localModDate isKindOfClass:[NSDate class]])
        {
            modifyDate = localModDate;
        }
    }
    *bundleSizeRef = bundleSize;
    *createDateRef = createDate;
    *modifyDateRef = modifyDate;
}

+ (id)softWithBundle:(NSBundle *)bundle
{
    if (!bundle)
    {
        return nil;
    }
    
    NSString *appFilePath = [bundle bundlePath];
    NSDictionary *infoDict = nil;
    
    /*
     获取info信息，先通过读取plist文件，这样的效率更高，如果读取失败(比如文件名不是Info.plist),
     则直接调用infoDictionary方法获取到Info信息。
     */
    NSString *infoPath = [appFilePath stringByAppendingString:@"/Contents/Info.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath])
    {
        infoDict = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
    }
    if (!infoDict)
    {
        infoDict = [bundle infoDictionary];
    }
    
    if (!infoDict)
    {
        return nil;
    }
    
    //获取bundleID
    NSString *bundleIDString = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
    if ([bundleIDString length] == 0)
    {
        return nil;
    }
    
    /*
     获取App Name,先通过读取Info字典获取，如果失败直接取文件名
     */
    NSString *appNameString = [self getAppNameWithInfo:infoDict filePath:appFilePath];
    if (!appNameString) {
        return nil;
    }
    
    McLocalSoft * soft = [[McLocalSoft alloc] init];
    soft.bundleID = bundleIDString;
    soft.appName = appNameString;
    soft.bundlePath = appFilePath;
    
    //获得显示名字
    NSString *displayName = [[bundle localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (![displayName isKindOfClass:[NSString class]] || displayName.length == 0)
    {
        displayName = [[appFilePath lastPathComponent] stringByDeletingPathExtension];
        if (displayName.length == 0)
        {
            displayName = appNameString;
        }
    }
    soft.showName = displayName;
    
    //获取可执行文件的名字
    NSString *executableNameString = [infoDict objectForKey:(NSString *)kCFBundleExecutableKey];
    if (![executableNameString isKindOfClass:[NSString class]] || [executableNameString length] == 0)
    {
        executableNameString = [[bundle executablePath] lastPathComponent];
        if ([executableNameString length] == 0)
        {
            executableNameString = appNameString;
        }
    }
    soft.executableName = executableNameString;
    
    //获取最小系统兼容版本
    NSString *minSystemString = [infoDict objectForKey:@"LSMinimumSystemVersion"];
    if ([minSystemString isKindOfClass:[NSString class]] && [minSystemString length] > 0)
    {
        soft.minSystem = minSystemString;
    }
        
    //获取版本号
    NSString *tempVersion;
    NSString *tempBuildVersion;
    [self setAppShortVersion:&tempVersion buildVersion:&tempBuildVersion info:infoDict];
    soft.version = tempVersion;
    soft.buildVersion = tempBuildVersion;
    
    //获取copyright
    soft.copyright = [self getCopyRightWithInfo:infoDict];
    
    NSNumber *bundleSize;
    NSDate *createDate;
    NSDate *modifyDate;
    [self setBundleSize:&bundleSize createDate:&createDate modifyDate:&modifyDate filePath:appFilePath];
    soft.bundleSize = bundleSize;
    soft.createDate = createDate;
    soft.modifyDate = modifyDate;
    
    //通过逐层遍历去计算包大小
    if (!soft.bundleSize || [soft.bundleSize unsignedLongLongValue] == 0)
    {
        uint64 fileSize = [[NSFileManager defaultManager] diskSizeAtPath:appFilePath];
        soft.bundleSize = [NSNumber numberWithUnsignedLongLong:fileSize];
    }
    
    //获取图标
    @try
    {
        NSImage * iconImage = nil;
        iconImage = [[NSWorkspace sharedWorkspace] iconForFile:appFilePath];
        
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(32, 32)];
            soft.icon = iconImage;
        }
    }
    @catch (NSException *exception)
    {
        soft.icon = nil;
    }
    
    //设置默认的图标
    if (!soft.icon)
    {
        static NSImage *defaultIcon = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
            [defaultIcon setSize:NSMakeSize(32, 32)];
        });
        soft.icon = defaultIcon;
    }
    return soft;
}

- (BOOL)needUpdateWithNetVersion:(NSString *)netVersion
{
    NSString *netMainVersion = [netVersion versionString];
    NSString *netBuildVersion = [netVersion buildVersionString];
    
    if (!netMainVersion)
        return NO;
    
    NSComparisonResult mainCompareRe = [self.version compare:netMainVersion options:NSNumericSearch];
    
    if (mainCompareRe == NSOrderedAscending)
    {
        return YES;
    }
    else if (mainCompareRe == NSOrderedSame && netBuildVersion)
    {
        if (!self.buildVersion || [self.buildVersion compare:netBuildVersion options:NSNumericSearch]==NSOrderedAscending)
            return YES;
    }
    
    return NO;
}

- (NSComparisonResult)compareVersion:(McLocalSoft *)localSoft
{
    if (!localSoft || !localSoft.version)
    {
        return NSOrderedDescending;
    }
    
    if (!self.version)
    {
        return NSOrderedAscending;
    }
    
    NSComparisonResult result = [self.version compare:localSoft.version options:NSNumericSearch];
    
    if (result == NSOrderedSame)
    {
        if (self.buildVersion && !localSoft.buildVersion)
            result = NSOrderedDescending;
        else if (!self.buildVersion && localSoft.buildVersion)
            result = NSOrderedAscending;
        else if (self.buildVersion && localSoft.buildVersion)
            result = [self.buildVersion compare:localSoft.buildVersion options:NSNumericSearch];
    }
    
    return result;
}

@end

