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
#import "SocketCommunicationKeyWord.h"
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
    int ret = unloadPlistByLable(DAEMON_LAUNCHD_LABLE);
    if (ret == 0) {
        NSLog(@"%s, unload %@, successfully", __FUNCTION__, DAEMON_LAUNCHD_PATH);
    } else {
        NSLog(@"%s, unload %@, failed: %@", __FUNCTION__, DAEMON_LAUNCHD_PATH, getErrorStr(ret));
    }
    exit(0);
}

// 通知客户端启动情况。
void notiflyClient(int ret){
    if (ret == 0) {
        NSLog(@"%@", KEY_WORD_START_SUCCESSED);
    } else {
        NSLog(@"%@", KEY_WORD_START_FAILED);
    }
}

int startDaemon(void) {
    NSLog(@"%s", __FUNCTION__);
    int ret = loadPlist(DAEMON_LAUNCHD_PATH);
    if (ret == 0) {
        NSLog(@"%s, load %@, successfully", __FUNCTION__, DAEMON_LAUNCHD_PATH);
    } else {
        NSLog(@"%s, load %@, failed: %@", __FUNCTION__, DAEMON_LAUNCHD_PATH, getErrorStr(ret));
    }
    
    
    // Daemon从socket唤醒后，NSLOG的任何输出都会重定向到socket文件上。
    // 客户端通过读取socket文件，通过匹配字符串尾部的KEY_WORD_START_SUCCESSED和KEY_WORD_START_FAILED去判断启动情况
    // notifly后不要NSlog输出任何东西，因为两次NSLOG输出可能沾在一起，客互端现简单处理没有处理沾包情况。
    notiflyClient(ret);
    return ret;
}


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
    
    NSString *rootLaunchctlCmd = @"launchctl list | grep Lemon"; // root
    NSString *rootLaunchctlStatus = executeCmdAndGetResult(rootLaunchctlCmd);
    NSLog(@"root launchctl status :\n %@",rootLaunchctlStatus);
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



