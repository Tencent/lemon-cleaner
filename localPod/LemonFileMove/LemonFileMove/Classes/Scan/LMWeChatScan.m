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

- (void)startScanWeChat {
    [self start];
    [self scanWeChat:LMFileMoveScanType_Image before:YES];
    [self scanWeChat:LMFileMoveScanType_Image before:NO];
    [self scanWeChat:LMFileMoveScanType_File before:YES];
    [self scanWeChat:LMFileMoveScanType_File before:NO];
    [self scanWeChat:LMFileMoveScanType_Video before:YES];
    [self scanWeChat:LMFileMoveScanType_Video before:NO];
}

- (void)scanWeChat:(LMFileMoveScanType)type before:(BOOL)before {
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
        if ([strongSelf.delegate respondsToSelector:@selector(weChatScanWithType:resultItem:)] && !self.cancel) {
            [strongSelf.delegate weChatScanWithType:type resultItem:resultItem];
        }
    }];
}

@end
