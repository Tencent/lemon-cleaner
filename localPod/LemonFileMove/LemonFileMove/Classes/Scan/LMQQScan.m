//
//  LMQQScan.m
//  LemonFileMove
//
//  
//

#import "LMQQScan.h"
#import "NSString+Extension.h"


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
        if (![path containsString:@"/Caches/Images"] && ![path containsString:@"/Caches/Videos"] && ![path containsString:@"/Caches/Files"]) {
            continue;
        }
        
        NSArray *subArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        NSArray *subResultArr = [self filterPathArray:subArr parentDir:path continueExec:^BOOL(NSString * path) {
            return YES;
        } before:before];
        [resultArr addObjectsFromArray:subResultArr];
    }

    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr.copy appType:LMAppCategoryItemType_QQ type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(QQScanWithType:resultItem:)]) {
            [strongSelf.delegate QQScanWithType:type resultItem:resultItem];
        }
    }];
}

@end
