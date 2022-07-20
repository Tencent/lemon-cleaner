//
//  QMShellExcuteHelper.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMShellExcuteHelper.h"

@implementation QMShellExcuteHelper

+(NSString *)excuteCmd:(NSString *)cmd
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = @[@"-c", cmd];
    [task setArguments:arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    
    @try {
        [task launch];
    } @catch (NSException *exception) {
        NSLog(@"exception excuteCmd = %@", exception);
        return nil;
    }
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
        //NSLog(@"%s, Task succeeded.", __FUNCTION__);
    } else {
        [task terminate];
        NSLog(@"%s, Task failed.", __FUNCTION__);
    }
    
    [file closeFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


// 注意返回的 String 可能带有"\n", 比如 echo "xxx" 作为返回值为 "xxx\n"
// 注意: "xxx\n".split("\n") 返回的 array 为["xxx"和""], 这里有个空字符串.

// 启动一个脚本执行命令后返回, 实际是新启动了一个进程执行脚本.  这不是函数调用.
// 所以执行结果只能通过标准输入输出返回. (比如脚本中可以通过 echo "xxx" 返回)
+ (nullable NSString *)executeScript:(nonnull NSString *)scriptPath arguments:(nullable NSArray<NSString *> *)scriptArguments {
    // path的获取途径
    //NSString *script = [[NSBundle mainBundle] pathForResource:@"killDeamonAndMonitor.sh" ofType:nil];
    //NSString* newPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] privateFrameworksPath], scriptName];
    
    
    if (!scriptPath || scriptPath.length < 2) {
        return nil;
    }
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir;
    BOOL isExist = [fileManager fileExistsAtPath:scriptPath isDirectory:&isDir];
    if (!isExist || isDir) {
        NSLog(@"%s stop execute because path:%@ isExist:%hhd, isDir: %hhd", __FUNCTION__, scriptPath, isExist, isDir);
        return nil;
    }
    
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    
    NSLog(@"shell script path: %@", scriptPath);
    NSMutableArray *arguments = [NSMutableArray array];
    [arguments addObject:scriptPath];
    //            [NSMutableArray arrayWithObjects:scriptPath, nil];
    if (scriptArguments && scriptArguments.count > 0) {
        [arguments addObjectsFromArray:scriptArguments];
    }
    [task setArguments:[arguments copy]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    @try {
        [task launch];
    } @catch (NSException *exception) {
        NSLog(@"exception executeScript = %@", exception);
    }
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
        //NSLog(@"%s, Task succeeded.", __FUNCTION__);
    } else {
        [task terminate];
        NSLog(@"%s, Task failed.", __FUNCTION__);
    }
    
    [file closeFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}

@end
