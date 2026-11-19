//
//  McUninstall.m
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "McUninstall.h"
#import "CmcProcess.h"
#import "CmcFileAction.h"
#import "McPipeStruct.h"
#import "QMLaunchpadClean.h"
#import "LMDMVersionHelper.h"
#import <pwd.h>
#import <semaphore.h>
#import <sys/stat.h>
#import <sys/xattr.h>
#import <errno.h>
#import <Security/Security.h>
#import "LMPlistHelper.h"
#import "ExecuteCmdHelper.h"

// 判断当前系统版本是否在指定版本数组中的公共方法
BOOL isCurrentSystemVersionInArray(NSArray<NSString *> *versionArray) {
    if (versionArray.count == 0) {
        return NO;
    }
    
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *currentVersion = [NSString stringWithFormat:@"%ld.%ld.%ld",
                                    systemVersion.majorVersion,
                                    systemVersion.minorVersion,
                                    systemVersion.patchVersion];
    
    return [versionArray containsObject:currentVersion];
}

// 13.7.5 / 13.7.5 用户覆盖安装后守护进程拉不起来，发现控制 "com.tencent.Lemon.listen" 在该版本上失效，使用  "com.tencent.Lemon"
BOOL isRepairFailedSystemVersion(void) {
    return isCurrentSystemVersionInArray(@[@"13.7.5", @"13.7.6"]);
}

//如果Application里没有Lemon.app或version不一样，则执行copy操作。
int copyFileIfNeed() {
    NSLog(@"%s", __FUNCTION__);
    // 这里selfPath获取到的是daemon在app中的路径
    //daemon放在Lemon.app/Contents/Frameworks目录下。
    NSString *selfPath = [[NSBundle mainBundle] bundlePath];
    NSString *selfAppPath = [[selfPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([selfAppPath isEqualToString:DEFAULT_APP_PATH]) {
        //现在return 0;
        NSLog(@"%s selfAppPath=%@, already in /Applications no need to copy", __FUNCTION__, selfAppPath);
        return 0;
    }
    BOOL isExistInApplication = [fm fileExistsAtPath:DEFAULT_APP_PATH];
    
    NSString *myVer = [LMDMVersionHelper fullVersionFromBundle:[NSBundle bundleWithPath:selfAppPath]];
    NSString *oldVer = [LMDMVersionHelper fullVersionFromBundle:[NSBundle bundleWithPath:DEFAULT_APP_PATH]];
    BOOL isSameAsInstalledVersion = oldVer == nil ? FALSE:[myVer isEqualToString:oldVer];
    NSLog(@"%s, oldVer = %@, newVer = %@", __FUNCTION__, oldVer, myVer);
    NSLog(@"%s selfPath=%@, LemonInApplicationPath:%d", __FUNCTION__, selfAppPath, isExistInApplication);
    
    int ret = 0;
    if (!isExistInApplication || !isSameAsInstalledVersion) {
        NSLog(@"%s, need to move file", __FUNCTION__);
        // copy的时候先把卸载监控unload掉
        unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
        // 上一次卸载的时候，在uninstall 例程里unload uninstall plist, 因为launch unload的时候会杀Daemon进程，
        // 但有时Daemon杀不死，系统会在当前用户下，注册一个uninstall plist agent，
        // 然后把Daemon下的uninstall plist remove掉。所以这里做一下清理工作。
        unloadAgentPlistByLableForAllUser(DAEMON_UNINSTALL_LAUNCHD_LABLE);
        if (fileMoveTo((char *)[selfAppPath UTF8String], (char *)[DEFAULT_APP_PATH UTF8String], MCCMD_MOVEFILE_COPY) == -1)
        {
            NSLog(@"%s Update fail when replacing APP file", __FUNCTION__);
            ret = -1;
        }
        loadPlist(DAEMON_UNINSTALL_LAUNCHD_PATH);
    } else {
        NSLog(@"%s, no need to move file", __FUNCTION__);
    }
    return ret;
}


// Security fix: reloadListenPlist() 已移除，socket 唤醒机制不再使用

void unlinkOldSemWithPath(NSString *path)
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

void unlinkOldSem(void)
{
    NSLog(@"%s", __FUNCTION__);
    unlinkOldSemWithPath(MCPIPE_NAME_FSMON);
    unlinkOldSemWithPath(MCPIPE_NAME_PROC);
    unlinkOldSemWithPath(MCPIPE_NAME_SOCK);
}

// 解压app到指定的目录
void unzipToolApp(NSString *srcPath, NSString *dstPath)
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    //创建临时目录
    NSString *tempFolderPath =  nil;
    do {
        tempFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%u",arc4random()]];
    } while ([fileMgr fileExistsAtPath:tempFolderPath]);
    [fileMgr createDirectoryAtPath:tempFolderPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/unzip"];
    [task setArguments:@[@"-q",srcPath,@"-d",tempFolderPath]];
    [task launch];
    [task waitUntilExit];
    
    //在解压后的目录中寻找文件
    NSArray *contentsItems = [fileMgr contentsOfDirectoryAtPath:tempFolderPath error:NULL];
    for (NSString *subItem in contentsItems)
    {
        if (![[subItem.pathExtension lowercaseString] isEqualToString:@"app"])
            continue;
        
        NSString *findFilePath = [tempFolderPath stringByAppendingPathComponent:subItem];
        [fileMgr removeItemAtPath:dstPath error:NULL];
        [fileMgr moveItemAtPath:findFilePath toPath:dstPath error:NULL];
        
        break;
    }
    
    //删除临时目录
    [fileMgr removeItemAtPath:tempFolderPath error:NULL];
}

// 强行移动小工具到新目录
void updateTools()
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *toolsDir = [APP_SUPPORT_PATH stringByAppendingPathComponent:TOOLS_INSTALL_DIR];
    
    NSDictionary *toolAttr = @{NSFilePosixPermissions:@(0777)};
    NSArray *toolNames = @[@"QMDuplicateFile.app",@"QMBigOldFile.app",@"QMNetSpeed.app",@"QMWireLurkerKiller.app"];
    
    for (NSString *toolName in toolNames)
    {
        NSString *toolPath = [toolsDir stringByAppendingPathComponent:toolName];
        NSString *oldPath = [[DEFAULT_APP_PATH stringByDeletingLastPathComponent] stringByAppendingPathComponent:toolName];
        if (![fileMgr fileExistsAtPath:toolPath] && [fileMgr fileExistsAtPath:oldPath])
        {
            NSString *exeName = [[[NSBundle bundleWithPath:oldPath] executablePath] lastPathComponent];
            NSCharacterSet *allowedExeChars = [NSCharacterSet characterSetWithCharactersInString:
                                               @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"];
            if (exeName.length > 0 &&
                [exeName rangeOfCharacterFromSet:[allowedExeChars invertedSet]].location == NSNotFound) {
                executeLaunchPath(@"/usr/bin/killall", @[exeName]);
            } else if (exeName.length > 0) {
                NSLog(@"[security] updateTools: reject invalid exeName: %@", exeName);
            }
            [fileMgr moveItemAtPath:oldPath toPath:toolPath error:nil];
            [fileMgr setAttributes:toolAttr ofItemAtPath:toolPath error:nil];
        }
    }
    
    @try {
        [QMLaunchpadClean cleanLaunchpad];
    }
    @catch (NSException *exception) {
        return;
    }
}

uid_t getUidOfUser(NSString *userName) {
    struct passwd *pwd;
    pwd = getpwnam([userName UTF8String]);
    uid_t uid = pwd->pw_uid;
    NSLog(@"%s, userName:%@, uid:%d", __FUNCTION__, userName, uid);
    return uid;
}

void delFileOrDir(NSString *file) {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error = nil;
    // remove deamon plist file
    if (![fileMgr removeItemAtPath:file error:&error]) {
        NSLog(@"removeAllFiles %@ error: %@", file, error);
    }else{
        NSLog(@"removeAllFiles %@ success: %@", file, error);
    }
}


void killProcessByExecname(NSArray<NSString *> * execNameArray) {
    NSLog(@"%s", __FUNCTION__);
    ProcessInfo_t *proc_info = NULL;
    int ret = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    NSProcessInfo *curProcessInfo = [NSProcessInfo processInfo];
    int curProcessId = [curProcessInfo processIdentifier];
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            // 预防要杀其他Daemon进程的时候，把自己杀了
            if (curProcessId == proc_info[i].pid) {
                continue;
            }
            exeName = [NSString stringWithUTF8String:proc_info[i].pExeName];
            //覆盖安装的时候也强杀下Monitor
            //            NSLog(@"%s, exeName:%@, path:%s, pid:%d", __FUNCTION__,exeName, proc_info[i].pExeName, proc_info[i].pid);
            if ([execNameArray containsObject:exeName]) {
                system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                NSLog(@"kill: '%@' Process ID:'%d'", exeName, proc_info[i].pid);
            }
        }
    }
    
    if (proc_info != NULL)
        free(proc_info);
}


