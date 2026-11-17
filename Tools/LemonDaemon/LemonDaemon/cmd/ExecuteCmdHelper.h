//
//  ExecuteCmdHelper.h
//  LemonDaemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdio.h>

/// 仅允许传入常量命令。禁止把任何用户/客户端可控字符串拼进 cmd。
NSString* executeCmdAndGetResult(NSString *cmd);
NSString* executeLaunchPathAndGetResult(NSString *launchPath, NSArray<NSString *> *arguments);
int executeLaunchPath(NSString *launchPath, NSArray<NSString *> *arguments);

/// 以参数数组启动可执行文件，不经过 /bin/bash。用户输入必须作为独立参数传入。
NSString* executeExecutableWithArguments(NSString *launchPath, NSArray<NSString *> *arguments);

/// 同上，返回进程退出码；启动失败返回 -1。
int executeExecutableWithArgumentsGetStatus(NSString *launchPath, NSArray<NSString *> *arguments);
