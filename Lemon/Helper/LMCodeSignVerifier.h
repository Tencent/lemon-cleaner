//
//  LMCodeSignVerifier.h
//  Lemon
//
//  Created on 2026/7/22.
//  Copyright © 2026 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 代码签名校验工具类
/// 用于在提权执行前验证 app bundle 的代码签名完整性和 Team ID
@interface LMCodeSignVerifier : NSObject

/// 校验指定路径的 app bundle 代码签名完整性及 Team ID
/// @param appPath app bundle 的完整路径（如 /Applications/Tencent Lemon.app）
/// @param teamID 期望的 Team ID（如 @"88L2Q4487U"）
/// @return YES = 签名有效且 Team ID 匹配；NO = 签名无效或 Team ID 不匹配
+ (BOOL)verifyAppBundleAtPath:(NSString *)appPath expectedTeamID:(NSString *)teamID;

@end

NS_ASSUME_NONNULL_END