// 根据应用名杀应用，但用户exceptUser下的应用不杀。
void killProcessByExecnameExceptUser(NSArray<NSString *> * execNameArray, const char *exceptUser) {
    NSLog(@"%s", __FUNCTION__);
    ProcessInfo_t *proc_info = NULL;
    int ret = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    NSProcessInfo *curProcessInfo = [NSProcessInfo processInfo];
    int curProcessId = [curProcessInfo processIdentifier];
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            // 预防要杀其他Daemon进程的时候，把自己杀了
            if (curProcessId == proc_info[i].pid) {
                continue;
            }
            
            if (strcmp(proc_info[i].pUserName, exceptUser) == 0) {
                continue;
            }
            
            exeName = [NSString stringWithUTF8String:proc_info[i].pExeName];
            if ([execNameArray containsObject:exeName]) {
                system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                NSLog(@"kill: '%@' of user:%s Process ID:'%d'", exeName, proc_info[i].pUserName,  proc_info[i].pid);
            }
        }
    }
    
    if (proc_info != NULL)
        free(proc_info);
}


//卸载自身时做最后清理操作
void removeAllFiles()
{
    // 卸载自身
    //    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl unload %@", DAEMON_LAUNCHD_PATH];
    //    pid_t status = system([unloadCmd UTF8String]);
    //    if (-1 == status)
    //    {
    //        NSLog(@"removeAllFiles system error: %d", status);
    //    }
    //    else
    //    {
    //        NSLog(@"removeAllFiles exit status value = [0x%x]", status);
    //        if (WIFEXITED(status))
    //        {
    //            if (0 == WEXITSTATUS(status))
    //            {
    //                NSLog(@"removeAllFiles run shell script successfully");
    //            }
    //            else
    //            {
    //                NSLog(@"removeAllFiles run shell script fail, script exit code: %d", WEXITSTATUS(status));
    //            }
    //        }
    //        else
    //        {
    //            NSLog(@"removeAllFiles run shell script fail, script exit code: %d", WEXITSTATUS(status));
    //        }
    //    }
    unloadPlist(DAEMON_LAUNCHD_PATH);
    unloadPlist(TRASH_MONITOR_LAUNCHD_PATH);
    
    //    // remove all files
    //    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //    NSString *mainAppPath = DEFAULT_APP_PATH;
    //    NSString *agentLaunchdFile = DAEMON_LAUNCHD_PATH;
    //    NSString *supportPath = APP_SUPPORT_PATH;
    //
    //    NSError *error = nil;
    //    // remove main app
    //    // 现在只有拖到垃圾统卸载方法，所以mainAppPath已经没有Lemon.app这里不进行删除，避免误删用户移入的t新lemon.app
    //    // 如果后续采用卸载程序，需要加回来，同时要解决可能会误删新包的问题。
    //    //    if (![fileMgr removeItemAtPath:mainAppPath error:&error]) {
    //    //        NSLog(@"removeAllFiles mainAppPath error: %@", error);
    //    //    }
    //    //
    //    // remove deamon plist file
    //    if (![fileMgr removeItemAtPath:agentLaunchdFile error:&error]) {
    //        NSLog(@"removeAllFiles agentLaunchdFile error: %@", error);
    //    }
    //
    //    if (![fileMgr removeItemAtPath:TRASH_MONITOR_LAUNCHD_PATH error:&error]) {
    //        NSLog(@"removeAllFiles trashMonitorLaunchdFile error: %@", error);
    //    }
    //
    //    // remove support folder
    //    if (![fileMgr removeItemAtPath:supportPath error:&error]) {
    //        NSLog(@"removeAllFiles supportPath error: %@", error);
    //    }
    
    delFileOrDir(DEFAULT_APP_PATH);
    delFileOrDir(DAEMON_LAUNCHD_PATH);
    delFileOrDir(APP_SUPPORT_PATH);
    delFileOrDir(APP_SUPPORT_PATH2);
    delFileOrDir(DAEMON_STARTUP_LISTEN_LAUNCHD_PATH);
    
}

