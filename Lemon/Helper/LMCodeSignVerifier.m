//
//  LMCodeSignVerifier.m
//  Lemon
//
//  Created on 2026/7/22.
//  Copyright © 2026 Tencent. All rights reserved.
//

#import "LMCodeSignVerifier.h"
#import <Security/Security.h>

@implementation LMCodeSignVerifier

+ (BOOL)verifyAppBundleAtPath:(NSString *)appPath expectedTeamID:(NSString *)teamID
{
#ifdef DEBUG
    // 开发环境下跳过签名校验（本地编译无有效签名）
    NSLog(@"[LMCodeSignVerifier] DEBUG mode, skip signature verification for: %@", appPath);
    return YES;
#else
    if (!appPath || appPath.length == 0 || !teamID || teamID.length == 0) {
        NSLog(@"[LMCodeSignVerifier] Invalid parameters: appPath=%@, teamID=%@", appPath, teamID);
        return NO;
    }

    NSURL *bundleURL = [NSURL fileURLWithPath:appPath];
    if (!bundleURL) {
        NSLog(@"[LMCodeSignVerifier] Failed to create URL for path: %@", appPath);
        return NO;
    }

    // Step 1: 创建 SecStaticCode 引用
    SecStaticCodeRef staticCode = NULL;
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)bundleURL,
                                                  kSecCSDefaultFlags,
                                                  &staticCode);
    if (status != errSecSuccess || !staticCode) {
        NSLog(@"[LMCodeSignVerifier] SecStaticCodeCreateWithPath failed: %d, path: %@", (int)status, appPath);
        return NO;
    }

    // Step 2: 严格校验签名（递归校验嵌套代码 + 所有架构）
    SecCSFlags validationFlags = kSecCSStrictValidate | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures;
    status = SecStaticCodeCheckValidity(staticCode, validationFlags, NULL);
    if (status != errSecSuccess) {
        NSLog(@"[LMCodeSignVerifier] SecStaticCodeCheckValidity failed: %d, path: %@", (int)status, appPath);
        CFRelease(staticCode);
        return NO;
    }

    // Step 3: 提取签名信息
    CFDictionaryRef signingInfo = NULL;
    status = SecCodeCopySigningInformation(staticCode, kSecCSSigningInformation, &signingInfo);
    if (status != errSecSuccess || !signingInfo) {
        NSLog(@"[LMCodeSignVerifier] SecCodeCopySigningInformation failed: %d, path: %@", (int)status, appPath);
        CFRelease(staticCode);
        return NO;
    }

    // Step 4: 提取 Team ID 并比对
    NSString *actualTeamID = ((__bridge NSDictionary *)signingInfo)[(NSString *)kSecCodeInfoTeamIdentifier];
    BOOL matched = [teamID isEqualToString:actualTeamID];

    if (!matched) {
        NSLog(@"[LMCodeSignVerifier] Team ID mismatch: expected=%@, actual=%@, path: %@", teamID, actualTeamID, appPath);
    } else {
        NSLog(@"[LMCodeSignVerifier] Signature verification PASSED for: %@", appPath);
    }

    CFRelease(signingInfo);
    CFRelease(staticCode);

    return matched;
#endif
}

@end
