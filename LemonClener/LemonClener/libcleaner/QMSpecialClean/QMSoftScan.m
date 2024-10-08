//
//  QMSoftScan.m
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "QMSoftScan.h"
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import "QMCacheEnumerator.h"
#import "QMCleanUtils.h"

@implementation QMSoftScan
@synthesize delegate;

-(void)scanSketchFileCache:(QMActionItem *)actionItem{
    [self __scanSketchFileCache:actionItem];
    [self scanActionCompleted];
}

-(void)__scanSketchFileCache:(QMActionItem *)actionItem{
    NSArray *pathItemArray = actionItem.pathItemArray;
    for (int i = 0; i < [pathItemArray count]; i++)
    {
        QMActionPathItem *pathItem = [pathItemArray objectAtIndex:i];
        NSString *result = [pathItem value];
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
        if (resultItem) [resultItem addResultWithPathByDeamonCalculateSize:result];
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathItemArray count] scanPath:result resultItem:resultItem])
            break;
    }
}

//扫描自适配软件缓存
-(void)scanAdaptSoftCache:(QMActionItem *)actionItem{
    [self __scanAdaptSoftCache:actionItem];
    [self scanActionCompleted];
}

-(void)__scanAdaptSoftCache:(QMActionItem *)actionItem{
    NSArray *pathArray = [[QMCacheEnumerator shareInstance] getCacheWithActionItem:actionItem];
    if ([pathArray count] == 0) {
        return;
    }
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString *result = [pathArray objectAtIndex:i];
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
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            break;
    }
}

//扫描剩余的缓存的大小
-(void)scanLeftAppCache:(QMActionItem *)actionItem{
    [self __scanLeftAppCache:actionItem];
    [self scanActionCompleted];
}

-(void)__scanLeftAppCache:(QMActionItem *)actionItem{
    NSArray *pathArray = [[QMCacheEnumerator shareInstance] getLeftAppCache];
    if ([pathArray count] == 0) {
        return;
    }
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString *result = [pathArray objectAtIndex:i];
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
        if([resultItem.title containsString:@"IntelliJIdea"] || [resultItem.title containsString:@"音乐"]){
            continue;
        }
        if([resultItem.path containsString:@"com.apple.amp.itmstransporter"]){
            continue;
        }
        resultItem.cleanType = actionItem.cleanType;
        // 添加结果
        if (resultItem) [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            break;
    }
}

//扫描剩余的日志大小
-(void)scanLeftAppLog:(QMActionItem *)actionItem{
    [self __scanLeftAppLog:actionItem];
    [self scanActionCompleted];
}

-(void)__scanLeftAppLog:(QMActionItem *)actionItem{
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];//通过扫描规则和过滤规则，返回所有路径
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        
        if (![filterParse filterPathWithFilters:result])
            continue;
        
        // 文件置空类型，判断子目录
        NSMutableArray * resultPathArray = [NSMutableArray array];
        if (actionItem.cleanType == QMCleanTruncate)
        {
            NSArray * subPaths = [QMCleanUtils processDirTruncatePath:result];
            if (subPaths)
            {
                for (NSString * subPath in subPaths)
                {
                    [resultPathArray addObject:subPath];
                }
            }
            else
            {
                [resultPathArray addObject:result];
            }
        }
        else
        {
            [resultPathArray addObject:result];
        }
        
        if ([resultPathArray count] == 0)
            continue;
        
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
        if (resultItem) [resultItem addResultWithPathArray:resultPathArray];
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            break;
    }
}


@end






