//
//  LemonMonitorDNCClient.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LemonMonitorDNCClient.h"
#import "LemonDNCDefine.h"

@implementation LemonMonitorDNCClient

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static LemonMonitorDNCClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)helpStart {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSTimeInterval delay = 0.1;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:appPath, @"appPath", @(delay), @"delay", nil];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:LemonDNCHelpStartNotificationName object:nil userInfo:userInfo deliverImmediately:YES];
}

@end