// 移除文件和unload agent和daemon， 不删用户目录的data和pref, 不unload uninstall的plist (为了在卸载和覆盖安装时能复用代码）
void removeFilesExceptUserFileAndUninstallDaemon() {
    NSLog(@"%s", __FUNCTION__);
    //    unloadPlist(DAEMON_LAUNCHD_PATH);
    //    unloadPlist(TRASH_MONITOR_LAUNCHD_PATH);
    //    unloadAgentPlist(MONITOR_LAUNCHD_PATH);
    //没有plist也能unload
    
    NSArray<NSNumber *> * uidArray = getCurrentLogInUserId();
    NSLog(@"curr login user:%@", uidArray);
    for (NSNumber *uid in uidArray) {
        NSLog(@"kill agent for %@", uid);
        unloadAgentPlistByLabel(MONITOR_LAUNCHD_LABLE, [uid intValue]);
        unloadAgentPlistByLabel(TRASH_MONITOR_LAUNCHD_LABLE, [uid intValue]);
        // 上一次卸载的时候，在uninstall 例程里unload uninstall plist, 因为launch unload的时候会杀Daemon进程，
        // 但有时Daemon杀不死，系统会在当前用户下，注册一个uninstall plist agent，
        // 然后把Daemon下的uninstall plist remove掉。所以这里做一下清理工作。
        unloadAgentPlistByLabel(DAEMON_UNINSTALL_LAUNCHD_LABLE, [uid intValue]);
    }
    
    unloadPlistByLable(DAEMON_LAUNCHD_LABLE);
    unloadPlistByLable(OLD_DAEMON_LAUNCHD_LABLE);
    unloadPlistByLable(DAEMON_STARTUP_LISTEN_LABLE);

    // remove deamon plist file
    delFileOrDir(DAEMON_LAUNCHD_PATH);
    
    delFileOrDir(MONITOR_LAUNCHD_PATH);
    delFileOrDir(DAEMON_STARTUP_LISTEN_LAUNCHD_PATH);
    
    //这里是为了兼容旧版本的1.06版本，1.06版本卸载残留检测注册的是Daemon, plist放在/Library/LaunchDaemons/com.tencent.Lemon.trash.plist里
    //1.07版移到了~/Library/LaunchAgents/com.tencent.Lemon.trash.plist中，并且注册成了Agent.
    unloadPlistByLable(TRASH_MONITOR_LAUNCHD_LABLE);
    
    //删除用户目录下的~/Library/LaunchAgents/com.tencent.Lemon.trash.plist
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *userNameArray = [fileMgr contentsOfDirectoryAtPath:@"/Users/" error:nil];
    for (NSString *userName in userNameArray)
    {
        if ([userName isEqualToString:@"Shared"] || [userName hasPrefix:@"."])
            continue;
        
        NSString *homePath = [NSString stringWithFormat:@"/Users/%@", userName];
        
        // 删除配置文件
        NSString *plistPath = [homePath stringByAppendingPathComponent:TRASH_MONITOR_LAUNCHD_PATH];
        delFileOrDir(plistPath);
    }
    
    // 删除support 目录
    delFileOrDir(APP_SUPPORT_PATH);
    delFileOrDir(APP_SUPPORT_PATH2);
    //删除旧版本的Monitor
//    delFileOrDir(MONITOR_APP_PATH);
    delFileOrDir(OLD_MONITOR_APP_PATH);
    delFileOrDir(OLD_MONITOR_APP_PATH_2);

}



