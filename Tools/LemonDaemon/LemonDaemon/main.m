//
//  main.m
//  LemonDaemon
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LemonDaemonConst.h"
#import "CmcSystem.h"
#import "McPipeThread.h"
#import "McUninstall.h"
#import "OwlManageDaemon.h"
#import "LemonBizManager.h"
#import "LMDaemonListenerDelegate.h"
#import "DaemonStartup.h"
#import "LemonBizManager.h"
#import "LMPlistHelper.h"
#import "CmcFileAction.h"

void redirectNSLog(NSString *suffix, NSInteger persistDays){
    NSString *logName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
    
    // do not redirect in test mode
    if (![[[NSBundle mainBundle] executablePath] hasPrefix:@"/Library"])
        return;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *rootPath;
    if (getuid() == 0) {
        rootPath = @"/Library/Logs/Lemon";
    } else {
        rootPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Logs/Lemon"];
    }
    BOOL isDir;
    if (![fileMgr fileExistsAtPath:rootPath isDirectory:&isDir] || !isDir) {
        [fileMgr createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@-%@.log", logName, suffix];
    
    
    NSString *logfilePath = [rootPath stringByAppendingPathComponent:fileName];
   
    NSLog(@"%s to %@", __FUNCTION__, logfilePath);
    // clean log file
 
    if (![fileMgr fileExistsAtPath:logfilePath]) {
        [fileMgr createFileAtPath:logfilePath contents:[NSData data] attributes:nil];
    }
    
    NSDictionary *fileAttributes = [fileMgr attributesOfItemAtPath:logfilePath error:nil];
    if (fileAttributes) {
        NSDate *date = [fileAttributes objectForKey:NSFileCreationDate];
        NSTimeInterval createTimeInterval = [date timeIntervalSince1970];
        NSTimeInterval todayTimeInterval = [[NSDate date] timeIntervalSince1970];
        NSInteger persistTime  = persistDays * 24 * 3600;
//        NSLog(@"%s, fileLifeInterval:%f, %@, persis:%ld, ", __FUNCTION__, (todayTimeInterval - createTimeInterval), logfilePath, persistTime);
        if ((todayTimeInterval - createTimeInterval) > persistTime) {
            [fileMgr createFileAtPath:logfilePath contents:[NSData data] attributes:nil];
            NSLog(@"%s, fileLifeInterval:%f, newFile:%@", __FUNCTION__, (todayTimeInterval - createTimeInterval), logfilePath);
        }
    }
    
    id handle = [NSFileHandle fileHandleForWritingAtPath:logfilePath];
    
    [handle seekToEndOfFile];

    if (handle != nil)
    {
        dup2([handle fileDescriptor], STDERR_FILENO);
    }
}

void* bundleCopyCallBack()
{
    CFURLRef bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)DEFAULT_APP_PATH, kCFURLPOSIXPathStyle, true);
    CFBundleRef mainBundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
    CFRelease(bundleURL);
    
    return mainBundle;
}

BOOL isAppRunningBundleId(NSString *bundelId){
    NSArray *runnings= [NSRunningApplication runningApplicationsWithBundleIdentifier:bundelId];
    NSLog(@"[TrashDel, running%@:%@", bundelId, runnings);
    return [runnings count] > 0;
}



