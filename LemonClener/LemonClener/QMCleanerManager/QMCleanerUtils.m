//
//  QMCleanerUtils.m
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMCleanerUtils.h"
#import "QMDataConst.h"
#import <QMCoreFunction/QMDataCenter.h>
#import <QMCoreFunction/QMNetworkClock.h>
#import <QMCoreFunction/QMTimeHelp.h>
#import <QMCoreFunction/NSDate+Extension.h>

@implementation QMCleanerUtils

+ (BOOL)checkLanguageCanRemove:(NSString *)path
{
    NSString * fileName = [path lastPathComponent];
    NSString * resoucesPath = [path stringByDeletingLastPathComponent];
    NSArray * contentArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resoucesPath
                                                                                 error:nil];
    for (NSString * contentPath in contentArray)
    {
        if ([[contentPath pathExtension] isEqualToString:@"lproj"]
            && ![contentPath isEqualToString:fileName])
        {
            return YES;
        }
    }
    return NO;
}

+ (void)removeUserLoginItem:(NSString *)loginName
{
    // Create a reference to the shared file list.
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems,
                                                            NULL);
    
    if (loginItems)
    {
        UInt32 seedValue;
        NSFileManager * fm = [NSFileManager defaultManager];
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray  *loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for(int i = 0; i< [loginItemsArray count]; i++)
        {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                 objectAtIndex:i];
            if (!itemRef)
                continue;
            
            NSString * displayName = (__bridge_transfer NSString *)(LSSharedFileListItemCopyDisplayName(itemRef));
            if (!displayName || ![displayName isEqualToString:loginName])
                continue;
            CFURLRef url;
			//Resolve the item with URL
            BOOL needRemove = NO;
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr)
            {
				NSString * urlPath = [(__bridge NSURL*)url path];
                if (![fm fileExistsAtPath:urlPath])
                {
                    needRemove = YES;
                }
			}
            else
            {
                needRemove = YES;
            }
            if (needRemove)
                LSSharedFileListItemRemove(loginItems, itemRef);
        }
        CFRelease(loginItems);
    }

}


+ (NSString *)getPathWithRunProcess:(NSString *)bundleID appName:(NSString *)name pid:(pid_t *)pid
{
    if (bundleID == nil)
        return nil;
    
    NSArray * runApps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication * runApp in runApps)
    {
        NSString * processBundle = runApp.bundleIdentifier;
        NSString * processName = runApp.localizedName;
        if ((processBundle && [processBundle rangeOfString:bundleID options:NSCaseInsensitiveSearch].length != 0)
            || (processName && [processName compare:name options:NSCaseInsensitiveSearch] == NSOrderedSame))
        {
            *pid = runApp.processIdentifier;
            return [[runApp bundleURL] path];
        }
    }
    return nil;
}

+ (void)saveCurrentCleanSize:(NSUInteger)size
{
    if (size == 0)
        return;
    QMDataCenter * dataCenter = [QMDataCenter defaultCenter];
    NSMutableDictionary * dict = [[dataCenter objectForKey:kQMMothCleanSize] mutableCopy];
    if (!dict) dict = [NSMutableDictionary dictionary];
    
    // 获取当前到1970-1的月数
    NSInteger monthCount = [QMTimeHelp mothsBetweenDate:[NSDate dateWithTimeIntervalSince1970:0]
                                                 toDate:[NSDate networkTime]];
    if (monthCount == NSUIntegerMax)
        return;
    NSString * monthKey = [NSString stringWithFormat:@"%ld", monthCount];
    UInt64 monthCleanSize = [[dict objectForKey:monthKey] unsignedLongLongValue];
    monthCleanSize += size;
    [dict setObject:[NSNumber numberWithUnsignedLongLong:monthCleanSize] forKey:monthKey];
    
    if ([dict count] > 5)
    {
        NSString * removeKey = nil;
        NSInteger curMonth = monthCount;
        for (NSString * key in dict.allKeys)
        {
            NSInteger month = [key integerValue];
            if (curMonth > month)
            {
                removeKey = key;
                curMonth = month;
            }
        }
        if (!removeKey)
        {
            for (NSString * key in dict.allKeys)
            {
                NSInteger month = [key integerValue];
                if (curMonth < month)
                {
                    removeKey = key;
                    curMonth = month;
                }
            }
        }
        if (removeKey)
            [dict removeObjectForKey:removeKey];
    }
    
    // 保存
    [dataCenter setObject:dict forKey:kQMMothCleanSize];
}

+ (NSDictionary *)imageNameMap
{
    static NSDictionary *categoryImageMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        categoryImageMap = @{@"1" : @"icon_log_cache",
                             @"2" : @"icon_dev_residual",
                             @"3" : @"icon_useless_binary",
                             @"4" : @"icon_language",
                             @"5" : @"icon_damanged_settings",
                             @"6" : @"icon_ios",
                             @"7" : @"icon_app_residual",
                             @"8" : @"icon_browser_cache"};
    });
    return categoryImageMap;
}

+ (NSImage *)iconWithCategoryID:(NSString *)categoryID highlight:(BOOL)highlight
{
    if (!categoryID)
        return nil;
    
    static NSDictionary *iconDic = nil;
    static NSDictionary *iconHLDic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSMutableDictionary *imageDic = [NSMutableDictionary dictionaryWithCapacity:8];
        NSMutableDictionary *imgHLDic = [NSMutableDictionary dictionaryWithCapacity:8];
        
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        NSDictionary *imageNameMap = [self imageNameMap];
        for (NSString *curID in imageNameMap)
        {
            NSString *imageName = imageNameMap[curID];
            if (!imageName)
                continue;
            
            NSImage *image = [bundle imageForResource:imageName];
            if (!image)
                continue;
            [imageDic setObject:image forKey:curID];
            
            NSString *imageNameHL = [imageName stringByAppendingString:@"_hover"];
            NSImage *imageHL = [bundle imageForResource:imageNameHL];
            if (!imageHL)
                continue;
            [imgHLDic setObject:imageHL forKey:curID];
        }
        
        iconDic = [NSDictionary dictionaryWithDictionary:imageDic];
        iconHLDic = [NSDictionary dictionaryWithDictionary:imgHLDic];
    });
    
    return highlight ? iconHLDic[categoryID] : iconDic[categoryID];
}


@end
