//
//  QMFilterParseManager.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMFilterParse.h"
#import "QMFilterItem.h"
#import "QMActionItem.h"
#import "QMCleanUtils.h"
#import <QMCoreFunction/McCoreFunction.h>

@implementation QMFilterParse

- (id)initFilterDict:(NSDictionary *)filterDict
{
    if (self = [super init])
    {
        m_filerDict = filterDict;
        // 结果过滤
        m_filterItemArray = [[NSMutableArray alloc] init];
        // 清空Filter关系
        [self resetFilterItem];
    }
    return self;
}

#pragma mark-
#pragma mark 过滤结果

/*
 解析过滤器
 */
- (void)parseFilters:(NSString *)filters filter:(NSMutableArray *)filterArray logicLevel:(int)level
{
    if (!filters || [m_filerDict count] == 0)
        return;
    
    NSRange rangeEnd = [filters rangeOfString:@")"];
    NSString * searchFilter = nil;
    if (rangeEnd.location != filters.length - 1)
    {
        searchFilter = [filters substringToIndex:rangeEnd.location + 1];
        NSRange rangeStart = [searchFilter rangeOfString:@"(" options:NSBackwardsSearch];
        searchFilter = [filters substringWithRange:NSMakeRange(rangeStart.location + 1, rangeEnd.location - rangeStart.location - 1)];
    }
    else
    {
        searchFilter = [filters substringWithRange:NSMakeRange(1, filters.length - 2)];
    }
    
    level++;
    
    BOOL andLogic = NO;
    if ([searchFilter rangeOfString:@"+"].length != 0)
        andLogic = YES;
    
    NSArray * filterSpliteArray = [searchFilter componentsSeparatedByString:(andLogic ? @"+" : @"|")];
    QMFilterItem * filterItem = nil;
    QMFilterItem * lastItem = nil;
    for (NSString * str in filterSpliteArray)
    {
        QMFilterItem * tempItem = [m_filerDict objectForKey:str];
        if (lastItem == nil)
        {
            if (filterItem != nil)
                debug_NSLog(@"last Item is Nil : %@", str);
            filterItem = tempItem;
        }
        else
        {
            if (andLogic)
                lastItem.andFilterItem = tempItem;
            else
                lastItem.orFilterItem = tempItem;
        }
        if (tempItem.logicLevel == 0)
            tempItem.logicLevel = level;
        lastItem = tempItem;
    }
    if (filterItem)
        [filterArray addObject:filterItem];
    
    if (rangeEnd.location != filters.length - 1)
    {
        NSString * newFilters = [filters stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"(%@)", searchFilter]
                                                                   withString:[filterSpliteArray lastObject]];
        [self parseFilters:newFilters filter:filterArray logicLevel:level];
    }
}

// 根据规则过滤路径
- (BOOL)filterPathWithFilters:(NSString *)path filter:(NSArray *)filterArray
{
    if ([filterArray count] == 0)
        return YES;
    if ([filterArray count] == 1)
    {
        QMFilterItem * filterItem = [filterArray lastObject];
        if (!filterItem.orFilterItem && !filterItem.andFilterItem)
            return [filterItem checkFilterWithPath:path];
    }
    
    BOOL result = YES;
    int curLogicLevel = 1;
    NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
    for (QMFilterItem * filterItem in filterArray)
    {
        QMFilterItem * tempItem = filterItem;
        BOOL resetResult = YES;
        while ([tempItem andFilterItem] || [tempItem orFilterItem])
        {
            BOOL andLogic = NO;
            QMFilterItem * relationItem = nil;
            BOOL curResult = NO;
            if ([tempItem andFilterItem])
            {
                andLogic = YES;
                relationItem = [tempItem andFilterItem];
            }
            else if ([tempItem orFilterItem])
            {
                andLogic = NO;
                relationItem = [tempItem orFilterItem];
            }
            
            if (relationItem.logicLevel != tempItem.logicLevel)
            {
                if (curLogicLevel != tempItem.logicLevel)
                {
                    NSString * levelKey = [NSString stringWithFormat:@"%d", tempItem.logicLevel];
                    if (![[tempDict allKeys] containsObject:levelKey])
                        break;
                    if (resetResult)
                    {
                        result = [[tempDict objectForKey:levelKey] boolValue];
                        resetResult = NO;
                    }
                    levelKey = [NSString stringWithFormat:@"%d", relationItem.logicLevel];
                    curResult = [[tempDict objectForKey:levelKey] boolValue];
                }
                else
                {
                    curResult = [tempItem checkFilterWithPath:path];
                }
            }
            else
            {
                if (resetResult)
                {
                    result = [tempItem checkFilterWithPath:path];
                    resetResult = NO;
                }
                curResult = [relationItem checkFilterWithPath:path];
            }
            
            result = andLogic ? result & curResult : result || curResult;
            tempItem = relationItem;
        }
        curLogicLevel++;
        [tempDict setObject:[NSNumber numberWithBool:result]
                     forKey:[NSString stringWithFormat:@"%d", filterItem.logicLevel]];
        
    }
    return result;
}


