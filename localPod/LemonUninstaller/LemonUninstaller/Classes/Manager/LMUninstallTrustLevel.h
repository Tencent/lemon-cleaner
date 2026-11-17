//
//  LMUninstallTrustLevel.h
//  LemonUninstaller
//
//  卸载扫描的路径信任分级（安全修复：S5.3-as1）。
//
//  背景：卸载列表按 app 自声明的 bundleID 合并「同一应用的多份拷贝」，
//  而 bundleID 任何人都可在 Info.plist 随意填写。攻击者在用户可写目录
//  （~/Downloads 等）放置伪造 .app，声明真实应用的 bundleID 即可被合并进
//  真实应用的卸载条目，一次常规卸载会借 root daemon 把真实应用永久删除。
//
//  对策：合并键附加路径信任级。仅 /Applications 视为信任位置；
//  其余发现根（~/Applications、~/Downloads、~/Desktop、~/Documents，见
//  LMLocalAppListManager.m scanPaths）均为用户可写，不可信。
//  信任级不同的副本不合并、各自独立成条目，伪造 app 无法进入
//  信任位置应用的删除单元。
//

#ifndef LMUninstallTrustLevel_h
#define LMUninstallTrustLevel_h

#import <Foundation/Foundation.h>

/// 路径是否位于信任位置（仅 /Applications；注意带尾斜杠，防 /ApplicationsX 前缀混淆）
static inline BOOL LMUninstallPathIsTrusted(NSString * _Nullable path) {
    if (path.length == 0) return NO;
    return [path hasPrefix:@"/Applications/"];
}

/// 卸载合并键：bundleID + 路径信任级。
/// 信任级相同 → 键相同 → 正常合并（保持"同应用多副本合并展示"的原有行为）；
/// 信任级不同 → 键不同 → 各自独立成条目（伪造副本无法并入信任应用的删除单元）。
static inline NSString * _Nonnull LMUninstallMergeKey(NSString * _Nonnull bundleID,
                                                      NSString * _Nullable bundlePath) {
    return [NSString stringWithFormat:@"%@:%@",
            LMUninstallPathIsTrusted(bundlePath) ? @"T" : @"U", bundleID];
}

#endif /* LMUninstallTrustLevel_h */
