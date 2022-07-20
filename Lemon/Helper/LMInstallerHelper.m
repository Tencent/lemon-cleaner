//
//  LMInstallerUtil.m
//  LemonInstaller
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMInstallerHelper.h"
#import "LemonDaemonConst.h"
#import <AppKit/AppKit.h>
#import <QMCoreFunction/STPrivilegedTask.h>
#import <QMCoreFunction/McPipeStruct.h>
#import <semaphore.h>

@interface LMInstallerHelper()
+ (void)unlinkOldSem:(NSString *)path;
@end

@implementation LMInstallerHelper

+ (NSString *)oldInstalledVersion
{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *versionPath = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *instVersion = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:nil];
    return instVersion;
}

+ (NSString *)versionOfApp:(NSString *)appPath
{
    NSString *curVersion = [[[NSBundle bundleWithPath:appPath] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return curVersion;
}

+ (void)moveToApplicationForApp:(NSString *)appPath
{
    NSString *dstPath = [appPath stringByAppendingPathComponent:MAIN_APP_NAME];
    // 先判断自己是否在 Application 目录下，不是则拷贝后再运行
    NSAppleScript *script = nil;
    NSString *finderPathFormat = [appPath stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    // 使用finder来copy，避免权限问题
    NSString *copyScript = [NSString stringWithFormat:@"tell application \"Finder\"\n"
                            "set sourceapp to ((startup disk as text) & \"%@\") as alias\n"
                            "set destfolder to ((startup disk as text) & \":Applications\") as alias\n"
                            "duplicate sourceapp to destfolder with replacing\n"
                            "end tell", finderPathFormat];
    // 先delete
    NSString *copyScript_107 = [NSString stringWithFormat:@"tell application \"Finder\"\n"
                                "set sourceapp to ((startup disk as text) & \"%@\") as alias\n"
                                "set removeapp to ((startup disk as text) & \":Applications:%@\") as alias\n"
                                "set destfolder to ((startup disk as text) & \":Applications\") as alias\n"
                                "delete removeapp\n"
                                "duplicate sourceapp to destfolder with replacing\n"
                                "end tell", finderPathFormat, MAIN_APP_NAME];
    
    SInt32 versionMajor=0, versionMinor=0;
    Gestalt(gestaltSystemVersionMajor, &versionMajor);
    Gestalt(gestaltSystemVersionMinor, &versionMinor);
    
    script = [[NSAppleScript alloc] initWithSource:copyScript];
    // 如果是10.7的系统并且Applications目录下文件已存在，则要先delete
    if (versionMajor == 10 && versionMinor < 8 && [[NSFileManager defaultManager] fileExistsAtPath:dstPath])
    {
        script = [[NSAppleScript alloc] initWithSource:copyScript_107];
    }
    NSDictionary *error;
    [script executeAndReturnError:&error];
    NSLog(@"moveToApplicationForApp excecute script %@", error);
}

// 开始安装
+ (int)startToInstall
{
    NSString *appPath = DEFAULT_APP_PATH;
    NSString *agentPath = [[[NSBundle bundleWithPath:appPath] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    NSString *curVersion = [[[NSBundle bundleWithPath:appPath] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    // 所有参数 - 命令参数 | 用户名 | 版本号 | 主进程ID
    NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kInstallCmd_cstr],
                          NSUserName(),
                          curVersion,
                          [NSString stringWithFormat:@"%d", getpid()],nil];
    
    // 获取用户权限来启动
    NSLog(@"angnetPath %@, args:%@", agentPath, arguments);
    STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:agentPath arguments:arguments];
    [instTask waitUntilExit];
    int retcode = [instTask terminationStatus];
    return retcode;
}

+ (void)unlinkOldSem
{
    [LMInstallerHelper unlinkOldSem:MCPIPE_NAME_FSMON];
    [LMInstallerHelper unlinkOldSem:MCPIPE_NAME_PROC];
    [LMInstallerHelper unlinkOldSem:MCPIPE_NAME_SOCK];
}

+ (void)unlinkOldSem:(NSString *)path
{
    NSString* path_read = [path stringByAppendingString:MCREAD_POSTFIX];
    NSString* path_write = [path stringByAppendingString:MCWRITE_POSTFIX];
    NSString *semReadPath = [[path_read lastPathComponent] stringByAppendingString:MCSEM_POSTFIX];
    NSString *semWritePath = [[path_write lastPathComponent] stringByAppendingString:MCSEM_POSTFIX];
    
    sem_unlink([semReadPath UTF8String]);
    sem_unlink([semWritePath UTF8String]);
    NSLog(@"sem %s readPath： %@", __FUNCTION__,semReadPath);
    NSLog(@"sem %s writePath: %@", __FUNCTION__,semWritePath);
}


@end