- (BOOL)filterPathWithFilters:(NSString *)path
{
    return [self filterPathWithFilters:path filter:m_filterItemArray];
}

// 简单过滤文件
- (BOOL)baseFilterWithPath:(NSString *)path withItem:(QMActionPathItem *)pathItem
{
    NSString * fileName = pathItem.filename;
    // 清理空目录
    BOOL cleanemptyfolder = m_actionItem.cleanemptyfolder;
    BOOL cleanhiddenfile = m_actionItem.cleanhiddenfile;
    
    // 过滤自身程序
    if ([QMCleanUtils checkQQMacMgrFile:path])
        return NO;
    
    // 过滤隐藏文件
    if (!cleanhiddenfile && [QMCleanUtils isHiddenItemForPath:path])
        return NO;
    
    // 过滤文件名
    if (fileName && ![QMCleanUtils assertRegex:fileName matchStr:[path lastPathComponent]])
        return NO;
    
    // 过滤清理空文件
    if (!cleanemptyfolder && [QMCleanUtils isEmptyDirectory:path filterHiddenItem:cleanhiddenfile])
        return NO;
    return YES;
}

#pragma mark-
#pragma mark 枚举路径，并进行扫描过滤

- (NSArray *)loopListFilePath:(int)level path:(NSString *)path scanPacakge:(BOOL)scanPacakge
{
    if (level < 1)
        return [NSArray arrayWithObject:path];
    NSMutableArray * retArray = [NSMutableArray array];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSArray * subPaths = [fm contentsOfDirectoryAtPath:path error:nil];
    BOOL isDir = NO;
    for (int i = 0 ; i < [subPaths count]; i++)
    {
        NSString * subPath = [path stringByAppendingPathComponent:[subPaths objectAtIndex:i]];
        if (scanPacakge && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:subPath])
            continue;
        if ([fm fileExistsAtPath:subPath isDirectory:&isDir] && isDir)
        {
            NSArray * result = [self loopListFilePath:(level - 1) path:subPath scanPacakge:scanPacakge];
            if (result)
                [retArray addObjectsFromArray:result];
        }
        else
        {
            [retArray addObject:subPath];
        }
    }
    return retArray;
}

- (id)pathArrayWithRegex:(NSString *)path
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSRange  range1 = [path rangeOfString:@"("];
    NSRange  range2 = [path rangeOfString:@")"];
    if (range1.length != 0 && range2.length != 0)
    {
        NSMutableArray * retArray = [NSMutableArray array];
        NSString * str = [path substringWithRange:NSMakeRange(range1.location + range1.length, range2.location - range1.location - range2.length)];
        NSString * path1 = [path substringToIndex:range1.location];
        NSString * path2 = [path substringFromIndex:range2.location + 1];
        NSArray * contentArray = [fm contentsOfDirectoryAtPath:path1 error:nil];
        for (NSString * temp in contentArray)
        {
            if (![QMCleanUtils assertRegex:str matchStr:temp] && ![temp isEqualToString:str])
                continue;
            NSString * tempPath = [path1 stringByAppendingPathComponent:temp];
            tempPath = [tempPath stringByAppendingPathComponent:path2];
            if ([fm fileExistsAtPath:tempPath])
            {
                id subPathObj = [self pathArrayWithRegex:tempPath];
                if ([subPathObj isKindOfClass:[NSArray class]])
                    [retArray addObjectsFromArray:subPathObj];
                else
                    [retArray addObject:subPathObj];
            }
        }
        return retArray;
    }
    else
    {
        return path;
    }
}

