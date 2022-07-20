//
//  LMQQScan.m
//  LemonFileMove
//
//  
//

#import "LMQQScan.h"
#import "NSString+Extension.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>


#define QQScanPath    @"~/Library/Containers/com.tencent.qq/Data/Library/Caches"

@implementation LMQQScan

+ (instancetype)shareInstance {
    static LMQQScan *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[[self class] alloc] init];
    });
    return shareInstance;
}

- (void)starScanQQ {
    [self scanQQ:LMFileMoveScanType_Image before:YES];
    [self scanQQ:LMFileMoveScanType_Image before:NO];
    [self scanQQ:LMFileMoveScanType_File before:YES];
    [self scanQQ:LMFileMoveScanType_File before:NO];
    [self scanQQ:LMFileMoveScanType_Video before:YES];
    [self scanQQ:LMFileMoveScanType_Video before:NO];
}

- (void)scanQQ:(LMFileMoveScanType)type before:(BOOL)before {
    NSArray *pathArray;
    NSString *originPath = [QQScanPath stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
    if (type == LMFileMoveScanType_Image) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Images"]];
    } else if (type == LMFileMoveScanType_File) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Files"]];
    } else if (type == LMFileMoveScanType_Video) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Videos"]];
    }
    
    //过滤90天/90天后
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        @autoreleasepool {
            if (![path containsString:@"/Caches/Images"] && ![path containsString:@"/Caches/Videos"] && ![path containsString:@"/Caches/Files"]) {
                continue;
            }
            
            NSArray *subArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            for(int num = 0; num < subArr.count; num++) {
                NSString *picPath = [path stringByAppendingPathComponent:subArr[num]];
                NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:picPath error:nil];
                NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
                NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval extraIntervalCreate = nowInterval - createTime;
                if(before == YES) {
                    if ((extraIntervalCreate > 90 * 24 * 60 * 60)) {
                        [resultArr addObject:picPath];
                    }
                } else {
                    if ((extraIntervalCreate <= 90 * 24 * 60 * 60)) {
                        [resultArr addObject:picPath];
                    }
                }
            }
            
        }
    }

    [self callbackResultArray:resultArr type:type before:before];
}

- (void)callbackResultArray:(NSArray *)resultArray type:(LMFileMoveScanType)type  before:(BOOL)before{
    for (int i = 0; i <[resultArray count]; i ++) {
        NSString *result = [resultArray objectAtIndex:i];
        LMResultItem * resultItem = [[LMResultItem alloc] init];
        resultItem.originPath = result;
        resultItem.appType = LMAppCategoryItemType_QQ;
        resultItem.fileType = type;
        
        NSArray *titleArr = [result componentsSeparatedByString:@"/"];
        if (titleArr && titleArr.count > 0) {
            resultItem.title = titleArr.lastObject;
        }
        if (before) {
            resultItem.selecteState = NSControlStateValueOn;
        } else {
            resultItem.selecteState = NSControlStateValueOff;
        }
        // 添加结果
        if (resultItem.fileSize == 0) {
            resultItem = nil;
        } else {
            if ([self.delegate respondsToSelector:@selector(QQScanWithType:resultItem:)]) {
                [self.delegate QQScanWithType:type resultItem:resultItem];
            }
        }
    }
}

// 获取相关目录
- (NSArray *)getPath:(NSString *)path shellString:(NSString *)shellString keyword:(NSString *)keyWord{
    NSMutableArray *resultArray = [NSMutableArray new];
    path = [path stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
    
    NSString *cmd = [NSString stringWithFormat:shellString, path];
    NSString *retPath = [QMShellExcuteHelper excuteCmd:cmd];
    if ([retPath isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ((retPath == nil) || ([retPath isEqualToString:@""])) {
        return nil;
    }
    NSArray *retArray = [retPath componentsSeparatedByString:@"\n"];
    for (NSString *resultPath in retArray) {
        if ([resultPath containsString:keyWord]) {
            [resultArray addObject:resultPath];
        }
    }
    return resultArray;
}


@end