int intsallSub(const char *szUserName, const char *szVersion, int nUserPid)
{
    NSLog(@"%s", __FUNCTION__);
    
    
    // 确认自身是在Applications目录下运行
    NSString *selfPath = [[NSBundle mainBundle] executablePath];
    NSString *selfFolder = [selfPath stringByDeletingLastPathComponent];
    if (![selfFolder hasPrefix:DEFAULT_APP_PATH])
    {
        return QMINST_ERR_POSITION;
    }
    
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // 检查用户名是否真实
    //    NSString *userHomePath = [NSString stringWithFormat:@"/Users/%s", szUserName];
    //    if (![fileMgr fileExistsAtPath:userHomePath])
    //    {
    //        return;
    //    }
    
    // 创建support目录
    NSString *supportPath = APP_SUPPORT_PATH;
    if (![fileMgr createDirectoryAtPath:supportPath withIntermediateDirectories:YES attributes:nil error:nil])
    {
        return QMINST_ERR_CREATESUPPORT;
    }
    
    //文件权限及所有者
    NSDictionary *modeAttr = @{NSFilePosixPermissions:@(0777)};//[NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
    NSDictionary *rootAttr = @{NSFileOwnerAccountName:@"root",NSFileGroupOwnerAccountName:@"admin"};
    
    // 创建用户可读写的Data目录
    NSString *dataPath = [supportPath stringByAppendingPathComponent:APP_DATA_NAME];
    if (![fileMgr createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:modeAttr error:nil])
    {
        return QMINST_ERR_CREATEDATA;
    }
    
    // 创建小工具安装的目录
    NSString *toolsPath = [supportPath stringByAppendingPathComponent:TOOLS_INSTALL_DIR];
    if (![fileMgr createDirectoryAtPath:toolsPath withIntermediateDirectories:YES attributes:modeAttr error:nil])
    {
        return QMINST_ERR_CREATEDATA;
    }
    
    // 将自身拷贝过去
    NSString *agentPath = [supportPath stringByAppendingPathComponent:[selfPath lastPathComponent]];
    [fileMgr removeItemAtPath:agentPath error:nil];
    if (![fileMgr copyItemAtPath:selfPath toPath:agentPath error:nil])
    {
        return QMINST_ERR_COPYSELF;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:agentPath error:nil];
    // [macOS 27 适配] 清理 daemon 二进制的 quarantine 属性
    removexattr([agentPath fileSystemRepresentation], "com.apple.quarantine", 0);
    
    //MARK: 拷贝monitor
    NSString *monitorSrcPath = MONITOR_SRC_APP_PATH;
//    NSString *monitorDstPath = [supportPath stringByAppendingPathComponent:[monitorSrcPath lastPathComponent]];
    NSString *monitorDstPath = MONITOR_APP_PATH;
//    [fileMgr removeItemAtPath:monitorDstPath error:nil];
//    if (![fileMgr copyItemAtPath:monitorSrcPath toPath:monitorDstPath error:nil])
//    {
//        NSLog(@"%s,monitor 拷贝识失败...",__FUNCTION__);
//        return QMINST_ERR_COPYSELF;
//    }
//
    // 检查目录并创建
    NSString *daemonFolder = [DAEMON_LAUNCHD_PATH stringByDeletingLastPathComponent];
    NSString *monitorFolder = [MONITOR_LAUNCHD_PATH stringByDeletingLastPathComponent];
    if (![fileMgr fileExistsAtPath:daemonFolder])
        [fileMgr createDirectoryAtPath:daemonFolder withIntermediateDirectories:NO attributes:nil error:nil];
    if (![fileMgr fileExistsAtPath:monitorFolder])
        [fileMgr createDirectoryAtPath:monitorFolder withIntermediateDirectories:NO attributes:nil error:nil];
    
    // 拷贝launchd配置文件
    NSString *agentLaunchdSrcPath = [selfFolder stringByAppendingPathComponent:[DAEMON_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:DAEMON_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:agentLaunchdSrcPath toPath:DAEMON_LAUNCHD_PATH error:nil])
    {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_LAUNCHD_PATH error:nil];
    // [macOS 27 适配] 清理 quarantine 属性，否则 launchd 拒绝加载
    removexattr([DAEMON_LAUNCHD_PATH fileSystemRepresentation], "com.apple.quarantine", 0);
    // 无条件 load daemon plist，确保安装后 daemon 立即以 root 启动
    {
        int result = loadPlist(DAEMON_LAUNCHD_PATH);
        NSLog(@"%s, load daemon plist result: %d", __FUNCTION__, result);
    }
    
    //    NSString *loadCmd = [NSString stringWithFormat:@"launchctl load -w %@", DAEMON_LAUNCHD_PATH];
    //    system([loadCmd UTF8String]);
    
    // Security fix: listen plist 拷贝逻辑已移除
    
    // 拷贝自身uninstall launchd配置文件
    NSString *uninsatllLaunchSrcPath = [selfFolder stringByAppendingPathComponent:[DAEMON_UNINSTALL_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:uninsatllLaunchSrcPath toPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil]) {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil];
    // [macOS 27 适配] 清理 quarantine 属性
    removexattr([DAEMON_UNINSTALL_LAUNCHD_PATH fileSystemRepresentation], "com.apple.quarantine", 0);
    loadPlist(DAEMON_UNINSTALL_LAUNCHD_PATH);
    
    
    // 安装用户权限的监控程序
    NSString *monitorLaunchdSrcPath = [selfFolder stringByAppendingPathComponent:[MONITOR_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:MONITOR_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:monitorLaunchdSrcPath toPath:MONITOR_LAUNCHD_PATH error:nil])
    {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:MONITOR_LAUNCHD_PATH error:nil];
    // [macOS 27 适配] 清理 monitor plist quarantine 属性
    removexattr([MONITOR_LAUNCHD_PATH fileSystemRepresentation], "com.apple.quarantine", 0);
    // [macOS 27 适配] 防御性清理 trash plist 的 quarantine（该 plist 由 AppTrashDel 安装，
    // 但可能继承 App Bundle 的 quarantine；对不存在的文件/属性 removexattr 返回 -1，无害）
    removexattr([TRASH_MONITOR_LAUNCHD_PATH fileSystemRepresentation], "com.apple.quarantine", 0);
    
    // 写入版本文件
    NSString *versionPath = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *versionStr = [NSString stringWithUTF8String:szVersion];
    [versionStr writeToFile:versionPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%s, write %@ to versionfile", __FUNCTION__, versionStr);
    
    // 修复小工具的安装目录
    updateTools();
    
    NSLog(@"Install finished PID: %d", getpid());
    return QMINST_ERR_OK;
}

int InstallCastle(const char *szUserName, const char *szVersion, int nUserPid)
{
    
    NSLog(@"%s, userName:%s", __FUNCTION__, szUserName);
    // 确认自身是root权限
    if (getuid() != 0 && geteuid() != 0)
    {
        return QMINST_ERR_PRIVILEGE;
    }
    
    // 自身设置为root，以免调用子程序时默认使用用户权限
    if (setuid(0) != 0)
    {
        return QMINST_ERR_PRIVILEGE;
    }
    
    // 杀其他登陆用户的Tencent Lemon.app 和update.app, 不杀当前登陆用户的Tencent Lemon和update.app， 因为安装流程可能是从update和双击Lemon触发，所以不能杀。
    //NSArray *lemonToKill = @[[MAIN_APP_NAME stringByDeletingPathExtension], [UPDATE_APP_NAME stringByDeletingPathExtension]];
    NSArray *lemonToKill = @[[MAIN_APP_NAME stringByDeletingPathExtension]]; //老代码(1.06及以下）传过来的userName有问题，暂时屏蔽杀update
    killProcessByExecnameExceptUser(lemonToKill, szUserName);
    
    // 清理旧的残留，不删除preference
    removeFilesExceptUserFileAndUninstallDaemon();
    
    //unload 卸载plist， 这里不放在removeFilesExceptUserFileAndUninstallDaemon的原因是
    //为了使removeFilesExceptUserFileAndUninstallDaemon的代码可以在卸载的时候复用。
    //卸载的时候removeFilesExceptUserFileAndUninstallDaemon里不能unload卸载的plist，因为unload卸载plist的时候同时会把
    //卸载程序杀掉。
    unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    delFileOrDir(DAEMON_UNINSTALL_LAUNCHD_PATH);
    
    // 杀进程
    NSArray * exeNamesToKill = @[DAEMON_APP_NAME, [MONITOR_APP_NAME stringByDeletingPathExtension], [OLD_MONITOR_APP_NAME stringByDeletingPathExtension]];
    //    NSArray * exeNamesToKill = @[[MONITOR_APP_NAME stringByDeletingPathExtension]];
    killProcessByExecname(exeNamesToKill);
    
    unlinkOldSem();
    
    // 13.7.5 / 13.7.6 安装新包卸载守护进程
    if (isRepairFailedSystemVersion()) {    // 13.7.5卸载listen无效
        delFileOrDir(DAEMON_STARTUP_LISTEN_SOCKT);  // 需要清理掉socket文件，否则还是无效
        int result = unloadPlistByLable(OLD_DAEMON_LAUNCHD_LABLE);
        NSLog(@" [repair] %s, unload deamon : %d", __FUNCTION__, result);
    }
    
    //    //真实安装
    return intsallSub(szUserName, szVersion, nUserPid);
}

// 安装  MARK:该方法没有使用？？
int InstallCastleOld(const char *szUserName, const char *szVersion, int nUserPid)
{
    
    NSLog(@"[TrashDel] InstallCastle");
    
    removeAllFiles();
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // 检查用户名是否真实
    //    NSString *userHomePath = [NSString stringWithFormat:@"/Users/%s", szUserName];
    //    if (![fileMgr fileExistsAtPath:userHomePath])
    //    {
    //        return;
    //    }
    
    NSString *selfPath = [[NSBundle mainBundle] executablePath];
    NSString *selfFolder = [selfPath stringByDeletingLastPathComponent];
    
    // 确认自身是在Applications目录下运行
    if (![selfFolder hasPrefix:DEFAULT_APP_PATH])
    {
        return QMINST_ERR_POSITION;
    }
    
    // 确认自身是root权限
    if (getuid() != 0 && geteuid() != 0)
    {
        return QMINST_ERR_PRIVILEGE;
    }
    
    // 自身设置为root，以免调用子程序时默认使用用户权限
    uid_t userId = getuid();
    if (setuid(0) != 0)
    {
        return QMINST_ERR_PRIVILEGE;
    }
    
    // 创建support目录
    NSString *supportPath = APP_SUPPORT_PATH;
    if (![fileMgr createDirectoryAtPath:supportPath withIntermediateDirectories:YES attributes:nil error:nil])
    {
        return QMINST_ERR_CREATESUPPORT;
    }
    
    //文件权限及所有者
    NSDictionary *modeAttr = @{NSFilePosixPermissions:@(0777)};//[NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0777] forKey:NSFilePosixPermissions];
    NSDictionary *rootAttr = @{NSFileOwnerAccountName:@"root",NSFileGroupOwnerAccountName:@"admin"};
    
    // 创建用户可读写的Data目录
    NSString *dataPath = [supportPath stringByAppendingPathComponent:APP_DATA_NAME];
    if (![fileMgr createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:modeAttr error:nil])
    {
        return QMINST_ERR_CREATEDATA;
    }
    
    // 创建小工具安装的目录
    NSString *toolsPath = [supportPath stringByAppendingPathComponent:TOOLS_INSTALL_DIR];
    if (![fileMgr createDirectoryAtPath:toolsPath withIntermediateDirectories:YES attributes:modeAttr error:nil])
    {
        return QMINST_ERR_CREATEDATA;
    }
    
    // 将自身拷贝过去
    NSString *agentPath = [supportPath stringByAppendingPathComponent:[selfPath lastPathComponent]];
    [fileMgr removeItemAtPath:agentPath error:nil];
    if (![fileMgr copyItemAtPath:selfPath toPath:agentPath error:nil])
    {
        return QMINST_ERR_COPYSELF;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:agentPath error:nil];
    
    //MARK: 拷贝monitor
//    NSString *monitorSrcPath = MONITOR_SRC_APP_PATH;
//    NSString *monitorDstPath = [supportPath stringByAppendingPathComponent:[monitorSrcPath lastPathComponent]];
//    [fileMgr removeItemAtPath:monitorDstPath error:nil];
//    if (![fileMgr copyItemAtPath:monitorSrcPath toPath:monitorDstPath error:nil])
//    {
//        return QMINST_ERR_COPYSELF;
//    }
//
    // 检查目录并创建
    NSString *daemonFolder = [DAEMON_LAUNCHD_PATH stringByDeletingLastPathComponent];
    NSString *monitorFolder = [MONITOR_LAUNCHD_PATH stringByDeletingLastPathComponent];
    if (![fileMgr fileExistsAtPath:daemonFolder])
        [fileMgr createDirectoryAtPath:daemonFolder withIntermediateDirectories:NO attributes:nil error:nil];
    if (![fileMgr fileExistsAtPath:monitorFolder])
        [fileMgr createDirectoryAtPath:monitorFolder withIntermediateDirectories:NO attributes:nil error:nil];
    
    // 拷贝launchd配置文件
    NSString *agentLaunchdSrcPath = [selfFolder stringByAppendingPathComponent:[DAEMON_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:DAEMON_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:agentLaunchdSrcPath toPath:DAEMON_LAUNCHD_PATH error:nil])
    {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_LAUNCHD_PATH error:nil];
    
    // launchctl直接加载Agent
    // 确保卸载残留的plist
    unloadPlist(DAEMON_LAUNCHD_PATH);
    // 旧版本plist中使用的Label是MAIN_APP_BUNDLEID非DAEMON_APP_BUNDLEID，所以确保残留在杀进程前先remove一次
    unloadPlistByLable(MAIN_APP_BUNDLEID);
    // 确保kill残留的daemon
    // terminate castle process
    ProcessInfo_t *proc_info = NULL;
    int ret = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            exeName = [[NSString stringWithUTF8String:proc_info[i].pExecutePath] lastPathComponent];
            NSProcessInfo *processInfo = [NSProcessInfo processInfo];
            if ([exeName isEqualToString:DAEMON_APP_NAME]) {
                int processID = [processInfo processIdentifier];
                if (processID != proc_info[i].pid) {
                    system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                    NSLog(@"kill other LaemonDaemon for InstallCastle: '%@' Process ID:'%d'", exeName, proc_info[i].pid);
                }
            }
            //覆盖安装的时候也强杀下Monitor
            if ([exeName isEqualToString:[MONITOR_APP_NAME stringByDeletingPathExtension]]) {
                system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                NSLog(@"kill LemonMonitor for InstallCastle: '%@' Process ID:'%d'", exeName, proc_info[i].pid);
            }
        }
    }
    if (proc_info != NULL)
        free(proc_info);
    
    loadPlist(DAEMON_LAUNCHD_PATH);
    
    // 为了保证Monitor启动时Agent的Pipe已经建立
    usleep(100*1000);
    
    // 安装垃圾桶监控服务，用于应用卸载残留检测
    NSString *trashMonitorLaunchdSrcPath = [selfFolder stringByAppendingPathComponent:[TRASH_MONITOR_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:TRASH_MONITOR_LAUNCHD_PATH error:nil];
    NSMutableDictionary *trashMonitorConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:trashMonitorLaunchdSrcPath];
    NSString *userTrashPath = [NSString stringWithFormat:@"/Users/%s/.Trash",szUserName];
    [trashMonitorConfig setObject:@[userTrashPath] forKey:@"WatchPaths"];
    if (![trashMonitorConfig writeToFile:TRASH_MONITOR_LAUNCHD_PATH atomically:NO]) {
        return QMINST_ERR_COPYMONITORPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:TRASH_MONITOR_LAUNCHD_PATH error:nil];
    // launchctl直接加载TrashMonitor
    //    NSString *unloadTrashMonitor = [NSString stringWithFormat:@"launchctl unload %@", TRASH_MONITOR_LAUNCHD_PATH];
    //    system([unloadTrashMonitor UTF8String]);
    //    NSString *loadCmdTrashMonitor = [NSString stringWithFormat:@"launchctl load -w %@", TRASH_MONITOR_LAUNCHD_PATH];
    //    system([loadCmdTrashMonitor UTF8String]);
    
    // 安装用户权限的监控程序
    NSString *monitorLaunchdSrcPath = [selfFolder stringByAppendingPathComponent:[MONITOR_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:MONITOR_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:monitorLaunchdSrcPath toPath:MONITOR_LAUNCHD_PATH error:nil])
    {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:MONITOR_LAUNCHD_PATH error:nil];
    
    // 写入版本文件
    NSString *versionPath = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *versionStr = [NSString stringWithUTF8String:szVersion];
    [versionStr writeToFile:versionPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%s, write %@ to versionfile", __FUNCTION__, versionStr);
    // 通过launchctl注册Monitor程序
    if (userId != 0)
    {
        // 重设userid来启动用户态的
        if (setuid(userId) != 0)
        {
            return QMINST_ERR_PRIVILEGE;
        }
        
        unloadPlist(MONITOR_LAUNCHD_PATH);
        system("killall Lemon\\ Menu\\ bar");
        //        loadCmd = [NSString stringWithFormat:@"launchctl load -w %@", MONITOR_LAUNCHD_PATH];
        //        system([loadCmd UTF8String]);
    }
    else
    {
        // 直接root权限拉起的更新过程
        unloadAgentPlistForUser(MONITOR_LAUNCHD_PATH, nUserPid, [NSString stringWithUTF8String:szUserName]);
        //killall命令有时候无法正常kill进程，废弃，使用kill -9来执行
        system("killall Lemon\\ Menu\\ bar");
        //        NSString *loadCmd = [NSString stringWithFormat:@"launchctl bsexec %d su %s -c 'launchctl load -w %@'",
        //                             nUserPid, szUserName, MONITOR_LAUNCHD_PATH];
        //        system([loadCmd UTF8String]);
    }
    
    
    // 修复小工具的安装目录
    updateTools();
    
    NSLog(@"Install finished PID: %d", getpid());
    return QMINST_ERR_OK;
}

