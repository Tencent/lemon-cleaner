//
//  LemonDNCClient.m
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LemonDNCClient.h"

@implementation LemonDNCClient

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static LemonDNCClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)restart:(LemonDNCRestartType)type reason:(LemonDNCRestartReason)reason {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:LemonDNCRestartNotificationName object:nil userInfo:@{LemonDNCRestartUserInfoTypeKey:@(type), LemonDNCRestartUserInfoReasonKey: @(reason)} deliverImmediately:YES];
}

@end
