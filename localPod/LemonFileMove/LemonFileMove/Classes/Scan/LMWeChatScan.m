//
//  LMWeChatScan.m
//  LemonFileMove
//
//  
//

#import "LMWeChatScan.h"
#import "NSString+Extension.h"

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
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"Image\"'";
    } else if (type == LMFileMoveScanType_File) {
        keyWord = @"File";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"File\"'";
    } else if (type == LMFileMoveScanType_Video) {
        keyWord = @"Video";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"Video\"'";
    }

    NSArray *pathArray = [self getPath:WeChatScanPath shellString:shellString keyword:keyWord];
    if ([pathArray count] == 0) {
        return;
    }
    //过滤90天/90天后
    NSArray *resultArr = [self filterPathArray:pathArray parentDir:nil continueExec:^BOOL(NSString * _Nonnull path) {
        return [path containsString:@"/Message/MessageTemp"];
    } before:before];

    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr appType:LMAppCategoryItemType_WeChat type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(weChatScanWithType:resultItem:)]) {
            [strongSelf.delegate weChatScanWithType:type resultItem:resultItem];
        }
    }];
}

@end
