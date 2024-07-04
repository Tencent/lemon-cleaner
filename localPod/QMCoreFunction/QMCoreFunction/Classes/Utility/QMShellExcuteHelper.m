//
//  QMShellExcuteHelper.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMShellExcuteHelper.h"

// 默认cmd 10.0s超时
static NSTimeInterval kDefaultTimeout = 10.0;

@implementation QMShellExcuteHelper

+(NSString *)excuteCmd:(NSString *)cmd
{
    return [self excuteCmd:cmd timeout:kDefaultTimeout];
}

+ (NSString *)excuteCmd:(NSString *)cmd timeout:(NSTimeInterval)timeout {
    if (@available(macOS 14.0, *)) {
        return [self __excuteCmd:cmd timeout:timeout];
    } else {
        return [self __excuteCmd:cmd timeout:0];
    }
}

+ (NSString *)__excuteCmd:(NSString *)cmd timeout:(NSTimeInterval)timeout {
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
    
    NSData *data = [[NSData alloc] init];
    __block BOOL terminatedForTimeout = NO;
    if (timeout > 0) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self taskWithTimeout:timeout semaphore:semaphore completion: ^(BOOL isTimedOut){
            terminatedForTimeout = isTimedOut;
            if (isTimedOut) {
                [task terminate];
            }
        }];
        // 获取运行结果
        data = [file readDataToEndOfFile];
        [task waitUntilExit];
        dispatch_semaphore_signal(semaphore);
    } else {
        data = [file readDataToEndOfFile];
        [task waitUntilExit];
    }
    
    int status = [task terminationStatus];
    if (status == 0) {
        //NSLog(@"%s, Task succeeded.", __FUNCTION__);
    } else {
        if (!terminatedForTimeout) {
            [task terminate];
        }
        NSLog(@"%s, Task failed.", __FUNCTION__);
    }
    
    [file closeFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (void)taskWithTimeout:(NSTimeInterval)timeout semaphore:(dispatch_semaphore_t)semaphore completion:(void(^)(BOOL))completion {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    });
    dispatch_async(queue, ^{
        dispatch_time_t timeout_time_t = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
        long result = dispatch_semaphore_wait(semaphore, timeout_time_t);
        BOOL value = result != 0;
        completion(value);
    });
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
