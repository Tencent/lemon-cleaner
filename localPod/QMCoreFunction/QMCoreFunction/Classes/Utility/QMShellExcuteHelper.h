//
//  QMShellExcuteHelper.h
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMShellExcuteHelper : NSObject
// 默认允许10后超时
// 仅macOS 14 以上包含超时
+ (nullable NSString *)excuteCmd:(NSString *)cmd;
// 设置超时时长。<= 0表示禁用超时；反之> 0表示允许超时。
// 仅macOS 14 以上包含超时，以下设置无效
+ (nullable NSString *)excuteCmd:(NSString *)cmd timeout:(NSTimeInterval)timeout;

/// 直接 exec 二进制，参数以数组传入，不经 /bin/bash -c，避免路径注入。
+ (nullable NSString *)executeLaunchPath:(NSString *)launchPath
                              arguments:(NSArray<NSString *> *)arguments;
+ (nullable NSString *)executeLaunchPath:(NSString *)launchPath
                              arguments:(NSArray<NSString *> *)arguments
                                timeout:(NSTimeInterval)timeout;

+ (nullable NSString *) executeScript:(NSString *)scriptPath arguments:(nullable NSArray<NSString *> *)scriptArguments;

@end

NS_ASSUME_NONNULL_END
