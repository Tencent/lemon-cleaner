//
//  LMTrashAppIdentity.h
//  LemonUninstaller
//
//  废纸篓残留：与 searchFiles: 对齐的身份匹配（name ∪ bundleIDPred ∪ company）。
//  不依赖自报身份做归属；只判断「是否撞上已安装应用」。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMTrashAppIdentity : NSObject
@property (nonatomic, copy, nullable) NSString *bundleID;
@property (nonatomic, copy, nullable) NSString *appName;
@property (nonatomic, copy, nullable) NSString *executableName;
@property (nonatomic, copy, nullable) NSString *showName;

+ (instancetype)identityWithBundleID:(nullable NSString *)bundleID
                             appName:(nullable NSString *)appName
                     executableName:(nullable NSString *)executableName
                           showName:(nullable NSString *)showName;
@end

@interface LMTrashInstalledMatch : NSObject

/// 与 LMLocalApp searchFiles: 相同：去空白、小写。
+ (NSString *)normalizedString:(nullable NSString *)string;

/// 与 LMLocalApp regexEscape 相同。
+ (NSString *)regexEscape:(nullable NSString *)string;

/// 三段 bundleID 取 [1]；com.jetbrains.apps.activator 特例为 jetbrains。
+ (nullable NSString *)companySegmentFromBundleID:(nullable NSString *)bundleID;

/// 常规残留默认 footer `(\\..*){0,}\\b`，含 `(\\w+\\.)?`。不为 LaunchDaemon 的 `\\.plist` 另做一套。
+ (nullable NSPredicate *)bundleIDPredicateForClaimedBundleID:(nullable NSString *)bundleID;

/// claimed 与已安装列表 name ∪ bundleIDPred ∪ company 任一命中则 YES。
+ (BOOL)claimedIdentity:(LMTrashAppIdentity *)claimed
     matchesInstalled:(NSArray<LMTrashAppIdentity *> *)installed;

@end

NS_ASSUME_NONNULL_END
