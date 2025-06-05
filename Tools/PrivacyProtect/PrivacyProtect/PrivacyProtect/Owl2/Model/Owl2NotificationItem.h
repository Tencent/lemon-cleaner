//
//  Owl2NotificationItem.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Owl2LogProcessItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2NotificationItem : NSObject
// 创建通知使用Owl2LogProcessItem来初始化
- (instancetype)initWithLogProcessItem:(Owl2LogProcessItem *)item;
// 通知的回调中，使用userInfo重新初始化
- (instancetype)initWithDic:(NSDictionary *)dic;

- (NSDictionary *)toDictionary;

- (NSDictionary *)userInfo;

@property (nonatomic, strong, readonly) Owl2LogProcessItem *processItem;

#pragma mark - 创建时
// 通知类型的分类（开发测主动进行的分类）
// -[UNUserNotificationCenterDelegate deliverNotification: key:] 与该key对应
// 通知中心塞进去的
@property (nonatomic, copy, readonly) NSString *notificationKey;
// 通知的唯一标识
@property (nonatomic, copy, readonly) NSString *uuid;

#pragma mark - 展示后
// 点击通知行为的标记
@property (nonatomic, copy, readonly, nullable) NSString *actionId;

@property (nonatomic, readonly) Owl2LogUserAction userAction;
// 解析userAction
- (void)parseUserActionWithNotification:(NSUserNotification *)notification;

@end

NS_ASSUME_NONNULL_END
