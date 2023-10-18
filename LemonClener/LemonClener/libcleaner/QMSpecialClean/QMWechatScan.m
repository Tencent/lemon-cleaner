//
//  QMWechatScan.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMWechatScan.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "QMResultItem.h"
#import <sys/stat.h>

@interface QMWechatScan ()
@property (nonatomic, strong) NSMutableArray *resultArrWechatImage90DayAgo;
@end

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
    self.resultArrWechatImage90DayAgo = [NSMutableArray new];
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
                [self queryFileTimeWithPath:picPath completion:^(NSTimeInterval extraIntervalModify, NSTimeInterval extraIntervalCreate) {
                    if ((extraIntervalCreate < 90 * 24 * 60 * 60) || (extraIntervalModify < 90 * 24 * 60 * 60)) {
                        [resultArr addObject:picPath];
                    } else {
                        if (@available(macOS 14.0, *)) {
                            [self.resultArrWechatImage90DayAgo addObject:picPath];
                        }
                    }
                }];
            }
        }
        
    }
    
    [self callbackResultArray:resultArr cleanType:actionItem.cleanType];
}

//扫描聊天图片 90天前
-(void)scanWechatImage90DayAgo:(QMActionItem *)actionItem{
    
    if (@available(macOS 14.0, *)) {
        if (self.resultArrWechatImage90DayAgo.count > 0) {
            /// 减少重复扫描
            [self callbackResultArray:self.resultArrWechatImage90DayAgo cleanType:actionItem.cleanType];
            /// 清空
            self.resultArrWechatImage90DayAgo = nil;
            return;
        }
    }
    
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
                [self queryFileTimeWithPath:picPath completion:^(NSTimeInterval extraIntervalModify, NSTimeInterval extraIntervalCreate) {
                    if ((extraIntervalCreate >= 90 * 24 * 60 * 60) && (extraIntervalModify >= 90 * 24 * 60 * 60)) {
                        [resultArr addObject:picPath];
                    }
                }];
            }
        }
    }
    
    [self callbackResultArray:resultArr cleanType:actionItem.cleanType];
}

- (void)queryFileTimeWithPath:(NSString *)path completion:(void(^)(NSTimeInterval extraIntervalModify, NSTimeInterval extraIntervalCreate))completion {
    NSTimeInterval extraIntervalModify = 0;
    NSTimeInterval extraIntervalCreate = 0;
    if (@available(macOS 14.0, *)) {
        /// 在macos 14.0 上通过NSFileManager获取文件元数据耗时较高。因为NSFileManager会包装文件中的所有元信息。
        /// 在iOS 、tvOS、watchos新版本上增加了一个key值，不知道是否由于这个变更影响的。
        /// struct stat 则可以按需获取，文件较多时，耗时更少
        struct stat statbuf;
        const char *cpath = [path fileSystemRepresentation];
        if (cpath && stat(cpath, &statbuf) == 0) {
            NSTimeInterval createTime = [[NSDate dateWithTimeIntervalSince1970:statbuf.st_ctime] timeIntervalSince1970];
            NSTimeInterval modifyTime = [[NSDate dateWithTimeIntervalSince1970:statbuf.st_mtime] timeIntervalSince1970];
            NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
            extraIntervalModify = nowInterval - modifyTime;
            extraIntervalCreate = nowInterval - createTime;
        }
    } else {
        NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
        NSTimeInterval modifyTime = [[attr objectForKey:NSFileModificationDate] timeIntervalSince1970];
        NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
        extraIntervalModify = nowInterval - modifyTime;
        extraIntervalCreate = nowInterval - createTime;
    }
    
    if (completion) {
        completion(extraIntervalModify, extraIntervalCreate);
    }
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
