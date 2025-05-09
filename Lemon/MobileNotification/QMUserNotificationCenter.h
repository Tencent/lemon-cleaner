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

// UNNotificationAction中Identifier映射NSUserNotification中的actionButtonTitle
#define UNNotificationActionButtonDidBlock @"UNNotificationActionButtonDidBlock"
// UNNotificationAction中Identifier映射NSUserNotification中的otherButtonTitle
#define UNNotificationActionOtherButtonDidBlock @"UNNotificationActionOtherButtonDidBlock"


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
- (void)removeScheduledNotificationWithIdentifier:(NSString *)identifier;

// Note: UNUserNotification
- (void)deliverNotification:(NSUserNotification *)notification key:(NSString *)key;
- (void)removeAllDeliveredNotifications;

// 删除以送达用户的通知
// removeScheduledNotificationWithKey:flagsBlock: 只能删除一种类型的通知
- (void)removeDeliveredNotificationWithIdentifier:(NSString *)identifier;

/// 通知弹窗行为回调
- (void)addNotificationActionCallBack:(void(^)(QMUNCNotificationAction action, NSString *notificationKey))callBack;

@end
