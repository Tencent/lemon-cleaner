//
//  LMDaemonStartupHelper.m
//  Lemon
//
//  Created by klkgogo on 2018/12/14.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMDaemonStartupHelper.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <unistd.h>
#import <stdlib.h>
#import <QMCoreFunction/McCoreFunction.h>
#import "STPrivilegedTask.h"

#define STARTUP_LISTEN_SOCKT          @"/var/run/com.tencent.Lemon.socket"

@interface LMDaemonStartupHelper(){
    
}
@end
@implementation LMDaemonStartupHelper

+ (LMDaemonStartupHelper *)shareInstance{
    static LMDaemonStartupHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (int)execCmd:(NSString *)cmd {
    NSLog(@"%s: %@", __FUNCTION__, cmd);
    pid_t status = system([cmd UTF8String]);
    //system命令执行错误
    if (-1 == status) {
        NSLog(@"%s: %@, system error: %d", __FUNCTION__, cmd, status);
        return -1;
    }
    //cmd执行成功
    if (WIFEXITED(status)) {
        NSLog(@"%s: %@, run successfully and exit with return value:%d", __FUNCTION__, cmd, WEXITSTATUS(status));
        return WEXITSTATUS(status);
    }
    
    NSLog(@"%s: %@, run error", __FUNCTION__, cmd);
    return -1;
}

- (int) relaunchListenPlist{
    NSLog(@"%s", __FUNCTION__);
    // 获取用户权限来启动
    STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:self.agentPath arguments:self.arguments];
    [instTask waitUntilExit];
    int retcode = [instTask terminationStatus];
    return retcode;
}


- (int)activeDaemon{
    NSLog(@"%s", __FUNCTION__);
    int ret = 0;
    // 执行失败返回255（activator 失败返回-1，用WEXITSTATUS获取到的对应是255，激活成功返回1，激活失败返回0
    // return: 255:socket创建失败 （activator 失败返回-1，用WEXITSTATUS获取到的对应是255)
    //         254:connect失败 (同上，对应-2)
    //         253:read失败 (同上，对应-3)
    //         252:"最终 Daemon 拉取失败" (同上，对应-4)
    //          1:拉活成功
    //          0:拉活失败 (activator 收不到Daemon的成功返回结果）
    ret = [LMDaemonStartupHelper execCmd:self.cmdPath];
    if (ret >= 253) {
        NSLog(@"%s activate Daemmon failed:%d ", __FUNCTION__, ret);
        [self relaunchListenPlist];
        int reTryCount = 0;
        while (reTryCount < 10) {
            ret = [LMDaemonStartupHelper execCmd:self.cmdPath];
            NSLog(@"%s try again return:%d ", __FUNCTION__, ret);
            if (ret == 1) {
                break;
            }
            reTryCount++;
            usleep(500 * 1000);
        }
    }
    return ret;
}

- (int) notiflyDaemonClientExit {
    NSLog(@"%s", __FUNCTION__);
    return [[McCoreFunction shareCoreFuction] notiflyClientExit];
}
@end
