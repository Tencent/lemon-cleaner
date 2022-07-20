//
//  QMAppUnlessFile.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMAppUnlessFile.h"
#import <mach-o/fat.h>
#import <libkern/OSByteOrder.h>
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import "QMCoreFunction/QMDataCenter.h"
#import "QMDataConst.h"
#import "QMCleanUtils.h"
#import "CutBinary.h"
#import "InstallAppHelper.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#include <sys/sysctl.h>

#define MAX_FAT_HEADER_SIZE (20*20)

#define kFileEnumerator(path,flags) [fm enumeratorAtURL:[NSURL fileURLWithPath:path]\
includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsAliasFileKey, NSURLIsExecutableKey, NSURLIsDirectoryKey, NSURLNameKey, nil]\
options:flags errorHandler:nil]

#define kWhiteAppleAppBundleID @[@"com.apple.Safari",@"com.apple.dt.Xcode",@"com.apple.appleseed.FeedbackAssistant"]
#define kWhiteCommonAppBundleID @[@"com.microsoft.VSCode",@"com.parallels.desktop.console"]

@implementation QMAppUnlessFile
@synthesize delegate;

- (id)init
{
    if (self = [super init])
    {
        NSArray *totalLangs = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        if ([totalLangs count] > 0)
        {
            NSString * curSysLanguage = [totalLangs objectAtIndex:0];
            NSString *normIdentifier = [NSLocale canonicalLocaleIdentifierFromString:curSysLanguage];
            NSRange range = [normIdentifier rangeOfString:@"-"];
            if (range.length != 0)
            {
                normIdentifier = [normIdentifier substringToIndex:range.location];
            }
            _normIdentifier = normIdentifier;
        }
        m_unlessNibArray = [NSMutableArray arrayWithObjects:@"designable.nib", @"info.nib", @"classes.nib", nil];
    }
    return self;
}


