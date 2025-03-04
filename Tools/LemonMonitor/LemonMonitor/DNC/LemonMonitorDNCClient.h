//
//  LemonMonitorDNCClient.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LemonMonitorDNCClient : NSObject

+ (instancetype)sharedInstance;

// 让其他进程，目前是lemon主进程帮助重启lemonMonitor
- (void)helpStart;

@end

NS_ASSUME_NONNULL_END
