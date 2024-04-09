//
//  LMCleanerDataCenter+LMCleanPatch.m
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "LMCleanerDataCenter+LMCleanPatch.h"

NSString * const kResetDownloadSelectStatusKey  = @"lmClean_resetDownloadSelectStatus_key";
NSString * const kItemIdDownloadKey             = @"1007"; // 下载

@implementation LMCleanerDataCenter (LMCleanPatch)

- (void)lmClean_resetDownloadSelectStatus {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString * shortVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString * bundleVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    if ([shortVersion isEqualToString:@"5.1.8"] && [bundleVersion isEqualTo:@"1015"]) {
        BOOL resetDownloadFlag = [[NSUserDefaults standardUserDefaults]  boolForKey:kResetDownloadSelectStatusKey];
        if (resetDownloadFlag) {
            return;
        }
        
        // 重置下载的勾选状态
        [self changeSubcate:kItemIdDownloadKey selectStatus:CleanSubcateSelectStatusDeselect];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kResetDownloadSelectStatusKey];
    }
}

@end
