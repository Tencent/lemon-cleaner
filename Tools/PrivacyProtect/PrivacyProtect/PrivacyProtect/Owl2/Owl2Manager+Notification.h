//
//  Owl2Manager+Notification.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <PrivacyProtect/PrivacyProtect.h>
#import "Owl2Manager.h"
#import "QMUserNotificationCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2Manager (Notification) <NSUserNotificationCenterDelegate>

- (void)registeNotificationDelegate;
- (void)analyseDeviceInfoForNotificationWithArray:(NSArray<NSDictionary *>*)itemArray;

@end

NS_ASSUME_NONNULL_END