- (void)scanAppUnlessLanguage:(QMActionItem *)actionItem
{
    NSMutableDictionary * languagesResult = [[NSMutableDictionary alloc] init];
    m_languageFilter = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [m_languageFilter enumeratorAtFilePath:actionItem];
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        NSString * appPath = result;
        // get bundle
        NSBundle * appBundle = [NSBundle bundleWithPath:appPath];
        if (appBundle == nil)
            continue;
        
        // 枚举路径
        NSFileManager * fm = [NSFileManager defaultManager];
        NSDirectoryEnumerationOptions optionFlags = (actionItem.cleanhiddenfile ? NSDirectoryEnumerationSkipsHiddenFiles : 0);
        NSDirectoryEnumerator * dirEnumerator = kFileEnumerator(appPath, optionFlags);
        
        //NSMutableArray * contentLanguages = [[NSMutableArray alloc] init];
        NSMutableDictionary * lprojFileDict = [[NSMutableDictionary alloc] init];
        for (NSURL * pathURL in dirEnumerator)
        {
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsAliasFileKey])
                continue;
            
            // 处理目录
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsDirectoryKey])
            {
                NSString * fileName = nil;
                [pathURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
                // 必须是/Resouces/*.lproj结构
                if ([fileName isEqualToString:@"Resources"])
                {
                    [dirEnumerator skipDescendants];
                    NSArray * resourcesArray = [fm contentsOfDirectoryAtURL:pathURL
                                                 includingPropertiesForKeys:nil
                                                                    options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                      error:nil];
                    for (NSURL * subResourcesPath in resourcesArray)
                    {
                        NSString * fileName = nil;
                        [subResourcesPath getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
                        if (![[fileName pathExtension] isEqualToString:@"lproj"])
                            continue;
                        
                        NSString * lprojPath = [subResourcesPath path];
                        NSString * parentPath = [pathURL path];
                        NSMutableArray * subFileArray = [lprojFileDict objectForKey:parentPath];
                        if (!subFileArray) subFileArray = [NSMutableArray array];
                        [subFileArray addObject:lprojPath];
                        [lprojFileDict setObject:subFileArray forKey:parentPath];
                        
                        // 进度信息
                        if ([delegate scanProgressInfo:((i + 0.0) / [pathArray count]) scanPath:appPath resultItem:nil])
                        {
                            return;
                        }
                    }
                }
            }
            // 进度信息
            if ([delegate scanProgressInfo:((i + 0.0) / [pathArray count]) scanPath:appPath resultItem:nil])
            {
                return;
            }
        }
        
        // 进度信息
        if ([delegate scanProgressInfo:((i + 0.0) / [pathArray count]) scanPath:appPath resultItem:nil])
        {
            return;
        }
        
        NSMutableDictionary * appCacheDict = [[NSMutableDictionary alloc] init];
        for (NSString * key in lprojFileDict.allKeys)
        {
            NSArray * contentLanguages = [lprojFileDict objectForKey:key];
            // 获取结果
            if ([contentLanguages count] > 1)
            {
                int j = 0;
                for (NSString * resourcesSubPath in contentLanguages)
                {
                    // 合并zh-cn,zh-tw为zh
                    NSString * languageID = [NSLocale canonicalLanguageIdentifierFromString:[[resourcesSubPath lastPathComponent] stringByDeletingPathExtension]];
                    if (!languageID || [languageID isEqualToString:@""])
                        continue;
                    
                    NSRange range = [languageID rangeOfString:@"-"];
                    if (range.length != 0)
                    {
                        languageID = [languageID substringToIndex:range.location];
                    }
                    // 过滤语言
                    
                    
                    // 根据配置过滤语言
                    NSArray * keepLanguages = [[QMDataCenter defaultCenter] objectForKey:kQMCleanerKeepLanguages];
                    NSArray * defaultKeepLanguages = [[QMDataCenter defaultCenter] objectForKey:kQMCleanerDefaultKeepLanguages];
                    if ([_normIdentifier isEqualToString:languageID]
                        || [keepLanguages containsObject:languageID]
                        || [defaultKeepLanguages containsObject:languageID])
                        continue;
                    
                    if (![m_languageFilter filterPathWithFilters:languageID])
                        continue;
                    
                    NSString * displayName = [[NSLocale systemLocale] displayNameForKey:NSLocaleIdentifier value:languageID];
                    if (displayName == nil || [@"" isEqualToString:displayName])
                        continue;
                    // 设置语言key
                    NSString * languageName = [[NSLocale systemLocale] displayNameForKey:NSLocaleIdentifier value:languageID];
                    
                    
                    QMResultItem * languageItem = nil;
                    if ([[languagesResult allKeys] containsObject:languageName])
                    {
                        languageItem = [languagesResult objectForKey:languageName];
                    }
                    else
                    {
                        languageItem = [[QMResultItem alloc] initWithLanguageKey:languageName];
                        [languagesResult setObject:languageItem forKey:languageName];
                        languageItem.cleanType = actionItem.cleanType;
                        NSImage * image = [[NSBundle mainBundle] imageForResource:languageID];
                        if (image)
                            languageItem.iconImage = image;
                        else
                            languageItem.iconImage = [[NSBundle mainBundle] imageForResource:@"languages"];
                    }
                    
                    NSString * key = [NSString stringWithFormat:@"%@_%@", appPath, languageID];
                    QMResultItem * resultItem = [appCacheDict objectForKey:key];
                    if (!resultItem)
                    {
                        resultItem = [[QMResultItem alloc] initWithPath:appPath];
                        resultItem.languageKey = languageID;
                        resultItem.cleanType = actionItem.cleanType;
                    }
                    [resultItem addResultWithPath:resourcesSubPath];
                    [resultItem setShowHierarchyType:4];
                    [languageItem addSubResultItem:resultItem];
                    [appCacheDict setObject:resultItem forKey:key];
                    
                    j++;
                    // 进度信息
                    if ([delegate scanProgressInfo:(i + (j + 0.0) / [contentLanguages count]) / [pathArray count] scanPath:result resultItem:languageItem])
                    {
                        return;
                    }
                }
            }
            
        }
        
        /*
         NSString * resourcesPath = [appBundle resourcePath];
         [self scanApplprojFile:resourcesPath];
         
         NSString * privateFrameWork = [appBundle privateFrameworksPath];
         [self scanApplprojFile:privateFrameWork];
         */
    }
}

