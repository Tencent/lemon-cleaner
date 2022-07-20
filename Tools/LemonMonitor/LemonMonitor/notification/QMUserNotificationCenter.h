//
//  QMUserNotificationCenter.h
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UNNotificationActionDidBlock @"UNNotificationActionDidBlock" // 弹窗中选择【拒绝】按钮操作

#import <UserNotifications/UserNotifications.h>

@interface QMUserNotificationCenter : NSObject<NSUserNotificationCenterDelegate, UNUserNotificationCenterDelegate>
{
    NSMutableDictionary * _delegateDict;
}
+ (instancetype)defaultUserNotificationCenter;

- (void)scheduleNotification:(NSUserNotification *)notification key:(NSString *)key;

- (void)addDelegate:(id<NSUserNotificationCenterDelegate>)delegate forKey:(NSString *)key;
//- (void)removeDelegate:(NSString *)key;

- (void)removeAllScheduledNotification;
- (void)removeScheduledNotificationWithKey:(NSString *)key flagsBlock:(BOOL (^)(NSDictionary * userInfo))sender;

// Note: UNUserNotification
- (void)deliverNotification:(NSUserNotification *)notification key:(NSString *)key;
- (void)removeAllDeliveredNotifications;
@end