// 用于删除某个用户的浏览器插件
void removeBrowserPlugins(NSString *homePath)
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *ffPath = [homePath stringByAppendingPathComponent:FIREFOX_PLUGIN_PATH];
    NSString *safariPath = [homePath stringByAppendingPathComponent:SAFARI_PLUGIN_PATH];
    
    // firefox和safari只删除文件
    [fileMgr removeItemAtPath:ffPath error:nil];
    [fileMgr removeItemAtPath:safariPath error:nil];
    
    // chrome插件的路径不固定，并且需要修改配置文件
    NSString *chromeFolder = [homePath stringByAppendingPathComponent:CHROME_PLUGIN_PATH];
    NSString *prefrenecePath = [homePath stringByAppendingPathComponent:CHROME_PREFERENCE_PATH];
    // 解析prefrenece
    NSData *data = [NSData dataWithContentsOfFile:prefrenecePath];
    if (!data) return;
    NSMutableDictionary *prefenceDict = [[NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingMutableContainers
                                                                           error:nil] mutableCopy];
    if (!prefenceDict) return;
    
    NSMutableDictionary *extensionDict = [[prefenceDict objectForKey:@"extensions"] mutableCopy];
    if (!extensionDict) return;
    
    NSMutableDictionary *settingDict = [[extensionDict objectForKey:@"settings"] mutableCopy];
    if (!settingDict) return;
    
    // 获取插件名
    NSMutableArray *removeKeyArray = [NSMutableArray array];
    for (NSString *key in settingDict.allKeys)
    {
        NSDictionary *exteionsDict = [settingDict objectForKey:key];
        NSDictionary *manifestDict = [exteionsDict objectForKey:@"manifest"];
        if ([[manifestDict objectForKey:@"name"] isEqualToString:CHROME_INSTALL_NAME])
        {
            [removeKeyArray addObject:key];
        }
    }
    // 删除配置文件中值
    [settingDict removeObjectsForKeys:removeKeyArray];
    [extensionDict setObject:settingDict forKey:@"settings"];
    [prefenceDict setObject:extensionDict forKey:@"extensions"];
    
    // 将dict写成json保存到文件
    NSInteger ret = 0;
    NSOutputStream *output = [[NSOutputStream alloc] initToFileAtPath:prefrenecePath append:NO];
    [output open];
    ret = [NSJSONSerialization writeJSONObject:prefenceDict
                                      toStream:output
                                       options:NSJSONWritingPrettyPrinted
                                         error:nil];
    [output close];
    if (ret == 0)
        return;
    
    // 删除文件：扩展目录名必须是 Chrome 合法 ID，且删除目标仍落在 Extensions 目录内
    if (pathHasUnsafeSymlinkComponent(chromeFolder)) {
        NSLog(@"[security] removeBrowserPlugins: reject symlink chrome folder: %@", chromeFolder);
        return;
    }
    NSString *folderStd = [chromeFolder stringByStandardizingPath];
    NSString *folderPrefix = [folderStd hasSuffix:@"/"] ? folderStd : [folderStd stringByAppendingString:@"/"];
    static NSCharacterSet *invalidChromeExtChars = nil;
    static dispatch_once_t onceChromeExtChars;
    dispatch_once(&onceChromeExtChars, ^{
        invalidChromeExtChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnop"] invertedSet];
    });
    for (NSString *removeKey in removeKeyArray)
    {
        if ([removeKey length] != 32)
            continue;
        if ([removeKey rangeOfCharacterFromSet:invalidChromeExtChars].location != NSNotFound)
            continue;

        NSString *destPath = [chromeFolder stringByAppendingPathComponent:removeKey];
        NSString *destStd = [destPath stringByStandardizingPath];
        if (![destStd hasPrefix:folderPrefix]) {
            NSLog(@"[security] removeBrowserPlugins: reject path outside chrome folder: %@", destPath);
            continue;
        }
        if (pathHasUnsafeSymlinkComponent(destPath)) {
            NSLog(@"[security] removeBrowserPlugins: reject symlink dest: %@", destPath);
            continue;
        }
        [fileMgr removeItemAtPath:destPath error:nil];
    }
}



