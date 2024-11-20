//
//  LMCleanerDataCenter+LMCleanPatch.m
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "LMCleanerDataCenter+LMCleanPatch.h"

static NSString * const kResetDownloadSelectStatusKey  = @"lmClean_resetDownloadSelectStatus_key";
static NSString * const kItemIdDownloadKey             = @"1007"; // 下载

static NSString * const kResetSketchCacheSelectStatusKey  = @"lmClean_resetSketchCacheSelectStatus_key";

static NSString * const kItemIdSketchActionId          = @"21021";
static NSString * const kItemIdSketchAppStoreBundleId  = @"com.bohemiancoding.sketch3.appstore1"; // 1 代表自适配软件的缓存, 2代表日志

static NSString * const kBuildWhenUpdateDownload = @"1015";
static NSString * const kBuildWhenUpdateSketch = @"1023";



@implementation LMCleanerDataCenter (LMCleanPatch)

- (void)lmClean_resetDownloadSelectStatus {
    NSString * bundleVersion = [self __lmClean_bundleVersion];
    if ([bundleVersion compare:kBuildWhenUpdateDownload] != NSOrderedAscending) {
        BOOL flag = [[NSUserDefaults standardUserDefaults]  boolForKey:kResetDownloadSelectStatusKey];
        if (flag) {
            return;
        }
        // 重置下载的勾选状态
        // 1015 一路升级过来的会有flag，不会进入重置
        // 1015 之后安装或者跨版本升级（1014 -> 1016）过来的则无flag,重置。（有可能将用户保存的选择重置）
        [self changeSubcate:kItemIdDownloadKey selectStatus:CleanSubcateSelectStatusNoSet];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kResetDownloadSelectStatusKey];
    }
}

- (void)lmClean_resetSketchCacheSelectStatus {
    NSString * bundleVersion = [self __lmClean_bundleVersion];
    // 新包大于等于1023
    if ([bundleVersion compare:kBuildWhenUpdateSketch] != NSOrderedAscending) {
        BOOL flag = [[NSUserDefaults standardUserDefaults]  boolForKey:kResetSketchCacheSelectStatusKey];
        if (flag) {
            return;
        }
        
        // 重置。
        // 新包进入重置无影响
        // 覆盖安装flag保留，无法进入
        [self changeSubcate:kItemIdSketchActionId selectStatus:CleanSubcateSelectStatusNoSet];
        [self changeSubcate:kItemIdSketchAppStoreBundleId selectStatus:CleanSubcateSelectStatusNoSet];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kResetSketchCacheSelectStatusKey];
    }
}

- (NSString *)__lmClean_bundleVersion {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    return bundleVersion;
}

@end
