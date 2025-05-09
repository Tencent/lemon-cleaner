//
//  NSUserNotification+QMExtensions.m
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "NSUserNotification+QMExtensions.h"
#import <objc/runtime.h>

static char kActionsKey;

API_AVAILABLE(macos(10.14))
@implementation QMUserNotificationAction @end

API_AVAILABLE(macos(10.14))
@implementation NSUserNotification (QMExtensions)
@dynamic qm_actions;

- (NSArray<QMUserNotificationAction *> *)qm_actions {
    return objc_getAssociatedObject(self, &kActionsKey);
}

- (void)setQm_actions:(NSArray<QMUserNotificationAction *> *)qm_actions {
    objc_setAssociatedObject(self, &kActionsKey, qm_actions, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
