//
//  LMWeChatScan.m
//  LemonFileMove
//
//  
//

#import "LMWeChatScan.h"
#import "NSString+Extension.h"

#define WeChatScanPath    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/"
#define WeChat4ScanPath @"~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files"

@implementation LMWeChatScan

- (void)startScanWeChat {
    [self start];
    [self scanWeChat:LMFileMoveScanType_Image before:YES];
    [self scanWeChat:LMFileMoveScanType_Image before:NO];
    [self scanWeChat:LMFileMoveScanType_File before:YES];
    [self scanWeChat:LMFileMoveScanType_File before:NO];
    [self scanWeChat:LMFileMoveScanType_Video before:YES];
    [self scanWeChat:LMFileMoveScanType_Video before:NO];
    
    // wechat4
    [self scanWeChat4:LMFileMoveScanType_Image before:YES];
    [self scanWeChat4:LMFileMoveScanType_Image before:NO];
    [self scanWeChat4:LMFileMoveScanType_File before:YES];
    [self scanWeChat4:LMFileMoveScanType_File before:NO];
    [self scanWeChat4:LMFileMoveScanType_Video before:YES];
    [self scanWeChat4:LMFileMoveScanType_Video before:NO];
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
    } else {
        return;
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
        if ([strongSelf.delegate respondsToSelector:@selector(weChatScanWithType:resultItem:)] && !strongSelf.cancel) {
            [strongSelf.delegate weChatScanWithType:type resultItem:resultItem];
        }
    }];
}

- (void)scanWeChat4:(LMFileMoveScanType)type before:(BOOL)before {
    NSString *keyWord;
    NSString *shellString;
    NSString *pathContainString = nil;
    if (type == LMFileMoveScanType_Image) {
        keyWord = @"attach";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"attach\"'";
        pathContainString = @"/msg/attach";
    } else if (type == LMFileMoveScanType_File) {
        keyWord = @"file";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"file\"'";
        pathContainString = @"/msg/file";
    } else if (type == LMFileMoveScanType_Video) {
        keyWord = @"video";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"video\"'";
        pathContainString = @"/msg/video";
    } else {
        // 处理未知类型，直接返回避免后续使用未初始化变量
        return;
    }

    NSArray *pathArray = [self getPath:WeChat4ScanPath shellString:shellString keyword:keyWord];
    if ([pathArray count] == 0) {
        return;
    }
    
    // 遍历下一层级
    NSInteger targetDepth = 1;
    if (type == LMFileMoveScanType_Image) {
        targetDepth = 2;
    }
    pathArray = [self findSubdirectoriesFromPaths:pathArray maxDepth:targetDepth filterBlock:^BOOL(NSString * _Nonnull path, NSInteger depth) {
        return depth == targetDepth;
    }];
    
    //过滤90天/90天后
    NSArray *resultArr = [self filterPathArray:pathArray parentDir:nil continueExec:^BOOL(NSString * _Nonnull path) {
        return [path containsString:pathContainString];
    } before:before];

    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr appType:LMAppCategoryItemType_WeChat type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(weChatScanWithType:resultItem:)] && !strongSelf.cancel) {
            [strongSelf.delegate weChatScanWithType:type resultItem:resultItem];
        }
    }];
}

@end
