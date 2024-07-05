//
//  QMUserNotificationCenter.h
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSUInteger, QMUNCNotificationAction) {
    QMUNCNotificationActionNone,
    QMUNCNotificationActionShown,
    QMUNCNotificationActionContentClicked,
    QMUNCNotificationActionButtonClicked,
    QMUNCNotificationActionDismissed,
};

#define UNNotificationActionDidBlock @"UNNotificationActionDidBlock" // 弹窗中选择【拒绝】按钮操作

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

/// 通知弹窗行为回调
- (void)addNotificationActionCallBack:(void(^)(QMUNCNotificationAction action, NSString *notificationKey))callBack;

@end
