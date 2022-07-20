//
//  ExecuteCmdHelper.c
//  LemonDaemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#include "ExecuteCmdHelper.h"



NSString* executeCmdAndGetResult(NSString *cmd)
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
        NSLog(@"%s, Task succeeded.", __FUNCTION__);
    } else {
        [task terminate];
        NSLog(@"%s, Task failed.", __FUNCTION__);
    }
    [file closeFile];
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}