- (id)pathWithActionPathItem:(QMActionPathItem *)pathItem
{
    if (![[pathItem type] isEqualToString:kXMLKeyAbs]
        && ![[pathItem type] isEqualToString:kXMLKeySpecial])
        return nil;
    NSString * path = nil;
    NSString * pathValue = pathItem.value;
    NSString * pathType = pathItem.type;
    if ([pathType isEqualToString:kXMLKeySpecial])
    {
        if ([pathValue isEqualToString:kXMLKeyTemp])
        {
            path = NSTemporaryDirectory();
            path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"C"];
        }
        else if ([pathValue isEqualToString:kXMLKeyFireFoxProfiles])
        {
            NSString * profilesPath = [@"~/Library/Application Support/FireFox/" stringByExpandingTildeInPath];
            NSString * contentStr = [NSString stringWithContentsOfFile:[profilesPath stringByAppendingPathComponent:@"profiles.ini"]
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
            NSArray * contentArray = [contentStr componentsSeparatedByString:@"\n"];
            NSMutableArray * pathArray = [NSMutableArray array];
            for (NSString * str in contentArray)
            {
                NSRange range = [str rangeOfString:@"Path=" options:NSCaseInsensitiveSearch];
                if (range.length != 0)
                {
                    NSString * value = [str substringFromIndex:range.location + range.length];
                    NSString * defaultPath = [profilesPath stringByAppendingPathComponent:value];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:defaultPath])
                    {
                        [pathArray addObject:defaultPath];
                    }
                }
            }
            if ([pathArray count] == 1) return [pathArray lastObject];
            return pathArray;
        }
    }
    else
    {
        if ([McCoreFunction isAppStoreVersion]) {
            pathValue = [pathValue stringByReplacingOccurrencesOfString:@"~/" withString:@""];
            path = [NSString stringWithFormat:@"%@/%@", [NSString getUserHomePath], pathValue];
            return [self pathArrayWithRegex:path];
        }else{
            path = [pathValue stringByStandardizingPath];
            return [self pathArrayWithRegex:path];
        }
    }
    return path;
}

- (NSArray *)_enumeratorAtFilePath:(NSString *)path pathItem:(QMActionPathItem *)pathItem
{
    NSFileManager * fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path])
        return nil;
    int level = pathItem.level;
    //debug_NSLog(@"Start Scan level : %d path : %@", level, path);

    NSMutableArray * retArray = [NSMutableArray array];
    
    // 当前路径
    if (level == 0 || m_actionItem.type == QMActionDirType)
    {
        [retArray addObject:path];
        return retArray;
    }
    // 遍历所有子目录
    BOOL scanApp = [[[pathItem.filename pathExtension] lowercaseString] isEqualToString:@"app"];
    if (scanApp)
    {
        // 缓存目录
        NSArray * array = [QMCleanUtils cacheResultWithPath:path];
        if (array)   return array;
    }
    NSDirectoryEnumerationOptions directoryEnum = 0;
    if (scanApp) directoryEnum = NSDirectoryEnumerationSkipsPackageDescendants;
    // 扫描路径
    BOOL flags = [QMCleanUtils contentPathAtPath:path options:directoryEnum level:level propertiesKey:[NSArray arrayWithObject:NSURLIsAliasFileKey] block:^(NSURL *pathURL) {
        if(level == -1){
            NSFileManager *fileManger = [NSFileManager defaultManager];
            BOOL isDir;
            if([fileManger fileExistsAtPath:[pathURL path] isDirectory:&isDir]){
                if(isDir && !scanApp){
                    return [self->_delegate needStopScan];
                }
            }
        }
        if (scanApp)
        {
            NSNumber * result = nil;
            [pathURL getResourceValue:&result forKey:NSURLIsPackageKey error:NULL];
            if (result && [result boolValue])
            {
                NSString * path = [pathURL path];
                if (path && [[[path pathExtension] lowercaseString] isEqualToString:@"app"])
                    [retArray addObject:path];
            }
        }
        else
        {
            NSString * path = [pathURL path];
            if (path) [retArray addObject:path];
        }
        return [self->_delegate needStopScan];
    }];
    if (scanApp && flags)    [QMCleanUtils setScanCacheResult:[NSDictionary dictionaryWithObject:retArray forKey:path]];
    return retArray;
}

