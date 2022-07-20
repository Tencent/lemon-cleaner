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
                               DAEMON_STARTUP_LISTEN_LAUNCHD_PATH,
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
    NSString *agentPath = [[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kCopySelfToApplication], nil];
    // 获取用户权限来启动
    NSLog(@"%s %@, args:%@", __FUNCTION__, agentPath, arguments);
    STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:agentPath arguments:arguments];
    [instTask waitUntilExit];
    int retcode = [instTask terminationStatus];
    return retcode;
}

// 开始安装
+ (int)startToInstall
{
    NSString *agentPath = [[[NSBundle bundleWithPath:DEFAULT_APP_PATH] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
//    NSString *curVersion = [[[NSBundle bundleWithPath:appPath] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *curVersion = [LMVersionHelper fullVersionFromBundle:[NSBundle mainBundle]];
    NSLog(@"%s, Version:%@", __FUNCTION__,  curVersion);
    // 所有参数 - 命令参数 | 用户名 | 版本号 | 主进程ID
    NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kInstallCmd_cstr],
                          NSUserName(),
                          curVersion,
                          [NSString stringWithFormat:@"%d", getpid()],nil];
    
    // 获取用户权限来启动
    NSLog(@"%s %@, args:%@", __FUNCTION__, agentPath, arguments);
    STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:agentPath arguments:arguments];
    [instTask waitUntilExit];
    int retcode = [instTask terminationStatus];
    return retcode;
}

// 开始卸载
+ (BOOL)startToUnInstall
{
    return YES;
}

@end