- (void)scanSubFrameworks:(NSString *)frameworksDir
               filesArray:(NSMutableArray *)files
               sizesArray:(NSMutableArray *)sizes
{
    NSFileManager * fileMange = [NSFileManager defaultManager];
    NSArray *subFrameworks = [fileMange contentsOfDirectoryAtPath:frameworksDir
                                                            error:nil];
    
    uint64_t cut_size = 0;
    for (NSString *frameworkName in subFrameworks)
    {
        NSString *subFramework = [frameworksDir stringByAppendingPathComponent:frameworkName];
        BOOL isDir;
        // must be a folder
        if ([fileMange fileExistsAtPath:subFramework isDirectory:&isDir]
            && isDir)
        {
            NSBundle *frameBunble = [NSBundle bundleWithPath:subFramework];
            if (frameBunble != nil && [frameBunble executablePath] != nil)
            {
                cut_size = testFileArch([[frameBunble executablePath] fileSystemRepresentation]);
                if (cut_size != 0)
                {
                    // resolve symbolic here
                    NSString *realPath = [frameBunble executablePath];
                    NSString *symbolicPath = [fileMange destinationOfSymbolicLinkAtPath:realPath
                                                                                  error:NULL];
                    if (symbolicPath != nil)
                    {
                        if (![symbolicPath hasPrefix:@"/"])
                        {
                            realPath = [[realPath stringByDeletingLastPathComponent]
                                        stringByAppendingPathComponent:symbolicPath];
                        }
                        else
                        {
                            realPath = symbolicPath;
                        }
                    }
                    
                    //NSLog(@"[add]%@", realPath);
                    [files addObject:realPath];
                    [sizes addObject:[NSNumber numberWithUnsignedLongLong:cut_size]];
                }
            }
        }
    }
}

- (void)scanAppBinaries:(NSString *)executablePath
              machFiles:(NSMutableArray **)machFiles
               cutSizes:(NSUInteger *)cutSizes
{
//    NSBundle * appBundle = [NSBundle bundleWithPath:appPath];
//    if (appBundle == nil)
//        return;
    
    //*machFiles = [NSMutableArray arrayWithCapacity:20];
    //*cutSizes = [NSMutableArray arrayWithCapacity:20];
    
    uint64_t cut_size = 0;
    
    // only care about main executable file
    cut_size = testFileArch([executablePath fileSystemRepresentation]);
    if (cut_size != 0)
    {
        //[*machFiles addObject:executablePath];
        //[*cutSizes addObject:[NSNumber numberWithUnsignedLongLong:cut_size]];
        *cutSizes += cut_size;
    }
    
    /*
    // frameworks
    [self scanSubFrameworks:[appBundle privateFrameworksPath]
                 filesArray:*machFiles
                 sizesArray:*cutSizes];
    
    if (![[appBundle sharedFrameworksPath] isEqualToString:[appBundle privateFrameworksPath]])
    {
        [self scanSubFrameworks:[appBundle sharedFrameworksPath]
                     filesArray:*machFiles
                     sizesArray:*cutSizes];
        
    }
    
    // plugins
    [self scanSubFrameworks:[appBundle builtInPlugInsPath]
                 filesArray:*machFiles
                 sizesArray:*cutSizes];
     */
    
}

- (void)scanAppUnlessBinary:(QMActionItem *)actionItem
{
    NSMutableDictionary * retDict = [NSMutableDictionary dictionary];
    
    QMFilterParse * binaryFilter = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [binaryFilter enumeratorAtFilePath:actionItem];
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        
        NSString * appPath = result;
        
        // 枚举路径
        NSFileManager * fm = [NSFileManager defaultManager];
        NSDirectoryEnumerationOptions optionFlags = (actionItem.cleanhiddenfile ? NSDirectoryEnumerationSkipsHiddenFiles : 0);
        NSDirectoryEnumerator * dirEnumerator = kFileEnumerator(appPath, optionFlags);
        
        NSMutableArray * binaryArray = [NSMutableArray array];
        for (NSURL * pathURL in dirEnumerator)
        {
            // 过滤快捷方式
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsAliasFileKey])
                continue;
            
            // 处理目录
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsDirectoryKey])
            {
                NSString * pathExtension = [pathURL pathExtension];
                if ([pathExtension isEqualToString:@"lproj"] || [pathExtension isEqualToString:@"nib"])
                {
                    [dirEnumerator skipDescendants];
                    continue;
                }
            }
            else
            {
                if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsExecutableKey])
                {
                    [binaryArray addObject:[pathURL path]];
                }
            }
            if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:nil])
                return;
        }
        QMResultItem * resultItem = nil;
        for (NSString * executablePath in binaryArray)
        {
            
            if (![binaryFilter filterPathWithFilters:executablePath])
                continue;
            //NSMutableArray * machFiles = nil;
            //NSMutableArray * cutSizes = nil;
            NSUInteger cutSizes = 0;
//            [self scanAppBinaries:executablePath
//                        machFiles:nil
//                         cutSizes:&cutSizes];
            NSFileManager *manager = [NSFileManager defaultManager];
            cutSizes = [manager attributesOfItemAtPath:executablePath error:nil].fileSize;
            
            if (cutSizes > 0)
            {
                if ([retDict objectForKey:appPath])
                    resultItem = [retDict objectForKey:appPath];
                else
                    resultItem = [[QMResultItem alloc] initWithPath:appPath];
                resultItem.cleanType = actionItem.cleanType;
                [resultItem addResultWithPath:executablePath];
                [resultItem setFileSize:(cutSizes + [resultItem resultFileSize])];
                
//                NSMutableArray * array = [retDict objectForKey:appPath];
//                if (array) [array addObjectsFromArray:machFiles];
//                else array = machFiles;
                [retDict setObject:resultItem forKey:appPath];
            }
            if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:nil])
                break;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            return;
    }
}