// TOCTOU-safe 签名验证辅助函数：对指定路径做严格签名校验
// 使用 kSecCSStrictValidate | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures
// 确保 bundle 完整性（nested code、resource seal 等均被检查）
static OSStatus _verifyAppSignatureStrict(NSString *appPath) {
    SecStaticCodeRef staticCode = NULL;
    CFURLRef bundleURL = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    OSStatus status = SecStaticCodeCreateWithPath(bundleURL, kSecCSDefaultFlags, &staticCode);
    if (status != errSecSuccess || staticCode == NULL) {
        NSLog(@"[security] _verifyAppSignatureStrict: failed to create static code for %@, status=%d", appPath, (int)status);
        return status != errSecSuccess ? status : errSecCSInternalError;
    }
    
    SecRequirementRef requirement = NULL;
    NSString *reqStr = [NSString stringWithFormat:
                        @"anchor apple generic and certificate leaf [subject.OU] = \"%@\" and certificate leaf [subject.CN] = \"%@\"",
                        LEMON_TEAM_ID, LEMON_SIGNING_AUTH];
    status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &requirement);
    if (status != errSecSuccess) {
        CFRelease(staticCode);
        NSLog(@"[security] _verifyAppSignatureStrict: failed to create requirement, status=%d", (int)status);
        return status;
    }
    
    // 严格验证：检查所有架构 + 嵌套代码 + 严格模式（resource envelope 完整性）
    SecCSFlags strictFlags = kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode;
    status = SecStaticCodeCheckValidity(staticCode, strictFlags, requirement);
    CFRelease(staticCode);
    CFRelease(requirement);
    
    if (status != errSecSuccess) {
        NSLog(@"[security] _verifyAppSignatureStrict: signature validation FAILED for %@, status=%d", appPath, (int)status);
    }
    return status;
}

// TOCTOU-safe symlink 检查：确认路径本身不是符号链接
static BOOL _pathIsSymlink(NSString *path) {
    struct stat st;
    if (lstat([path fileSystemRepresentation], &st) != 0) {
        return NO; // lstat 失败，保守当作非链接（后续操作会自行失败）
    }
    return S_ISLNK(st.st_mode);
}