/*
 枚举路径
 */
- (NSArray *)enumeratorAtFilePath:(QMActionItem *)item
{
    m_actionItem = item;
    
    // 创建结果过滤
    [self parseFilters:item.atomItem.resultFilters filter:m_filterItemArray logicLevel:0];
    
    // 获取扫描的路径
    NSMutableArray * scanPathArray = [NSMutableArray array];
    NSArray * pathItemArray = m_actionItem.pathItemArray;
    [scanPathArray addObjectsFromArray:pathItemArray];
    
    NSUInteger scanFileNum = 0;
    NSMutableArray * retPathArray = [NSMutableArray array];
    for (QMActionPathItem * pathItem in scanPathArray)
    {
        // 创建扫描过滤
        NSMutableArray * scanFilterItemArray = [NSMutableArray array];
        [self parseFilters:pathItem.scanFilters filter:scanFilterItemArray logicLevel:0];
        
        NSMutableArray * scanPathArray = [NSMutableArray array];
        id resultPath = [self pathWithActionPathItem:pathItem];
        
        //如果是systempdir 并且bundleid不为空，则直接拼接上
        NSString * pathValue = pathItem.value;
        NSString * pathValue1 = pathItem.value1;
        if([pathValue isEqualToString:kXMLKeyTemp] && (pathValue1 != nil)){
            resultPath = [resultPath stringByAppendingPathComponent:pathValue1];
        }
        
        if ([resultPath isKindOfClass:[NSArray class]])
        {
            for (NSString * path in resultPath)
            {
                NSArray * array = [self _enumeratorAtFilePath:path pathItem:pathItem];
                if (array){
                    for (NSString *path in array) {
                        if (path) {
                            [scanPathArray addObject:path];
                        }
                    }
                    scanFileNum += [array count];
                }else{
                    scanFileNum++;
                }
                
            }
        }
        else
        {
            NSArray * array = [self _enumeratorAtFilePath:resultPath pathItem:pathItem];
            if (array){
                for (NSString *path in array) {
                    if (path) {
                        [scanPathArray addObject:path];
                    }
                }
                scanFileNum += [array count];
            }else{
                scanFileNum++;
            }
        }
        
        for (NSString * scanPath in scanPathArray)
        {
            if ([self baseFilterWithPath:scanPath withItem:pathItem]
                && [self filterPathWithFilters:scanPath filter:scanFilterItemArray])
                if (scanPath != nil) {
                    [retPathArray addObject:scanPath];
                }
        }
        // 重置扫描filteritem
        for (QMFilterItem * filterItem in scanFilterItemArray)
        {
            filterItem.orFilterItem = nil;
            filterItem.andFilterItem = nil;
        }
    }
    [item setScanFileNum:scanFileNum];
    return retPathArray;
}

#pragma mark-
#pragma mark 重置FilterItem关系

- (void)resetFilterItem
{
    for (QMFilterItem *filterItem in m_filerDict.allValues) {
        filterItem.andFilterItem = nil;
        filterItem.orFilterItem = nil;
    }
}

@end
