//
//  Owl2NotificationItem.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2NotificationItem.h"
#import "QMUserNotificationCenter.h"

extern NSString * const kUNNotificationActionPreventButtonDidBlock;
static NSString *kLogProcessItemKey = @"kLogProcessItemKey";

@implementation Owl2NotificationItem
- (instancetype)initWithLogProcessItem:(Owl2LogProcessItem *)item {
    self = [super init];
    if (self) {
        _processItem = item;
        _uuid = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _processItem = [[Owl2LogProcessItem alloc] initWithProcessDic:dic[kLogProcessItemKey]];
        _notificationKey = dic[QMUserNotificationKey];
        _uuid = dic[OwlUUID];
        _actionId = dic[QMUserNotificationActionIdKey];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *muDic = [[NSMutableDictionary alloc] init];
    if (self.processItem.toDictionary) [muDic setObject:self.processItem.toDictionary forKey:kLogProcessItemKey];
    [self __mappingToDictionary:muDic];
    return muDic.copy;
}

- (NSDictionary *)userInfo {
    NSMutableDictionary *muDic = [[NSMutableDictionary alloc] init];
    if (self.processItem.originalDic) [muDic setObject:self.processItem.originalDic forKey:kLogProcessItemKey];
    [self __mappingToDictionary:muDic];
    return muDic.copy;
}

- (void)__mappingToDictionary:(NSMutableDictionary *)muDic {
    if (self.notificationKey) [muDic setObject:self.notificationKey forKey:QMUserNotificationKey];
    if (self.uuid) [muDic setObject:self.uuid forKey:OwlUUID];
    if (self.actionId) [muDic setObject:self.actionId forKey:QMUserNotificationActionIdKey];
}

- (void)parseUserActionWithNotification:(NSUserNotification *)notification {
    Owl2LogUserAction userAction = Owl2LogUserActionNone;
    // 开始
    if (self.processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStart) {
        if (@available(macOS 10.14, *)) {
            if ([self.actionId isEqualToString:UNNotificationDismissActionIdentifier]) {
                // 点击了左上角的x
                userAction = Owl2LogUserActionClose;
            }
            else if ([self.actionId isEqualToString:UNNotificationDefaultActionIdentifier]) {
                //点击了内容
                userAction = Owl2LogUserActionContent;
            }
            else if ([self.actionId isEqualToString:UNNotificationActionButtonDidBlock]) {
                //本次允许
                userAction = Owl2LogUserActionAllow;
            }
            else if ([self.actionId isEqualToString:UNNotificationActionOtherButtonDidBlock]) {
                // 点击了永久允许,添加到白名单中
                userAction = Owl2LogUserActionAlwaysAllowed;
            }
            else if ([self.actionId isEqualToString:kUNNotificationActionPreventButtonDidBlock]) {
                // 点击了阻止
                userAction = Owl2LogUserActionPrevent;
            }
        } else {
            // 无法监听或者没有X关闭
            if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
                // 点击了内容
                userAction = Owl2LogUserActionContent;
            }
            else if (notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
                // 点击了阻止 （也只有阻止）
                userAction = Owl2LogUserActionPrevent;
            }
        }
    } else if (self.processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStop) {
        userAction = Owl2LogUserActionClose;
    }
    
    _userAction = userAction;
}


@end
