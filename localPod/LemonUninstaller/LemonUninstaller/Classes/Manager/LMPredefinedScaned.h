//
//  LMPredefinedScaned.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMPredefinedScaned : NSObject
- (void)setScanApp:(NSString *)appName;
- (NSArray *)scanSupports;
- (NSArray *)scanCaches;
- (NSArray *)scanPreferences;
- (NSArray *)scanStates;
- (NSArray *)scanCrashReporters;
- (NSArray *)scanLogs;
- (NSArray *)scanSandboxs;
- (NSArray *)scanLaunchDaemons;
- (NSArray *)scanOthers;
- (void)test;

// 新增

- (NSArray *)scanSignal;     // 退出,使用 kill 命令
- (NSArray *)scanLoginItem;
- (NSArray *)scanKext;


//:early_script,
//:launchctl,
//:quit,
//:signal,
//:login_item,
//:kext,
//:script,
//:pkgutil,
//:delete,
//:trash,
//:rmdir

@end

NS_ASSUME_NONNULL_END