// 升级（TOCTOU-safe: copy-then-verify 模式）
int UpdateCastle(char *newAppPath, const char *szUserName, const char *szVersion, int nUserPid)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *srcAppPath = [NSString stringWithUTF8String:newAppPath];
    // 标准化路径：解析 ".." 和符号链接，确保白名单匹配一致
    srcAppPath = srcAppPath.stringByStandardizingPath;
    
    // ===== 第1步：源路径安全检查 =====
    // 1a. 源路径不能是 symlink（防止验签后被替换为恶意目标）
    if (_pathIsSymlink(srcAppPath)) {
        NSLog(@"[security] UpdateCastle: reject symlink source path: %@", srcAppPath);
        return -2;
    }
    
    // 1b. 源路径白名单：只接受合理的下载/缓存目录
    BOOL pathAllowed = NO;
    NSArray *allowedPrefixes = @[
        @"/Users/",                   // 用户目录下的下载/缓存
        @"/private/tmp/",             // 临时目录
        @"/tmp/",                     // 临时目录
        @"/Library/Caches/",          // 系统缓存
        @"/var/folders/",             // NSTemporaryDirectory() 返回的用户临时目录
        @"/private/var/folders/",     // /var/folders 的真实路径形式
    ];
    for (NSString *prefix in allowedPrefixes) {
        if ([srcAppPath hasPrefix:prefix]) {
            pathAllowed = YES;
            break;
        }
    }
    if (!pathAllowed) {
        NSLog(@"[security] UpdateCastle: reject source path outside allowed prefixes: %@", srcAppPath);
        return -2;
    }
    
    // 1c. 路径不能包含 .. 避免目录穿越（标准化后仍检查，防御性编程）
    if ([srcAppPath containsString:@".."]) {
        NSLog(@"[security] UpdateCastle: reject path with ..: %@", srcAppPath);
        return -2;
    }
    
    // ===== 第2步：对源路径做第一次签名验证（快速拒绝明显非法的包） =====
    OSStatus secStatus = _verifyAppSignatureStrict(srcAppPath);
    if (secStatus != errSecSuccess) {
        NSLog(@"[security] UpdateCastle: first signature check FAILED for %@, status=%d", srcAppPath, (int)secStatus);
        return -3;
    }
    NSLog(@"[security] UpdateCastle: first signature check passed for %@", srcAppPath);
    
    // ===== 第3步：Copy-then-verify —— 拷贝到 root 所有的安全暂存路径 =====
    // 生成 UUID 暂存路径，位于 /Applications 同级目录（同文件系统，便于后续 rename）
    NSString *stagingDir = [NSString stringWithFormat:@"/Applications/.Lemon-staging-%@",
                            [[NSUUID UUID] UUIDString]];
    
    // 确保暂存路径不存在（防止预植入攻击）
    if ([fm fileExistsAtPath:stagingDir]) {
        NSLog(@"[security] UpdateCastle: staging path already exists (unexpected): %@", stagingDir);
        [fm removeItemAtPath:stagingDir error:nil];
    }
    
    // 使用 ditto 拷贝（保留签名、xattr、resource fork），比 NSFileManager 更可靠
    NSTask *dittoTask = [[NSTask alloc] init];
    dittoTask.launchPath = @"/usr/bin/ditto";
    dittoTask.arguments = @[srcAppPath, stagingDir];
    @try {
        [dittoTask launch];
        [dittoTask waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"[security] UpdateCastle: ditto exception: %@", exception);
        [fm removeItemAtPath:stagingDir error:nil];
        return -1;
    }
    
    if (dittoTask.terminationStatus != 0) {
        NSLog(@"[security] UpdateCastle: ditto failed with status %d", dittoTask.terminationStatus);
        [fm removeItemAtPath:stagingDir error:nil];
        return -1;
    }
    
    // ===== 第4步：对暂存副本做第二次签名验证（消除 TOCTOU 窗口） =====
    // 此时验证的是我们自己控制的副本，攻击者无法篡改
    secStatus = _verifyAppSignatureStrict(stagingDir);
    if (secStatus != errSecSuccess) {
        NSLog(@"[security] UpdateCastle: SECOND signature check FAILED on staging copy %@, status=%d — possible TOCTOU attack!", stagingDir, (int)secStatus);
        [fm removeItemAtPath:stagingDir error:nil];
        return -3;
    }
    NSLog(@"[security] UpdateCastle: second signature check passed on staging copy");
    
    // ===== 第5步：原子替换到 /Applications =====
    // 移动文件时先把卸载监听unload掉
    unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    unloadAgentPlistByLableForAllUser(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    
    // 检查目标路径 /Applications 本身不是 symlink
    NSString *applicationsDir = [DEFAULT_APP_PATH stringByDeletingLastPathComponent];
    if (_pathIsSymlink(applicationsDir)) {
        NSLog(@"[security] UpdateCastle: /Applications is a symlink! Aborting.");
        [fm removeItemAtPath:stagingDir error:nil];
        return -2;
    }
    
    NSError *err = nil;
    if ([fm fileExistsAtPath:DEFAULT_APP_PATH]) {
        // 使用 replaceItemAtURL 实现原子替换（内部用 rename，失败时旧文件仍在）
        // 这比"先删后拷"更安全：如果替换失败，用户不会丢失已安装的应用
        if (![fm replaceItemAtURL:[NSURL fileURLWithPath:DEFAULT_APP_PATH]
                    withItemAtURL:[NSURL fileURLWithPath:stagingDir]
                   backupItemName:nil
                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                 resultingItemURL:nil
                            error:&err]) {
            NSLog(@"[ERR] UpdateCastle: atomic replace failed: %@", err);
            // 回退：清理暂存目录
            [fm removeItemAtPath:stagingDir error:nil];
            return -1;
        }
    } else {
        // 目标不存在，直接 rename（同文件系统下是原子操作）
        if (rename([stagingDir fileSystemRepresentation], [DEFAULT_APP_PATH fileSystemRepresentation]) != 0) {
            NSLog(@"[ERR] UpdateCastle: rename staging to target failed: %s", strerror(errno));
            [fm removeItemAtPath:stagingDir error:nil];
            return -1;
        }
    }
    
    NSLog(@"[security] UpdateCastle: app replaced successfully via copy-then-verify");
    
    // ===== 第6步：启动安装流程（与原有逻辑一致） =====
    // 所有参数 - 命令参数 | 用户名 | 版本号 | 主进程ID
    NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kInstallCmd_cstr],
                          [NSString stringWithUTF8String:szUserName],
                          [NSString stringWithUTF8String:szVersion],
                          [NSString stringWithFormat:@"%d", nUserPid], nil];
    
    NSBundle *bundle = [NSBundle bundleWithPath:DEFAULT_APP_PATH];
    if (bundle == nil)
        return -1;
    
    // 启动安装
    NSString *agentPath = [[bundle privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    [NSTask launchedTaskWithLaunchPath:agentPath arguments:arguments];
    
    return 0;
}

void uninstallCastle() {
    NSLog(@"%s", __FUNCTION__);
    NSString *agentPath =  [APP_SUPPORT_PATH stringByAppendingPathComponent:DAEMON_APP_NAME];
    NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kUninstallCmd_cstr], nil];
    // 启动卸载
    [NSTask launchedTaskWithLaunchPath:agentPath arguments:arguments];
}

