//
//  QMUserNotificationCenter.m
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QMUserNotificationCenter.h"
#import "NSUserNotification+QMExtensions.h"

NSString * const QMUserNotificationKey = @"_notification_key";
NSString * const QMUserNotificationActionIdKey = @"ACTION_ID";
#define kNotificationCategoryKey @"_category_key"

@interface QMUserNotificationCenter ()
@property (nonatomic, copy) void (^actionCallBack)(QMUNCNotificationAction action, NSString *notificationKey);
@end

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
    [dict setObject:key forKey:QMUserNotificationKey];
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
        [dict setObject:key forKey:QMUserNotificationKey];
        
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
        __weak typeof(self) weakSelf = self;
        NSSet *categories = [NSSet setWithArray:@[[self categoryWithUserNotification:notification]]];
        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error)
        {
            if (!error) {
                notification.userInfo = dict;
                [weakSelf presentedWhenAuthorizedWithNotification:notification key:key];
            }
        }];
        
    } else {
        // Fallback on earlier versions
        [self scheduleNotification:notification key:key];
    }
    
    return;
}

- (void)presentedWhenAuthorizedWithNotification:(NSUserNotification *)notification key:(NSString *)key API_AVAILABLE(macos(10.14)) {
    __weak typeof(self) weakSelf = self;
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized
            || settings.authorizationStatus == UNAuthorizationStatusProvisional) {
            if (key) {
                // 通知被展示（添加的通知均为立即展示）
                [strongSelf notificationPresentedWithNotificationKey:key];
                id obj = [strongSelf->_delegateDict objectForKey:key];
                if ([obj respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)])
                    [obj userNotificationCenter:[NSUserNotificationCenter defaultUserNotificationCenter]
                         didDeliverNotification:notification];
            }
        }
    }];
}

- (void)removeAllDeliveredNotifications {
    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
    } else {
        // Fallback on earlier versions
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    }
}

- (void)removeDeliveredNotificationWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:NSString.class]) {
        return;
    }
    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[identifier]];
    } else {
        // Fallback on earlier versions
        NSUserNotification *targetNoti = nil;
        for (NSUserNotification *noti in [NSUserNotificationCenter defaultUserNotificationCenter].deliveredNotifications) {
            if ([noti.identifier isEqualToString:identifier]) {
                targetNoti = noti;
                break;
            }
        }
        if (targetNoti) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:targetNoti];
        }
    }
}

- (void)removeScheduledNotificationWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:NSString.class]) {
        return;
    }
    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[identifier]];
    } else {
        // Fallback on earlier versions
        NSUserNotification *targetNoti = nil;
        for (NSUserNotification *noti in [NSUserNotificationCenter defaultUserNotificationCenter].scheduledNotifications) {
            if ([noti.identifier isEqualToString:identifier]) {
                targetNoti = noti;
                break;
            }
        }
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotification:targetNoti];
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
                NSString * userKey = [userInfo objectForKey:QMUserNotificationKey];
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
            NSString * userKey = [userInfo objectForKey:QMUserNotificationKey];
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
    NSString * key = [userInfo objectForKey:QMUserNotificationKey];
    if (key)
    {
        [self notificationPresentedWithNotificationKey:key];
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
    NSString * key = [userInfo objectForKey:QMUserNotificationKey];
    if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
        [self notificationContentClickedWithNotificationKey:key];
    } else if (notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
        [self notificationButtonClickedWithNotificationKey:key];
    } else if (notification.activationType == NSUserNotificationActivationTypeNone) {
        [self notificationDismissedWithNotificationKey:key];
    }
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
    NSString * key = [userInfo objectForKey:QMUserNotificationKey];
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
 
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    if (notification.hasActionButton && notification.actionButtonTitle.length > 0) {
        UNNotificationAction *action = [UNNotificationAction
                                        actionWithIdentifier:UNNotificationActionButtonDidBlock
                                        title:notification.actionButtonTitle
                                        options:UNNotificationActionOptionForeground];
        [actions addObject:action];
    }
    if (notification.otherButtonTitle.length > 0) {
        UNNotificationAction *action = [UNNotificationAction
                                        actionWithIdentifier:UNNotificationActionOtherButtonDidBlock
                                        title:notification.otherButtonTitle
                                        options:UNNotificationActionOptionForeground];
        [actions addObject:action];
    }
    for (QMUserNotificationAction *__action in notification.qm_actions) {
        UNNotificationAction *action = [UNNotificationAction
                                        actionWithIdentifier:__action.actionIdentifier
                                        title:__action.title
                                        options:__action.options];
        [actions addObject:action];
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
                                               actions:actions.copy
                                     intentIdentifiers:@[]
                                               options:UNNotificationCategoryOptionCustomDismissAction];
 
    return category;
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(macos(10.14)) {
    
    NSString *key = [response.notification.request.content.userInfo objectForKey:QMUserNotificationKey];
        if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
            [self notificationContentClickedWithNotificationKey:key];
        } else if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
            [self notificationDismissedWithNotificationKey:key];
        } else  {
            [self notificationButtonClickedWithNotificationKey:key];
        }
    if (key) {
        id obj = [_delegateDict objectForKey:key];
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = response.notification.request.content.title;
        notification.identifier = response.notification.request.identifier;
        
        NSMutableDictionary *dict = [response.notification.request.content.userInfo mutableCopy];
        if (dict && response.actionIdentifier) {
            [dict setObject:response.actionIdentifier forKey:QMUserNotificationActionIdKey];
        }
        notification.userInfo = dict;
        
        if ([obj respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)])
            [obj userNotificationCenter:[NSUserNotificationCenter defaultUserNotificationCenter]
                didActivateNotification:notification];
    }
    
}

#pragma mark - private

/// 通知被展示
- (void)notificationPresentedWithNotificationKey:(NSString *)key {
    if (self.actionCallBack) {
        self.actionCallBack(QMUNCNotificationActionShown, key?:@"");
    }
}

/// 通知内容被点击
- (void)notificationContentClickedWithNotificationKey:(NSString *)key {
    if (self.actionCallBack) {
        self.actionCallBack(QMUNCNotificationActionContentClicked, key?:@"");
    }
}

/// 通知按钮被点击
- (void)notificationButtonClickedWithNotificationKey:(NSString *)key {
    if (self.actionCallBack) {
        self.actionCallBack(QMUNCNotificationActionButtonClicked, key?:@"");
    }
}

/// 通知被关闭
- (void)notificationDismissedWithNotificationKey:(NSString *)key {
    if (self.actionCallBack) {
        self.actionCallBack(QMUNCNotificationActionDismissed, key?:@"");
    }
}

- (void)addNotificationActionCallBack:(void (^)(QMUNCNotificationAction, NSString *))callBack {
    self.actionCallBack = callBack;
}

@end
