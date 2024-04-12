//
//  QMLeftAppScan.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMAppLeftScan.h"
#import "QMFilterParse.h"
#import "QMActionItem.h"
#import "QMResultItem.h"
#import "QMCleanUtils.h"
#import "QMCoreFunction/McLocalSoftManager.h"
#import "QMCoreFunction/McLocalSoft.h"

#define kApplicationsPath       @"/Applications"

@implementation QMAppLeftScan
@synthesize delegate;

- (id)init
{
    if (self = [super init])
    {
        addSoftLock = [[NSLock alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(localSoftDidChanged:)
                                                     name:McLocalSoftManagerChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)localSoftDidChanged:(NSNotification *)notify
{
    NSDictionary *userInfo = [notify userInfo];
    NSInteger type = [[userInfo objectForKey:McLocalSoftManagerFlagKey] integerValue];
    if (type != kMcLocalFlagAll)
        return;
    
    BOOL finished = [[userInfo objectForKey:McLocalSoftManagerFinishKey] boolValue];
    if (!finished)
        return;
    
    [addSoftLock lock];
    NSArray *softArray = [[McLocalSoftManager sharedManager] softsWithFlag:kMcLocalFlagAll];
    m_localSoftArray = softArray;
    [addSoftLock unlock];
}

- (void)checkFileName:(NSString *)fileName
              unExist:(BOOL *)isUnExistApps
{
    if ([fileName hasPrefix:@"."])
        return;
    // get bound id
    NSString * bundleID = [fileName stringByDeletingPathExtension];
    if ([bundleID rangeOfString:@"."].length == 0)
        return;
    while (![[bundleID pathExtension] isEqualToString:@""])
    {
        // check app path by bundle id
        // this function rely on launch service database !!!
        // so may return nil
        NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
        
        if (appPath != nil)
        {
            return;
        }
        
        bundleID = [bundleID stringByDeletingPathExtension];
    }
    *isUnExistApps = YES;
}

- (void)scanAppLeftWithItem:(QMActionItem *)actionItem
{
    // 获取路径
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];
    
    NSArray * localCopySoftArray = nil;
    for (int i = 0; i < 20; i++)
    {
        [addSoftLock lock];
        if (m_localSoftArray && [m_localSoftArray count] > 0)
        {
            localCopySoftArray = [m_localSoftArray copy];
            [addSoftLock unlock];
            break;
        }
        [addSoftLock unlock];
        if ([delegate scanProgressInfo:0.1 scanPath:nil resultItem:nil])
            return;
        [NSThread sleepForTimeInterval:0.2];
    }
    // 获取当前/Applications所有app
    NSArray * curAppArray = nil;
    if (!localCopySoftArray || [localCopySoftArray count] == 0)
    {
        curAppArray = [QMCleanUtils cacheResultWithPath:kApplicationsPath];
        if (!curAppArray)
        {
            NSMutableArray * array = [NSMutableArray array];
            
            BOOL flags = [QMCleanUtils contentPathAtPath:kApplicationsPath
                                                 options:NSDirectoryEnumerationSkipsPackageDescendants
                                                   level:0
                                           propertiesKey:[NSArray arrayWithObject:NSURLIsAliasFileKey]
                                                   block:^(NSURL *pathURL) {
                                                       NSNumber * result = nil;
                                                       [pathURL getResourceValue:&result forKey:NSURLIsPackageKey error:NULL];
                                                       if (result && [result boolValue])
                                                       {
                                                           NSString * path = [pathURL path];
                                                           if (path && [[[path pathExtension] lowercaseString] isEqualToString:@"app"])
                                                               [array addObject:path];
                                                       }
                                                       return [self->delegate needStopScan];
                                                   }];
            if (flags) [QMCleanUtils setScanCacheResult:[NSDictionary dictionaryWithObject:array forKey:kApplicationsPath]];
            curAppArray = array;
        }
    }
    
    if ([delegate scanProgressInfo:0.2 scanPath:nil resultItem:nil])
        return;
    
    // 获取搜索路径
    NSMutableArray * searchPathItem = [NSMutableArray array];
    NSArray * pathItemArray = actionItem.pathItemArray;
    for (QMActionPathItem * pathItem in pathItemArray)
    {
        if (![[pathItem type] isEqualToString:kXMLKeyAbs])
            continue;
        [searchPathItem addObject:pathItem];
    }
    
    // 通过bundle id确定是否残留程序
    NSMutableArray * unExistApps = [NSMutableArray array];
    NSMutableSet * existAppsBundle = [NSMutableSet set];
    NSFileManager * fm = [NSFileManager defaultManager];
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * curObj = [pathArray objectAtIndex:i];
        BOOL isUnExist = NO;
        [self checkFileName:[curObj lastPathComponent] unExist:&isUnExist];
        if (isUnExist)
            [unExistApps addObject:curObj];
        else
            [existAppsBundle addObject:[[curObj lastPathComponent] stringByDeletingPathExtension]];
        if ([delegate scanProgressInfo:0.2 + (i + 1.0) / ([pathArray count] * 5) scanPath:curObj resultItem:nil])
            return;
    }
    
    // 添加当前App所有bunlde
    if (curAppArray)
    {
        for (NSString * appPath in curAppArray)
        {
            NSBundle * bundle = [NSBundle bundleWithPath:appPath];
            if (!bundle)
                continue;
            NSString * bundleID = [bundle bundleIdentifier];
            if (!bundleID)
                continue;
            [existAppsBundle addObject:bundleID];
        }
    }
    // 如果有全局的软件
    if (localCopySoftArray)
    {
        for (McLocalSoft * localSoft in localCopySoftArray)
        {
            NSString * bundleID = [localSoft bundleID];
            if (!bundleID)
                continue;
            [existAppsBundle addObject:bundleID];
        }
    }
    
    // loop for check the same company exist app
    NSMutableIndexSet * removeIndex = [NSMutableIndexSet indexSet];
    
    for (NSString * bundleID in existAppsBundle)
    {
        // split string save "com.xxx...." to "com.xx"
        NSMutableString * companyName = [[NSMutableString alloc] init];
        NSArray * array = [bundleID componentsSeparatedByString:@"."];
        if ([array count] >= 2)
        {
            for (int j = 0; j < 2; j++)
            {
                [companyName appendString:[array objectAtIndex:j]];
                
                if (j == 0)
                    [companyName appendString:@"."];
            }
        }
        for (int j = 0; j < [unExistApps count]; j++)
        {
            NSString * str = [unExistApps objectAtIndex:j];
            NSString * unExistPlist = [str lastPathComponent];
            
            // 判断公司名
            if ([companyName length] > 0)
            {
                if ([unExistPlist hasPrefix:companyName])
                {
                    [removeIndex addIndex:j];
                }
            }
            else
            {
                // 判断bundle id
                NSString * unExistBundle = [unExistPlist stringByDeletingPathExtension];
                if ([unExistBundle compare:bundleID options:NSCaseInsensitiveSearch] == NSOrderedSame)
                    [removeIndex addIndex:j];
            }
        }
        [unExistApps removeObjectsAtIndexes:removeIndex];
        [removeIndex removeAllIndexes];
        
        if ([unExistApps count] == 0) break;
    }
    
    
    if ([delegate scanProgressInfo:0.5 scanPath:nil resultItem:nil])
        return;
    
    
    // 查找残留文件
    for (int i = 0; i < [unExistApps count]; i++)
    {
        NSString * preferencePath = [unExistApps objectAtIndex:i];
        NSString * appPlist = [preferencePath lastPathComponent];
        NSString * appBundle = [appPlist stringByDeletingPathExtension];
        NSString * appName = [[appBundle pathExtension] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
//        QMResultItem * resultItem = nil;
//        if ([retDict objectForKey:appBundle])   resultItem = [retDict objectForKey:appBundle];
//        else resultItem = [[QMResultItem alloc] initWithPath:preferencePath];
//        resultItem.cleanType = actionItem.cleanType;
        
        NSMutableArray * leftPathArray = [NSMutableArray array];
        [leftPathArray addObject:preferencePath];
        
        for (QMActionPathItem * pathItem in pathItemArray)
        {
            NSString * path = [pathItem.value stringByStandardizingPath];
            if ([pathItem.type isEqualToString:kXMLKeyAbs])
                continue;
            
            BOOL searchName = NO;
            BOOL searchBundle = NO;
            if ([pathItem.type isEqualToString:kXMLKeySearchName])
                searchName = YES;
            if ([pathItem.type isEqualToString:kXMLKeySearchBundle])
                searchBundle = YES;
            // scan system application support path
            NSArray * subPaths = [fm contentsOfDirectoryAtPath:path error:nil];
            for (NSString * temp in subPaths)
            {
                if (searchName)
                {
                    NSString * lastTemp = [temp stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if ([lastTemp localizedCaseInsensitiveCompare:appName] == NSOrderedSame)
                    {
                        // 过滤结果
                        NSString * tempPath = [path stringByAppendingPathComponent:temp];
                        
                        if (![leftPathArray containsObject:tempPath] && [filterParse filterPathWithFilters:tempPath])
                            [leftPathArray addObject:tempPath];
                    }
                }
                if (searchBundle)
                {
                    if ([temp isEqualToString:appBundle])
                    {
                        // 过滤结果
                        NSString * tempPath = [path stringByAppendingPathComponent:temp];
                        
                        if (![leftPathArray containsObject:tempPath] && [filterParse filterPathWithFilters:tempPath])
                            [leftPathArray addObject:tempPath];
                    }
                }
            }
        }
        
        // fill to dictionary
        for (NSString * path in leftPathArray)
        {
            QMResultItem * resultItem = [[QMResultItem alloc] initWithPath:path];
            resultItem.cleanType = actionItem.cleanType;
            [resultItem addResultWithPath:path];
            if ([delegate scanProgressInfo:0.5 + (i + 1.0) / ([unExistApps count] * 2) scanPath:preferencePath resultItem:resultItem])
                return;
        }
    }
}

@end