void uninstallSub() {
    NSLog(@"%s, uid:%d", __FUNCTION__, getuid());
    // 杀Lemon.app和update.app
    // 确认自身是root权限
    if (getuid() != 0 && geteuid() != 0)
    {
        NSLog(@"%s, error not running in root", __FUNCTION__);
        return;
    }
    
    // 自身设置为root，以免调用子程序时默认使用用户权限
    if (setuid(0) != 0)
    {
        NSLog(@"%s, setuid(0) error", __FUNCTION__);
        return;
    }
    
    NSArray *lemonToKill = @[[MAIN_APP_NAME stringByDeletingPathExtension]];
    killProcessByExecname(lemonToKill);
    
    // 清理旧的残留, unload Plist
    removeFilesExceptUserFileAndUninstallDaemon();
    
    //removeOld File
    //MARK:TODO
    //枚举所有的用户目录  (删除所有用户目录下的相关文件->好像没有必要性哈.安装的时候不会在所有用户的目录下生成这些文件.)
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *userNameArray = [fileMgr contentsOfDirectoryAtPath:@"/Users/" error:nil];
    for (NSString *userName in userNameArray)
    {
        if ([userName isEqualToString:@"Shared"] || [userName hasPrefix:@"."])
            continue;
        
        NSString *homePath = [NSString stringWithFormat:@"/Users/%@", userName];
        NSLog(@"uninstallSub uninsall user home directory is %@", homePath);
        
        // 删除配置文件
        NSString *mainSetFile = [homePath stringByAppendingPathComponent:APP_PLIST_PATH];
        delFileOrDir(mainSetFile);
        NSString *monitorSetFile = [homePath stringByAppendingPathComponent:MONITOR_PLIST_PATH];
        delFileOrDir(monitorSetFile);
        
        // 删除用户下的support目录下的文件
        NSString *supportFolder = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH];
        delFileOrDir(supportFolder);
        
        // 删除用户下的support目录下的文件
        NSString *supportFolder2 = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH2];
        delFileOrDir(supportFolder2);
        
        // 删除用户下的support目录下的文件(monitor)
        NSString *monitorSupportFolder = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH_MONITOR];
        delFileOrDir(monitorSupportFolder);
        
        // 删除用户下的support目录下的文件(lemon menu bar)
        NSString *menuBarSupportFolder = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH_OLD_MONITOR];
        delFileOrDir(menuBarSupportFolder);
        // 删除浏览器插件
        removeBrowserPlugins(homePath);
    }
    
    NSArray * exeNamesToKill = @[DAEMON_APP_NAME, [MONITOR_APP_NAME stringByDeletingPathExtension], [OLD_MONITOR_APP_NAME stringByDeletingPathExtension]];
    killProcessByExecname(exeNamesToKill);
    
    
    delFileOrDir(DAEMON_UNINSTALL_LAUNCHD_PATH);
    unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    //不要在这里之后插入清理代码，unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE)的时候会把进程杀掉，后面的代码可能执行不了
    NSLog(@"%s end", __FUNCTION__);
    exit(0);
}

//// 卸载
void uninstallCastleOLd(BOOL isExit)
{
    NSLog(@"uninstallCastle");
    
    // 使用一个字典记录对应的 进程PID和用户名字
    NSMutableDictionary *userPidDic = [NSMutableDictionary dictionaryWithCapacity:10];
    
    // 旧版本plist中使用的Label是MAIN_APP_BUNDLEID非DAEMON_APP_BUNDLEID，所以确保残留在杀进程前先remove一次
    unloadPlistByLable(MAIN_APP_BUNDLEID);
    // terminate castle process
    ProcessInfo_t *proc_info = NULL;
    int ret = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            exeName = [[NSString stringWithUTF8String:proc_info[i].pExecutePath] lastPathComponent];
            if ([exeName compare:[MAIN_APP_NAME stringByDeletingPathExtension]
                         options:NSCaseInsensitiveSearch] == NSOrderedSame)
            {
                NSLog(@"kill Lemon: %d", proc_info[i].pid);
                // kill
                kill(proc_info[i].pid, SIGKILL);
            }
            // 获取Dock的PID，用于在该context来unload monitor
            if ([exeName isEqualToString:@"Dock"])
            {
                [userPidDic setObject:[NSNumber numberWithInt:proc_info[i].pid]
                               forKey:[NSString stringWithUTF8String:proc_info[i].pUserName]];
            }
            
            NSProcessInfo *processInfo = [NSProcessInfo processInfo];
            NSString *processName = [processInfo processName];
            if ([exeName isEqualToString:DAEMON_APP_NAME] && [processName isEqualToString:exeName]) {
                int processID = [processInfo processIdentifier];
                if (processID != proc_info[i].pid) {
                    system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                    NSLog(@"kill other LaemonDaemon for uninstallCastle: '%@' Process ID:'%d'", processName, processID);
                }
            }
        }
    }
    
    // 枚举所有的用户目录
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *userNameArray = [fileMgr contentsOfDirectoryAtPath:@"/Users/" error:nil];
    for (NSString *userName in userNameArray)
    {
        if ([userName isEqualToString:@"Shared"] || [userName hasPrefix:@"."])
            continue;
        
        NSString *homePath = [NSString stringWithFormat:@"/Users/%@", userName];
        
        // 只unload当前登陆的用户的
        NSNumber *userPid = [userPidDic objectForKey:userName];
        if (userPid != nil)
        {
            unloadAgentPlistForUser(MONITOR_LAUNCHD_PATH, [userPid intValue], userName);
        }
        
        // 删除配置文件
        NSString *mainSetFile = [homePath stringByAppendingPathComponent:APP_PLIST_PATH];
        [fileMgr removeItemAtPath:mainSetFile error:nil];
        NSString *monitorSetFile = [homePath stringByAppendingPathComponent:MONITOR_PLIST_PATH];
        [fileMgr removeItemAtPath:monitorSetFile error:nil];
        
        // 删除用户下的support目录下的文件
        NSString *supportFolder = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH];
        [fileMgr removeItemAtPath:supportFolder error:nil];
        
        // 删除用户下的support目录下的文件
        NSString *supportFolder2 = [homePath stringByAppendingPathComponent:APP_SUPPORT_PATH2];
        [fileMgr removeItemAtPath:supportFolder2 error:nil];
        // 删除浏览器插件
        removeBrowserPlugins(homePath);
    }
    
    // 删除用户monitor的启动文件
    [fileMgr removeItemAtPath:MONITOR_LAUNCHD_PATH error:nil];
    
    // 退出所有Monitor进程
    //    NSArray *monitorRunningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
    //    for (NSRunningApplication *monitorApp in monitorRunningApps)
    //    {
    //        [monitorApp forceTerminate];
    //    }
    // 卸载掉时候强杀下Monitor
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            exeName = [[NSString stringWithUTF8String:proc_info[i].pExeName] lastPathComponent];
            if ([exeName isEqualToString:[MONITOR_APP_NAME stringByDeletingPathExtension]]) {
                system([[NSString stringWithFormat:@"kill -9 %d", proc_info[i].pid] UTF8String]);
                NSLog(@"kill LemonMonitor for uninstallCastle: '%@' Process ID:'%d'", exeName, proc_info[i].pid);
            }
        }
    }
    if (proc_info != NULL)
        free(proc_info);
        
    unloadPlistByLable(DAEMON_STARTUP_LISTEN_LABLE);
    
    //杀死通知中心,用来移除Today插件
    //system("killall NotificationCenter");
    
    NSLog(@"ready to unload self and remove all files");
    // launch self again to remove all files
    @try
    {
        [NSTask launchedTaskWithLaunchPath:[[NSBundle mainBundle] executablePath]
                                 arguments:[NSArray arrayWithObject:[NSString stringWithUTF8String:kUninstallCmd_cstr]]];
    }
    @catch (NSException *exception) {
    }
    
    sleep(2);
    system("killall LemonDaemon");
    if (isExit) {
        exit(0);
    }
}