- (void)scanAppInstallPackage:(QMActionItem *)actionItem{
    
    NSString *shellString = @"mdfind -onlyin \'%@\' 'kMDItemKind = \"磁盘映像\" || kMDItemKind = \"Disk Image\"'";
    NSArray *pathArray = @[[@"~/Downloads" stringByExpandingTildeInPath],[@"~/Desktop" stringByExpandingTildeInPath],[@"~/Library/Containers/com.tencent.WeWorkMac/Data/Documents/Profiles" stringByExpandingTildeInPath]];
    
    for (NSString *path in pathArray) {
        NSString *cmd = [NSString stringWithFormat:shellString, path];
        NSString *retString = [QMShellExcuteHelper excuteCmd:cmd];
        if (retString == nil || [retString isEqualToString:@""]) {
            continue;
        }
        NSArray *pathItemArray = [retString componentsSeparatedByString:@"\n"];
        if ((pathItemArray == nil) || ([pathItemArray count] == 0)) {
            continue;
        }
       
        for (int i = 0; i < [pathItemArray count]; i++)
        {
            
            NSString *result = [pathItemArray objectAtIndex:i];
            // 忽略img文件
            if ([result hasSuffix:@".img"]){
                continue;
            }
            
            if (result == nil || [result isEqualToString:@""]) {
                continue;
            }
            QMResultItem * resultItem = nil;
            NSString * fileName = [result lastPathComponent];
            NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:fileName];
            if (appPath)
            {
                resultItem = [[QMResultItem alloc] initWithPath:appPath];
                resultItem.path = result;
            }
            else
            {
                resultItem = [[QMResultItem alloc] initWithPath:result];
            }
            resultItem.cleanType = actionItem.cleanType;
            
            // 添加结果
            if (resultItem) [resultItem addResultWithPath:result];
    
            if ([delegate respondsToSelector:@selector(scanProgressInfo:scanPath:resultItem:)]) {
                [delegate scanProgressInfo:(1 + 1.0) / [pathItemArray count] scanPath:result resultItem:resultItem];
            }
        }
        
    }
}

