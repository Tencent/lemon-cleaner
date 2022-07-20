//
//  LMWeChatScan.m
//  LemonFileMove
//
//  
//

#import "LMWeChatScan.h"
#import "NSString+Extension.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "LMFileHelper.h"

#define WeChatScanPath    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/"

@implementation LMWeChatScan

+ (instancetype)shareInstance {
    static LMWeChatScan *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[[self class] alloc] init];
    });
    return shareInstance;
}

- (void)starScanWechat {
    [self scanWechat:LMFileMoveScanType_Image before:YES];
    [self scanWechat:LMFileMoveScanType_Image before:NO];
    [self scanWechat:LMFileMoveScanType_File before:YES];
    [self scanWechat:LMFileMoveScanType_File before:NO];
    [self scanWechat:LMFileMoveScanType_Video before:YES];
    [self scanWechat:LMFileMoveScanType_Video before:NO];
}

- (void)scanWechat:(LMFileMoveScanType)type before:(BOOL)before {
    NSString *keyWord;
    NSString *shellString;
    if (type == LMFileMoveScanType_Image) {
        keyWord = @"Image";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Image\"'";
    } else if (type == LMFileMoveScanType_File) {
        keyWord = @"File";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"File\"'";
    } else if (type == LMFileMoveScanType_Video) {
        keyWord = @"Video";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemDisplayName=\"Video\"'";
    }

    NSArray *pathArray = [self getPath:WeChatScanPath shellString:shellString keyword:keyWord];
    if ([pathArray count] == 0) {
        return;
    }
    //过滤90天/90天后
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        @autoreleasepool {
            if (![path containsString:@"/Message/MessageTemp"]) {
                continue;
            }
            BOOL isDirectory = NO;
            if ([LMFileHelper isEmptyDirectory:path filterHiddenItem:YES isDirectory:&isDirectory] || !isDirectory) {
                continue;
            }
            
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
            NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
            NSTimeInterval extraIntervalCreate = nowInterval - createTime;
            if(before == YES) {
                if ((extraIntervalCreate > 90 * 24 * 60 * 60)) {
                    [resultArr addObject:path];
                }
            } else {
                if ((extraIntervalCreate <= 90 * 24 * 60 * 60)) {
                    [resultArr addObject:path];
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
        resultItem.path = result;
        resultItem.appType = LMAppCategoryItemType_WeChat;
        resultItem.fileType = type;

        if (before) {
            resultItem.selecteState = NSControlStateValueOn;
        } else {
            resultItem.selecteState = NSControlStateValueOff;
        }
        NSArray *titleArr = [result componentsSeparatedByString:@"/"];
        if (titleArr && titleArr.count > 0) {
            resultItem.title = titleArr.lastObject;
        }
        // 添加结果
        if (resultItem.fileSize == 0) {
            resultItem = nil;
        } else {
            if ([self.delegate respondsToSelector:@selector(weChatScanWithType:resultItem:)]) {
                [self.delegate weChatScanWithType:type resultItem:resultItem];
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
