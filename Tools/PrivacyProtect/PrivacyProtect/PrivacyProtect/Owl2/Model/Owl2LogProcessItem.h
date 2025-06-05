//
//  Owl2LogProcessItem.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Owl2AppItem.h"
#import "OwlConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2LogProcessItem : NSObject

- (instancetype)initWithProcessDic:(NSDictionary *)dic;
- (NSDictionary *)toDictionary;

// 原始数据
@property (nonatomic, copy, readonly) NSDictionary *originalDic;

@property (nonatomic, copy, readonly) NSNumber *pid;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, copy, readonly) NSString *executablePath;

@property (nonatomic, copy, readonly) NSNumber *deviceType;

@property (nonatomic, copy, readonly) NSNumber *deviceExtra;

@property (nonatomic, copy, readonly) NSString *deviceName;

@property (nonatomic, copy, readonly, nullable) NSString *identifier;
// > 0 开始；< 0 结束
@property (nonatomic, copy, readonly) NSNumber *delta;


// 根据binaryPath找到对应应用，获取的应用信息
@property (nonatomic, strong, readonly, nullable) Owl2AppItem *appItem;
// 父应用
@property (nonatomic, strong, readonly, nullable) Owl2AppItem *parentAppItem;

@end

@interface Owl2LogProcessItem (QMConvenient)
- (Owl2AppItem *)convenient_mainAppItem;
- (nullable NSString *)convenient_identifier;
- (nullable NSString *)convenient_name;
// .app路径(mainBundle路径)
- (nullable NSString *)convenient_appPath;
// delta 的映射 （监控到开始、监控到结束）
- (Owl2LogThirdAppAction)convenient_thirdAppAction;
// 日志落库专用，用于区分screen中截屏和录屏的文案区别
- (Owl2LogThirdAppAction)convenient_thirdAppActionForLog;
- (Owl2LogHardware)convenient_hardware;
// 是否命中白名单
- (BOOL)convenient_hitWhiteList;
@end

NS_ASSUME_NONNULL_END