- (void)scanAppGeneralBinary:(QMActionItem *)actionItem {
   
    NSMutableDictionary *installBundleIdDic = [InstallAppHelper getInstallBundleIds];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSString *appBundleId in installBundleIdDic.allKeys) {
        dispatch_group_async(group, queue, ^{
            //苹果app白名单 普通app白名单
            if (![kWhiteAppleAppBundleID containsObject:appBundleId] && ![kWhiteCommonAppBundleID containsObject:appBundleId]) {
                NSString *appPath = [installBundleIdDic objectForKey:appBundleId];
                
                NSError * err = nil;
                NSFileManager * manager = [NSFileManager defaultManager];
        //        NSArray * dirArr = [manager subpathsOfDirectoryAtPath:appPath error:&err];
        //        NSLog(@"dirArr-->%lu",dirArr.count);
                NSMutableArray *arr = [NSMutableArray array];
                NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
                int total = 0;
                
                NSMutableArray * dirArr = [NSMutableArray array];
                NSString *macOSPath = [NSString stringWithFormat:@"%@/Contents/MacOS",appPath];
                NSArray *macOSArr = [manager subpathsOfDirectoryAtPath:macOSPath error:&err];
                if (macOSArr != nil && macOSArr.count > 0) {
                    for (NSString *str in macOSArr) {
                        NSString *path = [NSString stringWithFormat:@"%@/%@",macOSPath,str];
                        [dirArr addObject:path];
                    }
                    
                }
                
                NSString *frameworksPath = [NSString stringWithFormat:@"%@/Contents/Frameworks",appPath];
                NSArray *frameworksArr = [manager subpathsOfDirectoryAtPath:frameworksPath error:&err];
                if (frameworksArr != nil && frameworksArr.count > 0) {
                    for (NSString *str in frameworksArr) {
                        NSString *path = [NSString stringWithFormat:@"%@/%@",frameworksPath,str];
                        [dirArr addObject:path];
                    }
                }
                
                NSString *libraryPath = [NSString stringWithFormat:@"%@/Contents/Library",appPath];
                NSArray *libraryArr = [manager subpathsOfDirectoryAtPath:libraryPath error:&err];
                if (libraryArr != nil && libraryArr.count > 0) {
                    for (NSString *str in frameworksArr) {
                        NSString *path = [NSString stringWithFormat:@"%@/%@",libraryPath,str];
                        [dirArr addObject:path];
                    }
                }
        
                
                //获取当前app主要框架
                AppBinaryType type = AppBinaryType_None;
                NSString *appBinaryPath = [NSString stringWithFormat:@"%@/Contents/MacOS/",appPath];
                NSArray * appBinaryDir = [manager subpathsOfDirectoryAtPath:appBinaryPath error:&err];
                for (NSString *path in appBinaryDir) {
                    NSString *newPath = [appBinaryPath stringByAppendingPathComponent:path];
                    NSString *description = [workSpace localizedDescriptionForType:[workSpace typeOfFile:newPath error:nil]];
                    if ([description containsString:@"可执行"] || [description containsString:@"Unix executable"]) {
                        NSString *shellString = [NSString stringWithFormat:@"file '%@'",newPath];
                        NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
                        if ([retString containsString:@"x86"] && [retString containsString:@"arm64"]) {
                            type = AppBinaryType_Both;
                        } else if ([retString containsString:@"x86"] && ![retString containsString:@"arm64"]) {
                            type = AppBinaryType_X86;
                        } else if (![retString containsString:@"x86"] && [retString containsString:@"arm64"]) {
                            type = AppBinaryType_Arm64;
                        } else {
                            continue;
                        }
                    }
                }
                
                if (AppBinaryType_None != type) {
                    //获取app中有对应架构的二进制
                    for (NSString *path in dirArr) {
                        NSString *newPath = path;//[appPath stringByAppendingPathComponent:path];
                        NSString *description = [workSpace localizedDescriptionForType:[workSpace typeOfFile:newPath error:nil]];
                        if ([description containsString:@"可执行"] || [description containsString:@"Unix executable"] ) {
                            NSString *shellString = [NSString stringWithFormat:@"file '%@'",newPath];
                            NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
                            
                            if ([retString containsString:@"x86"] && [retString containsString:@"arm64"]) {
                                [arr addObject:newPath];
                                NSDictionary * attributes = [manager attributesOfItemAtPath:newPath error:nil];
                                NSNumber *theFileSize = [attributes objectForKey:NSFileSize];
                                total = total + [theFileSize intValue];
                            }
                        }
                    }
                    
                    QMResultItem * resultItem = nil;
                    if (arr.count != 0) {
                        resultItem = [[QMResultItem alloc] initWithPath:appPath];
                        resultItem.cleanType = actionItem.cleanType;
                        resultItem.binaryType = type;
                        if (resultItem) [resultItem addResultWithPathArray:arr];
                        if ([self.delegate respondsToSelector:@selector(scanProgressInfo:scanPath:resultItem:)]) {
                            [self.delegate scanProgressInfo:(1 + 1.0) / [installBundleIdDic count] scanPath:appPath resultItem:resultItem];
                        }
                    }
                    
                }
            }
        });
    }
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 120ull * NSEC_PER_SEC);
    dispatch_group_wait(group, time);

}

#pragma mark-
#pragma mark scan junck

