//
//  QMUserNotificationCenter.m
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QMUserNotificationCenter.h"

#define kNotificationKey @"_notification_key"

@implementation QMUserNotificationCenter

- (id)init
{
    if (self = [super init])
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
    return self;
}

+ (instancetype)defaultUserNotificationCenter
{
    static QMUserNotificationCenter * notificationCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!notificationCenter)
            notificationCenter = [[QMUserNotificationCenter alloc] init];
    });
    return notificationCenter;
}

- (void)scheduleNotification:(NSUserNotification *)notification key:(NSString *)key;
{
    if (![_delegateDict objectForKey:key])
        return;
    NSMutableDictionary * dict = [notification.userInfo mutableCopy];
    if (!dict)
        dict = [[NSMutableDictionary alloc] init];
    [dict setObject:key forKey:kNotificationKey];
    notification.userInfo = dict;
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

- (void)addDelegate:(id<NSUserNotificationCenterDelegate>)delegate forKey:(NSString *)key
{
    if (!delegate)
        return;
    if ([[_delegateDict allKeys] containsObject:delegate])
        return;
    if (!_delegateDict) _delegateDict = [[NSMutableDictionary alloc] init];
    [_delegateDict setObject:delegate forKey:key];
}
//- (void)removeDelegate:(NSString *)key
//{
//    if (!key)
//        return;
//    [self removeScheduledNotificationWithKey:key flagsBlock:nil];
//    [_delegateDict removeObjectForKey:key];
//}


- (void)removeAllScheduledNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
}
- (void)removeScheduledNotificationWithKey:(NSString *)key flagsBlock:(BOOL (^)(NSDictionary * userInfo))sender
{
    NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSArray * array = [[center deliveredNotifications] copy];
    for (NSUserNotification * notification in array)
    {
        NSDictionary *userInfo = [notification userInfo];
        if (!userInfo)
            continue;
        NSString * userKey = [userInfo objectForKey:kNotificationKey];
        if (!userKey)
            continue;
        if ([userKey isEqualToString:key])
        {
            if (!sender || sender(userInfo))
                [center removeDeliveredNotification:notification];
        }
    }
}


#pragma mark -
#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    //通知已经递交！
    NSDictionary *userInfo = [notification userInfo];
    if (!userInfo)
    {
        return;
    }
    NSString * key = [userInfo objectForKey:kNotificationKey];
    if (key)
    {
        id obj = [_delegateDict objectForKey:key];
        if ([obj respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)])
            [obj userNotificationCenter:center didDeliverNotification:notification];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //用户点击了通知！
    NSDictionary *userInfo = [notification userInfo];
    if (!userInfo)
    {
        return;
    }
    NSString * key = [userInfo objectForKey:kNotificationKey];
    if (key)
    {
        id obj = [_delegateDict objectForKey:key];
        if ([obj respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)])
            [obj userNotificationCenter:center didActivateNotification:notification];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    if (!userInfo)
    {
        return;
    }
    NSString * key = [userInfo objectForKey:kNotificationKey];
    if (key)
    {
        id obj = [_delegateDict objectForKey:key];
        if ([obj respondsToSelector:@selector(userNotificationCenter:didDismissAlert:)])
            [obj userNotificationCenter:center didDismissAlert:notification];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


@end
