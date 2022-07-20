//
//  QMUserNotificationCenter.m
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QMUserNotificationCenter.h"

#define kNotificationKey @"_notification_key"
#define kNotificationCategoryKey @"_category_key"

@implementation QMUserNotificationCenter

- (id)init
{
    if (self = [super init])
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        if (@available(macOS 10.14, *)) {
            [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
        }
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

- (void)scheduleNotification:(NSUserNotification *)notification key:(NSString *)key
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

- (void)deliverNotification:(NSUserNotification *)notification key:(NSString *)key
{
    if (@available(macOS 10.14, *)) {
        if (![_delegateDict objectForKey:key])
            return;
        NSMutableDictionary * dict = [notification.userInfo mutableCopy];
        if (!dict)
            dict = [[NSMutableDictionary alloc] init];
        [dict setObject:key forKey:kNotificationKey];
        
        // notification content
        UNMutableNotificationContent* content = nil;
        
        //notificaiton request
        UNNotificationRequest* request = nil;

        //alloc content
        content = [[UNMutableNotificationContent alloc] init];

        //set title
        content.title = notification.title;

        //set body
        content.body = notification.informativeText;

        //set category
        content.categoryIdentifier = kNotificationCategoryKey;
        
        //set user info
        content.userInfo = dict;

        //init request
        request = [UNNotificationRequest requestWithIdentifier:notification.identifier content:content trigger:NULL];

        //send notification
        NSSet *categories = [NSSet setWithArray:@[[self categoryWithUserNotification:notification]]];
        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error)
        {
            if (!error) {
                NSString * key = [dict objectForKey:kNotificationKey];
                if (key) {
                    id obj = [self->_delegateDict objectForKey:key];
                    if ([obj respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)])
                        [obj userNotificationCenter:[NSUserNotificationCenter defaultUserNotificationCenter]
                             didDeliverNotification:notification];
                }
            }
        }];
        
    } else {
        // Fallback on earlier versions
        [self scheduleNotification:notification key:key];
    }
    
    return;
}

- (void)removeAllDeliveredNotifications {
    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
    } else {
        // Fallback on earlier versions
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    }
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
    if (@available(macOS 10.14, *)) {
        UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
        __weak typeof(center) weakCenter = center;
        [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
            
            NSMutableArray<NSString *> *identifiers = [NSMutableArray<NSString *> array];
            for (UNNotification * notification in notifications)
            {
                NSDictionary *userInfo = notification.request.content.userInfo;
                if (!userInfo)
                    continue;
                NSString * userKey = [userInfo objectForKey:kNotificationKey];
                if (!userKey)
                    continue;
                if ([userKey isEqualToString:key])
                {
                    if (!sender || sender(userInfo))
                        [identifiers addObject:notification.request.identifier];
                }
            }
            [weakCenter removeDeliveredNotificationsWithIdentifiers:identifiers];
        }];
    } else {
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


#pragma mark - Actions

- (UNNotificationCategory *)categoryWithUserNotification:(NSUserNotification *)notification API_AVAILABLE(macos(10.14)) {
    
    /**options
     UNNotificationActionOptionAuthenticationRequired  用于文本
     UNNotificationActionOptionForeground  前台模式，进入APP
     UNNotificationActionOptionDestructive  销毁模式，不进入APP
     */
 
    // 打开应用按钮
    UNNotificationAction *action = nil;
    if (notification.hasActionButton) {
        action = [UNNotificationAction actionWithIdentifier:UNNotificationActionDidBlock
                                                      title:notification.actionButtonTitle
                                                    options:UNNotificationActionOptionForeground];
    } else {
        action = [UNNotificationAction actionWithIdentifier:UNNotificationActionDidBlock
                                                      title:notification.otherButtonTitle
                                                    options:UNNotificationActionOptionForeground];
    }
        
    
    // 创建分类
    /**
     Identifier:分类的标识符，通知可以添加不同类型的分类交互按钮
     actions：交互按钮
     intentIdentifiers：分类内部标识符  没什么用 一般为空就行
     options:通知的参数   UNNotificationCategoryOptionCustomDismissAction:自定义交互按钮   UNNotificationCategoryOptionAllowInCarPlay:车载交互
     */
    UNNotificationCategory *category =
        [UNNotificationCategory categoryWithIdentifier:kNotificationCategoryKey
                                               actions:@[action]
                                     intentIdentifiers:@[]
                                               options:UNNotificationCategoryOptionCustomDismissAction];
 
    return category;
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(macos(10.14)) {
    
    NSString *key = [response.notification.request.content.userInfo objectForKey:kNotificationKey];
    if (key) {
        id obj = [_delegateDict objectForKey:key];
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = response.notification.request.content.title;
        notification.identifier = response.notification.request.identifier;
        
        NSMutableDictionary *dict = [response.notification.request.content.userInfo mutableCopy];
        if (dict && response.actionIdentifier) {
            [dict setObject:response.actionIdentifier forKey:@"ACTION_ID"];
        }
        notification.userInfo = dict;
        
        if ([obj respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)])
            [obj userNotificationCenter:[NSUserNotificationCenter defaultUserNotificationCenter]
                didActivateNotification:notification];
    }
    
}



@end