- (NSArray *)scanAppHeaderInfo:(NSArray *)headersPaths
{
    NSMutableArray * retArray = nil;
    NSFileManager * fileMange = [NSFileManager defaultManager];
    for (NSString *headerPath in headersPaths)
    {
        BOOL isDir = NO;
        if ([fileMange fileExistsAtPath:headerPath isDirectory:&isDir] && isDir)
        {
            NSArray * headersSubPath = [fileMange contentsOfDirectoryAtPath:headerPath error:nil];
            for (NSString * subPath in headersSubPath)
            {
                // .h结尾的文件
                if (![[subPath pathExtension] isEqualToString:@"h"])
                    continue;
                
                // 过滤结果
                NSString * path = [headerPath stringByAppendingPathComponent:subPath];
                if (![m_developerFilter filterPathWithFilters:path])
                    continue;
                
                if (!retArray) retArray = [NSMutableArray array];
                [retArray addObject:path];
            }
        }
    }
    return retArray;
}

- (NSArray *)scanAppResourceNIB:(NSArray *)nibsArray
{
    NSMutableArray * retArray = [NSMutableArray array];
    NSFileManager * fm = [NSFileManager defaultManager];
    for (NSString * path in nibsArray)
    {
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            // 过滤nib文件
            if (![m_developerFilter filterPathWithFilters:path])
                continue;
            NSArray * nibSubPath = [fm contentsOfDirectoryAtPath:path error:nil];
            if ([nibSubPath containsObject:@"keyedobjects.nib"])
            {
                for (NSString * str in m_unlessNibArray)
                {
                    if ([nibSubPath containsObject:str])
                    {
                        NSString * result = [path stringByAppendingPathComponent:str];
                        [retArray addObject:result];
                    }
                }
            }
        }
    }
    return retArray;
}

- (void)scanDeveloperJunck:(QMActionItem *)actionItem
{
    NSMutableDictionary * m_developerResult = [NSMutableDictionary dictionary];
    
    m_developerFilter = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [m_developerFilter enumeratorAtFilePath:actionItem];
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        
        NSString * appPath = result;
        
        // get bundle
        NSBundle * appBundle = [NSBundle bundleWithPath:appPath];
        if (appBundle == nil)
            continue;
        
        // 枚举路径
        NSFileManager * fm = [NSFileManager defaultManager];
        NSDirectoryEnumerationOptions optionFlags = (actionItem.cleanhiddenfile ? NSDirectoryEnumerationSkipsHiddenFiles : 0);
        NSDirectoryEnumerator * dirEnumerator = kFileEnumerator(appPath, optionFlags);
        

        NSMutableArray * headersArray = [NSMutableArray array];
        NSMutableArray * nibsArray = [NSMutableArray array];
        for (NSURL * pathURL in dirEnumerator)
        {
            NSLog(@"path url is = %@-1", [pathURL pathExtension]);
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsAliasFileKey])
                continue;
            NSLog(@"path url is = %@-2", [pathURL pathExtension]);
            // 处理目录
            if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsDirectoryKey])
            {
                NSLog(@"path url is = %@-3", [pathURL pathExtension]);
                NSString * fileName = nil;
                [pathURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
                // 头文件
                if ([fileName isEqualToString:@"Headers"])
                {
                    [dirEnumerator skipDescendants];
                    [headersArray addObject:[pathURL path]];
                }
                // 无用的nib
                if ([[fileName pathExtension] isEqualToString:@"nib"])
                {
                    [dirEnumerator skipDescendants];
                    [nibsArray addObject:[pathURL path]];
                }
            }
            if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:nil])
                return;
        }
        
        NSMutableArray * resultArray = [NSMutableArray array];
        NSArray * privateHeader = [self scanAppHeaderInfo:headersArray];
        if (privateHeader)
            [resultArray addObjectsFromArray:privateHeader];
        
        NSArray * unlessNIB = [self scanAppResourceNIB:nibsArray];
        if (unlessNIB)
            [resultArray addObjectsFromArray:unlessNIB];
        
        // 结果转换成对象
        QMResultItem * resultItem = nil;
        if ([resultArray count] > 0)
        {
            resultItem = [m_developerResult objectForKey:appPath];
            if (resultItem)
            {
                [resultItem addResultWithPathArray:resultArray];
            }
            else
            {
                resultItem = [[QMResultItem alloc] initWithPath:appPath];
                [m_developerResult setObject:resultItem forKey:appPath];
                resultItem.cleanType = actionItem.cleanType;
            }
            [resultItem addResultWithPathArray:resultArray];
        }
        
        // 进度信息
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            return;
        
    }
}


@end
