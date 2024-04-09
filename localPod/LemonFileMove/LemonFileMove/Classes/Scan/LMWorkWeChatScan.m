//
//  LMWorkWeChatScan.m
//  LemonFileMove
//
//  
//

#import "LMWorkWeChatScan.h"
#import "NSString+Extension.h"

#define WorkWeChatScanPath    @"~/Library/Containers/com.tencent.WeWorkMac/Data/Documents/Profiles"

@implementation LMWorkWeChatScan

- (void)startScanWorkWeChat {
    [self start];
    [self scanWorkWeChat:LMFileMoveScanType_Image before:YES];
    [self scanWorkWeChat:LMFileMoveScanType_Image before:NO];
    [self scanWorkWeChat:LMFileMoveScanType_File before:YES];
    [self scanWorkWeChat:LMFileMoveScanType_File before:NO];
    [self scanWorkWeChat:LMFileMoveScanType_Video before:YES];
    [self scanWorkWeChat:LMFileMoveScanType_Video before:NO];
}

- (void)scanWorkWeChat:(LMFileMoveScanType)type before:(BOOL)before {
    NSString *keyWord;
    NSString *shellString;
    if (type == LMFileMoveScanType_Image) {
        keyWord = @"Image";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"Images\"'";
    } else if (type == LMFileMoveScanType_File) {
        keyWord = @"File";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"Files\"'";
    } else if (type == LMFileMoveScanType_Video) {
        keyWord = @"Video";
        shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName=\"Videos\"'";
    }

    NSArray *pathArray = [self getPath:WorkWeChatScanPath shellString:shellString keyword:keyWord];
    if ([pathArray count] == 0) {
        return;
    }
    //过滤90天/90天后
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        if (![path containsString:@"/Caches/Files"] && ![path containsString:@"/Caches/Images"] && ![path containsString:@"/Caches/Videos"]) {
            continue;
        }
        
        NSArray *subArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        NSArray *subResultArr = [self filterPathArray:subArr parentDir:path continueExec:^BOOL(NSString * path) {
            return YES;
        } before:before];
        [resultArr addObjectsFromArray:subResultArr];
    }

    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr.copy appType:LMAppCategoryItemType_WeCom type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(workWeChatScanWithType:resultItem:)] && !self.cancel) {
            [strongSelf.delegate workWeChatScanWithType:type resultItem:resultItem];
        }
    }];
}

@end
