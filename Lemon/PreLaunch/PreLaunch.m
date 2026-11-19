//
//  PreLaunch.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "PreLaunch.h"
#import "LemonDaemonConst.h"
#import <QMCoreFunction/STPrivilegedTask.h>
#import "LMVersionHelper.h"
#import "LemonStartUpParams.h"
#import "LMCodeSignVerifier.h"

// 签名校验失败的错误码
#define QMINST_ERR_SIGNATURE        10

@implementation PreLaunch

+ (BOOL)needToInstall:(int*)installType
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *versionPath = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSArray *checkPathArray = [NSArray arrayWithObjects:supportPath,
                               [supportPath stringByAppendingPathComponent:DAEMON_APP_NAME],
                               [supportPath stringByAppendingPathComponent:APP_DATA_NAME],
                               versionPath,
                               DAEMON_LAUNCHD_PATH,
                               MONITOR_LAUNCHD_PATH,
                               DAEMON_UNINSTALL_LAUNCHD_PATH,
                               DEFAULT_APP_PATH,
                               nil];
    
    // 关键目录不存在
    for (NSString *checkPath in checkPathArray)
    {
        if (![fileMgr fileExistsAtPath:checkPath])
        {
            NSLog(@"%s need to install because path %@ not exist", __FUNCTION__, checkPath);
            if (![fileMgr fileExistsAtPath:versionPath])
            {
                *installType = LemonAppRunningFirstInstall;
            } else {
                NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
                if (runningApps.count > 0) {
                    *installType = LemonAppRunningReInstallAndMonitorExist;
                } else {
                    *installType = LemonAppRunningReInstallAndMonitorNotExist;
                }
            }
            return YES;
        }
    }
    
    // 是否需要检查2个进程都在运行中？
    
    // 检查版本号
//    NSString *instVersion = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:nil];
//    NSString *curVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *instVersion = [LMVersionHelper fullVersionFromVersionLogFile];
    NSString *curVersion = [LMVersionHelper fullVersionFromBundle:[NSBundle mainBundle]];
    NSLog(@"%s instVersion:%@, curVersion:%@", __FUNCTION__, instVersion, curVersion);
//    if (instVersion == nil || [instVersion compare:curVersion] == NSOrderedAscending)
    if (instVersion == nil || ![instVersion isEqualToString:curVersion]) //只要版本号不一样就进行安装
    {
        // 需要更新版本
        NSLog(@"%s need to install because version not same", __FUNCTION__);
        
        NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
        if (runningApps.count > 0) {
            *installType = LemonAppRunningReInstallAndMonitorExist;
        } else {
            *installType = LemonAppRunningReInstallAndMonitorNotExist;
        }
        return YES;
    }
    
    return NO;
}

+ (NSString *)oldInstalledVersion
{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *versionPath = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *instVersion = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:nil];
    
    // 如果有数据，则添加最后的 ".0"
    if ([instVersion length] > 0)
    {
        instVersion = [instVersion stringByAppendingString:@".0"];
    }
    
    return instVersion;
}

+ (int)copySelfToApplication {
    NSLog(@"%s", __FUNCTION__);
    // Security fix: copySelfToApplication 不再单独提权
    // 改由 startToInstall 一次性完成两步（只弹一次密码框）
    return 0;
}

// 开始安装（一次提权完成 copySelf + install，只弹一次密码框）
+ (int)startToInstall
{
    NSString *curVersion = [LMVersionHelper fullVersionFromBundle:[NSBundle mainBundle]];
    NSLog(@"%s, Version:%@", __FUNCTION__, curVersion);
    
    // === Security: Step 1 提权前校验当前 app bundle 代码签名 ===
    NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
    if (![LMCodeSignVerifier verifyAppBundleAtPath:appBundlePath expectedTeamID:@"88L2Q4487U"]) {
        NSLog(@"%s [Security] App bundle code signature verification FAILED. Abort install. path: %@", __FUNCTION__, appBundlePath);
        return QMINST_ERR_SIGNATURE;
    }
    
    NSString *agentPath = [[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    
    // Step 1: copySelfToApplication（root 权限）
    NSLog(@"%s step1: copySelfToApplication", __FUNCTION__);
    STPrivilegedTask *copyTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:agentPath
                                                                             arguments:@[[NSString stringWithUTF8String:kCopySelfToApplication]]];
    [copyTask waitUntilExit];
    int copyRet = [copyTask terminationStatus];
    NSLog(@"%s step1 result: %d", __FUNCTION__, copyRet);
    if (copyRet == STPrivilegedAuthorizationError) {
        return STPrivilegedAuthorizationError;
    }
    
    // === Security: Step 2 提权前校验目标路径 app bundle 代码签名 ===
    if (![LMCodeSignVerifier verifyAppBundleAtPath:DEFAULT_APP_PATH expectedTeamID:@"88L2Q4487U"]) {
        NSLog(@"%s [Security] Installed app bundle signature verification FAILED. Abort install. path: %@", __FUNCTION__, DEFAULT_APP_PATH);
        return QMINST_ERR_SIGNATURE;
    }
    
    // Step 2: InstallLemon（复用同一授权上下文，不会再弹密码框）
    NSString *installAgentPath = [[[NSBundle bundleWithPath:DEFAULT_APP_PATH] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    NSArray *installArgs = @[[NSString stringWithUTF8String:kInstallCmd_cstr],
                             NSUserName(),
                             curVersion,
                             [NSString stringWithFormat:@"%d", getpid()]];
    
    NSLog(@"%s step2: InstallLemon %@", __FUNCTION__, installArgs);
    STPrivilegedTask *installTask = [[STPrivilegedTask alloc] initWithLaunchPath:installAgentPath
                                                                      arguments:installArgs];
    // 复用 copyTask 的授权（STPrivilegedTask 缓存了 AuthorizationRef）
    OSStatus status = [installTask launch];
    if (status != errAuthorizationSuccess) {
        NSLog(@"%s step2 launch failed: %d", __FUNCTION__, (int)status);
        return -1;
    }
    [installTask waitUntilExit];
    int installRet = [installTask terminationStatus];
    NSLog(@"%s step2 result: %d", __FUNCTION__, installRet);
    return installRet;
}

// 开始卸载
+ (BOOL)startToUnInstall
{
    return YES;
}

@end
