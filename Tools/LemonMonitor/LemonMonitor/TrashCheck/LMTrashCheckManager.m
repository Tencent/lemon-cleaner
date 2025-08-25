//
//  LMTrashCheckManager.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMTrashCheckManager.h"

static NSTimeInterval kDelay = 1.0;

@implementation LMTrashCheckManager
+ (instancetype)manager {
    static LMTrashCheckManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LMTrashCheckManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 设置延时1秒后执行
        // 实际距离最后一次触发，由于控频原因可能只间隔0.5s执行
        self.task = [[QMTaskScheduler alloc] initWithDelay:kDelay task:^{
            
        }];
        // 控频，防止高频调用
        self.task.ignoreScheduleInterval = kDelay/2;
    }
    return self;
}

@end