int main(int argc, const char * argv[])
{

    @autoreleasepool
    {
        NSLog(@"%s args: ", __FUNCTION__);
        
        for(int i = 0; i < argc; i++) {
            NSLog(@"   %s", argv[i]);
        }

        if (argc == 2 && strcmp(argv[1], kReloadListenPlist) == 0) {
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
            NSLog(@"reloadListenPlist");
            setuid(0);
            reloadListenPlist();
            return 0;
        }
        
        if (argc == 2 && strcmp(argv[1], kStartupDaemon_cstr) == 0) {
            /* 注意， 这里不能redirectNSLog， 因为startDaemon时，NSLog是重定向到socket的
               startDaemon时，通过NSLog给client发送，启动结果，如果这里redirectNSLog，client就收不到标志位，做成卡顿。
            */
            NSLog(@"startup daemon");
            //返回数据后再重定向
            startDaemon(); //唤醒
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 7);
            printDaemonOrAgentsStatus();
            return 0;
        }
        
        if (argc == 2 && strcmp(argv[1], kCopySelfToApplication) == 0) {
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
            setuid(0);
            copyFileIfNeed();
            return 0;
        }
        

        // 安装命令 - 命令参数 | 用户名 | 版本号 | 主进程ID
        if (argc == 5 && strcmp(argv[1], kInstallCmd_cstr) == 0)
        {
            // 安装流程，会先删旧再装新，删旧的时候不会删perference
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
            NSLog(@"[QMAgent] Ready to install for %s (ver: %s)", argv[2], argv[3]);
            NSLog(@" agent Path:%@", [[NSBundle mainBundle] bundlePath]);
            int nRet = InstallCastle(argv[2], argv[3], atoi(argv[4]));
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kInstallFinishNotify
                                                                           object:[[NSNumber numberWithInt:nRet] stringValue]
                                                                         userInfo:nil
                                                                        options:NSNotificationPostToAllSessions];
            NSLog(@"[install] return");
            return nRet;
        }
        
        // 安装命令 - 命令参数 | 用户名 | 版本号 | 主进程ID
        if (argc == 6 && strcmp(argv[1], kRepairCmd_cstr) == 0)
        {
            // 安装流程，会先删旧再装新，删旧的时候不会删perference
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
            NSLog(@"[QMAgent] Ready to install for %s (ver: %s)", argv[2], argv[3]);
            NSLog(@" agent Path:%@", [[NSBundle mainBundle] bundlePath]);
            
            
            // 移动文件时先把卸载监听unload掉
            unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
            unloadAgentPlistByLableForAllUser(DAEMON_UNINSTALL_LAUNCHD_LABLE);
            if (fileMoveTo(argv[5], (char *)[DEFAULT_APP_PATH UTF8String], MCCMD_MOVEFILE_MOVE) == -1)
            {
                NSLog(@"Update fail when replacing APP file");
                return -1;
            }
            
            int nRet = InstallCastle(argv[2], argv[3], atoi(argv[4]));
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kInstallFinishNotify
                                                                           object:[[NSNumber numberWithInt:nRet] stringValue]
                                                                         userInfo:nil
                                                                        options:NSNotificationPostToAllSessions];
            NSLog(@"[install] return");
            return nRet;
        }
        
        //sleep(50);
        
        // 卸载
        if (argc == 2 && strcmp(argv[1], kUninstallCmd_cstr) == 0)
        {
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
            //DEFAULT_APP_PATH有变化就会触发kUninstallCmd_cstr，所以这里必须判断一下Lemon.app在不在
            // 再确定要不要卸载。
            if (![[NSFileManager defaultManager] fileExistsAtPath:DEFAULT_APP_PATH]) {
                NSLog(@"%@ not exist, go to uninstall", DEFAULT_APP_PATH);
                uninstallSub();
            } else {
                NSLog(@"%@ exist, no need to uninstall", DEFAULT_APP_PATH);
            }
            return 0;
        }
        
        //重定向日志输出
        if (argc >= 2) {
            redirectNSLog([NSString stringWithUTF8String:argv[1]], 30);
        } else {
            redirectNSLog(nil, 7);
        }
        
        // 必须是要由系统Daemon加载
        if (argc != 2 || strcmp(argv[1], kLoadCmd_cstr) != 0)
        {
            NSLog(@"LemonDaemon kLoadCmd_cstr error");
            return 0;
        }
       
        NSLog(@"LemonDaemon main run");
        
        
        // 检测Daemon是否真的要启动。
        // 主要是用于处理开机自启的情况，开机时系统会把/LaunchDaemon下的plist都加载一遍, 造成会把Daemon拉活。
        // 所以这里检测到没有client在，直接退出。
        if (isNeedExitDaemon(0)) {
            exitDaemon();
            exit(0);
        }
        
        // 卸载自身(当Monitor的卸载机制出现异常,Agent下次启动时(比如开机时)卸载自身)
        if (![[NSFileManager defaultManager] fileExistsAtPath:DEFAULT_APP_PATH])
        {
            NSLog(@"LemonDaemon DEFAULT_APP_PATH error， begin to uninstall");
            uninstallCastle();
            return 0;
        }
        
        // 注册返回主bundle的回调
        CmcRegisterBundleCallBack(&bundleCopyCallBack);
                
        // 需要手动设置版本号
        NSString *curVersion = [[[NSBundle bundleWithPath:DEFAULT_APP_PATH] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        curVersion = [curVersion stringByAppendingString:@".1"];
               
        NSOperationQueue *operQueue = [[NSOperationQueue alloc] init];
                
        NSXPCListener *listener = nil;
        LMDaemonListenerDelegate *delegate = nil;
   
        //11.3及以上系统暂时屏蔽隐私防护功能入口
        if (@available(macOS 11.3, *)) {
        } else {
            [OwlManageDaemon shareInstance];
        }
        
        //use xpc
        {
            NSLog(@"LemonDaemon use xpc");
            delegate = [LMDaemonListenerDelegate new];
            // Set up the one NSXPCListener for this service. It will handle all incoming connections.
            listener = [[NSXPCListener alloc] initWithMachServiceName:DAEMON_APP_BUNDLEID];
            listener.delegate = delegate;
            // Resuming the serviceListener starts this service. This method does not return.
            [listener resume];
            NSLog(@"LemonDaemon NSXPCListener resume");
        }
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

