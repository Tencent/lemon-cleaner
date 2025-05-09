//
//  NSUserNotification+QMExtensions.h
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMUserNotificationCenter.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(10.14))
@interface QMUserNotificationAction : NSObject
@property (nonatomic, copy) NSString *actionIdentifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) UNNotificationActionOptions options;
@end

API_AVAILABLE(macos(10.14))
@interface NSUserNotification (QMExtensions)
@property (nonatomic, copy) NSArray<QMUserNotificationAction *> *qm_actions;
@end

NS_ASSUME_NONNULL_END
