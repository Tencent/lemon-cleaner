//
//  Owl2AppItem.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OwlConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2AppItem : NSObject {
@protected
    NSString *_name;
    NSString *_executableName;
    NSString *_iconPath;
    NSString *_identifier;
    NSString *_appPath;
    BOOL _sysApp;
    BOOL _isWatchAudio;
    BOOL _isWatchCamera;
    BOOL _isWatchSpeaker;
}

// 后缀.app 或者 .appex
- (instancetype)initWithAppPath:(NSString *)appPath;
- (instancetype)initWithDic:(NSDictionary *)dic;
- (NSDictionary *)toDictionary;

// App名称
@property (nonatomic, copy, readonly) NSString *name;
// 可执行文件名称
@property (nonatomic, copy, readonly) NSString *executableName;
// 应用图标
@property (nonatomic, copy, readonly, nullable) NSString *iconPath;

@property (nonatomic, copy, readonly) NSString *identifier;
// .app路径(mainBundle路径)
@property (nonatomic, copy, readonly) NSString *appPath;
// 是否为系统App
@property (nonatomic, readonly) BOOL sysApp;

#pragma mark - 白名单
@property (nonatomic, readonly) BOOL isWatchAudio;
@property (nonatomic, readonly) BOOL isWatchCamera;
@property (nonatomic, readonly) BOOL isWatchSpeaker;
@property (nonatomic, readonly) BOOL isWatchScreen;

// 同步更新白名单缓存中的数据
- (void)syncUpdateWL:(NSDictionary *)dic;
// 修改白名单
- (void)setWatchValue:(BOOL)value forHardware:(Owl2LogHardware)hardware;
// 将another白名单的合并到当前
- (void)mergeWithAnother:(Owl2AppItem *)another;

// 开启所有开关
- (void)enableAllWatchSwitch;
@end

NS_ASSUME_NONNULL_END
