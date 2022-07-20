//
//  QMWechatScan.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMWechatScan.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "QMResultItem.h"

@implementation QMWechatScan

-(NSArray *)getPathItemPathArr:(QMActionItem *)actionItem shellString:(NSString *)shellString keyword:(NSString *)keyWord{
    NSMutableArray *resultArray = [NSMutableArray new];
    NSMutableArray *pathArray = [NSMutableArray new];
    NSArray *pathItemArr = actionItem.pathItemArray;
    for (QMActionPathItem *pathItem in pathItemArr) {
        NSString *path = [pathItem value];
        path = [path stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
        [pathArray addObject:path];
    }
    
    for (NSString *path in pathArray) {
        NSString *cmd = [NSString stringWithFormat:shellString, path];
        NSString *retPath = [QMShellExcuteHelper excuteCmd:cmd];
        if ([retPath isKindOfClass:[NSNull class]]) {
            continue;
        }
        if ((retPath == nil) || ([retPath isEqualToString:@""])) {
            continue;
        }
        NSArray *retArray = [retPath componentsSeparatedByString:@"\n"];
        for (NSString *resultPath in retArray) {
            if ([resultPath containsString:keyWord]) {
                [resultArray addObject:resultPath];
            }
        }
    }
    
    return resultArray;
}

-(void)callbackResultArray:(NSArray *)resultArray cleanType:(QMCleanType) cleanType{
    for (int i = 0; i < [resultArray count]; i++)
    {
        NSString *result = [resultArray objectAtIndex:i];
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
        resultItem.cleanType = cleanType;
        
        // 添加结果
        if (resultItem) [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            resultItem = nil;
        }
        if ([self.delegate scanProgressInfo:(i + 1.0) / [resultArray count] scanPath:result resultItem:resultItem])
        break;
    }
}

//扫描头像图片
-(void)scanWechatAvatar:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemKind = \"*PNG*\" || kMDItemKind = \"*JPEG*\" || kMDItemKind = \"*image*\"'" keyword:@"Avatar"];
    if ([pathArray count] == 0) {
        return;
    }
    [self callbackResultArray:pathArray cleanType:actionItem.cleanType];
}

//扫描聊天图片
-(void)scanWechatImage:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Image\"'" keyword:@"Image"];
    if ([pathArray count] == 0) {
        return;
    }
    //过滤90天前的图片
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        @autoreleasepool {
            if (![path containsString:@"/Message/MessageTemp"]) {
                continue;
            }
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
            NSString *tempPath = nil;
            while ((tempPath = [dirEnum nextObject]) != nil) {
                NSString *picPath = [path stringByAppendingPathComponent:tempPath];
                NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:picPath error:nil];
                NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
                NSTimeInterval modifyTime = [[attr objectForKey:NSFileModificationDate] timeIntervalSince1970];
                NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval extraIntervalModify = nowInterval - modifyTime;
                NSTimeInterval extraIntervalCreate = nowInterval - createTime;
                if ((extraIntervalCreate < 90 * 24 * 60 * 60) || (extraIntervalModify < 90 * 24 * 60 * 60)) {
                    [resultArr addObject:picPath];
                }
            }
        }
        
    }
    
    [self callbackResultArray:resultArr cleanType:actionItem.cleanType];
}

//扫描聊天图片 90天前
-(void)scanWechatImage90DayAgo:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Image\"'" keyword:@"Image"];
    if ([pathArray count] == 0) {
        return;
    }
    //过滤90天内的图片
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        @autoreleasepool {
            if (![path containsString:@"/Message/MessageTemp"]) {
                continue;
            }
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
            NSString *tempPath = nil;
            while ((tempPath = [dirEnum nextObject]) != nil) {
                NSString *picPath = [path stringByAppendingPathComponent:tempPath];
                NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:picPath error:nil];
                NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
                NSTimeInterval modifyTime = [[attr objectForKey:NSFileModificationDate] timeIntervalSince1970];
                NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval extraIntervalModify = nowInterval - modifyTime;
                NSTimeInterval extraIntervalCreate = nowInterval - createTime;
                if ((extraIntervalCreate >= 90 * 24 * 60 * 60) && (extraIntervalModify >= 90 * 24 * 60 * 60)) {
                    [resultArr addObject:picPath];
                }
            }
            
        }
    }
    
    [self callbackResultArray:resultArr cleanType:actionItem.cleanType];
}

//扫描接收的文件
-(void)scanWechatFile:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"File\"'" keyword:@"File"];
    if ([pathArray count] == 0) {
        return;
    }
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    for (NSString *path in pathArray) {
        @autoreleasepool {
            if (![path containsString:@"/Message/MessageTemp"]) {
                continue;
            }
            [retArr addObject:path];
        }
    }
    [self callbackResultArray:retArr cleanType:actionItem.cleanType];
}

//扫描接收到的视频
-(void)scanWechatVideo:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Video\"'" keyword:@"Video"];
    if ([pathArray count] == 0) {
        return;
    }
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    for (NSString *path in pathArray) {
        if (![path containsString:@"/Message/MessageTemp"]) {
            continue;
        }
        [retArr addObject:path];
    }
    [self callbackResultArray:retArr cleanType:actionItem.cleanType];
}

//扫描接收到的音频
-(void)scanWechatAudio:(QMActionItem *)actionItem{
    NSArray *pathArray = [self getPathItemPathArr:actionItem shellString:@"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Audio\"'" keyword:@"Audio"];
    if ([pathArray count] == 0) {
        return;
    }
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    for (NSString *path in pathArray) {
        if (![path containsString:@"/Message/MessageTemp"]) {
            continue;
        }
        [retArr addObject:path];
    }
    [self callbackResultArray:retArr cleanType:actionItem.cleanType];
}

@end
