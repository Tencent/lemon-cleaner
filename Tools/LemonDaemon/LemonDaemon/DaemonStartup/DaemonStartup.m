//
//  DaemonStartup.m
//  LemonDaemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "DaemonStartup.h"
#import "LemonDaemonConst.h"
#import "LMPlistHelper.h"
#import "CmcProcess.h"
#include <SystemConfiguration/SystemConfiguration.h>
#import "LMPlistHelper.h"
#import "ExecuteCmdHelper.h"

BOOL isNeedExitDaemon(pid_t clientPid) {
    ProcessInfo_t *proc_info = NULL;
    BOOL ret = YES;
    // 检测除了clientPid之外，还有没有其他客户断在运行。
    int count = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    if (count > 0)
    {
        NSString *exeName;
        for (int i = 0; i < count; i++)
        {
            if (clientPid == proc_info[i].pid) {
                continue;
            }
            exeName = [NSString stringWithUTF8String:proc_info[i].pExeName];
            if ([exeName isEqualToString:[MAIN_APP_NAME stringByDeletingPathExtension]]
                || [exeName isEqualToString:[MONITOR_APP_NAME stringByDeletingPathExtension]])
            {
                ret = NO;
                NSLog(@"%s, exist %@", __FUNCTION__, exeName);
            }
        }
    }
    if (proc_info){
        free(proc_info);
    }
    NSLog(@"%s: %d", __FUNCTION__, ret);
    return ret;
}


void exitDaemon(void) {
    NSLog(@"%s", __FUNCTION__);
    // Security fix: daemon 保持常驻，不再退出
    // 原因：移除 socket 唤醒后，exit(0) 会导致 launchd 移除 job，
    // 下次 XPC 连接无法按需拉起，需要重新弹密码框 load plist。
    // 保持常驻：daemon 内存占用极低，等待 XPC 连接即可。
    // 只有卸载流程（uninstallSub）中才执行 unload + exit。
    NSLog(@"%s: daemon stays resident, skipping exit", __FUNCTION__);
}

// Security fix: notiflyClient() 和 startDaemon() 已移除，socket 唤醒机制不再使用


void printDaemonOrAgentsStatus(void){
    NSLog(@"%s", __FUNCTION__);
    
    NSString *userCmd = @"echo `whoami`";
    NSString *userString = executeCmdAndGetResult(userCmd); // root 权限下和 sudo下执行的结果不同, 包括 $USER的结果(root 下是"",sudo 执行是当前用户名) whoami的结果(root 下是"root",sudo 执行是当前用户名)
    NSLog(@"now user is : %@",userString);
    
    NSArray<NSString *> *userArray = getCurrentLogInUserName();

    // 无法打印用户态下面的 launchctl list.  sudo -u userName 执行的结果还是 root用户态下的结果,而非 userName 用户态下. 可能的解决方法是 "su - username -c 'cmd' &" 这里会切换用户态( '&'且在子 shell 中,切换只在当前命令有效),但失败了, 在 root shell su 貌似没有-c命令
//    if(userArray && [userArray count] > 0){
//        NSString *firstUserName = userArray[0];
//        NSLog(@"login user is : %@",firstUserName);
//        NSString *normalLaunchctlCmd = [NSString stringWithFormat: @"su - %@ -c 'launchctl list' &", firstUserName];
//        NSLog(@"execute cmd is %@", normalLaunchctlCmd);
//        NSString *normalLaunchctlStatus = executeCmdAndGetResult(normalLaunchctlCmd);
//        NSLog(@"normal launchctl status :\n %@",normalLaunchctlStatus);
//    }
    
    NSString *rootLaunchctlStatus = executeExecutableWithArguments(@"/bin/launchctl", @[@"list"]);
    NSMutableString *lemonItems = [NSMutableString string];
    for (NSString *line in [rootLaunchctlStatus componentsSeparatedByString:@"\n"]) {
        if ([line localizedCaseInsensitiveContainsString:@"Lemon"]) {
            [lemonItems appendFormat:@"%@\n", line];
        }
    }
    NSLog(@"root launchctl status :\n %@", lemonItems);
}



int clientExit(pid_t clientPid) {
    NSLog(@"%s, clientPid:%d", __FUNCTION__, clientPid);
    if (isNeedExitDaemon(clientPid)) {
        NSLog(@"%s, dispacth to exit daemon", __FUNCTION__);
        //这里不能直接退出，因会还要return到client端，所以这里延时2秒关闭。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSLog(@"%s, dispatch Block", __FUNCTION__);
            // 再一次确认时否所有client端都已经退出。client可能在2秒时间内又重新启动。
            if (isNeedExitDaemon(0)) {
                NSLog(@"%s, client died exit", __FUNCTION__);
                exitDaemon();
            } else {
                NSLog(@"%s, client still alive don't exit", __FUNCTION__);
            }
        });
    }
    return 0;
}



