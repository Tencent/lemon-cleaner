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
#import "LMPlistHelper.h"


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


void reloadListenPlist() {
    unloadPlistByLable(DAEMON_STARTUP_LISTEN_LABLE);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH]) {
        [fileMgr removeItemAtPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil];
    }
    
    NSString *srcPath = [DEFAULT_APP_PATH stringByAppendingPathComponent:@"Contents/Frameworks"];
    srcPath = [srcPath stringByAppendingPathComponent:[DAEMON_STARTUP_LISTEN_LAUNCHD_PATH lastPathComponent]];
    
    if (![fileMgr copyItemAtPath:srcPath toPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil]) {
        NSLog(@"%s, move file %@ to %@ error", __FUNCTION__, srcPath, DAEMON_STARTUP_LISTEN_LAUNCHD_PATH);
        return;
    }
    NSDictionary *rootAttr = @{NSFileOwnerAccountName:@"root",NSFileGroupOwnerAccountName:@"admin"};
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil];
    loadPlist(DAEMON_STARTUP_LISTEN_LAUNCHD_PATH);
}

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
            if (exeName.length > 0)
            {
                NSString *commandString = [@"killall " stringByAppendingString:exeName];
                system([commandString UTF8String]);
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
    
    //    NSString *loadCmd = [NSString stringWithFormat:@"launchctl load -w %@", DAEMON_LAUNCHD_PATH];
    //    system([loadCmd UTF8String]);
    
    // 拷贝startup launchd配置文件
    NSString *listenLaunchSrcPath = [selfFolder stringByAppendingPathComponent:[DAEMON_STARTUP_LISTEN_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:listenLaunchSrcPath toPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil]) {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_STARTUP_LISTEN_LAUNCHD_PATH error:nil];
    loadPlist(DAEMON_STARTUP_LISTEN_LAUNCHD_PATH);
    
    // 拷贝自身uninstall launchd配置文件
    NSString *uninsatllLaunchSrcPath = [selfFolder stringByAppendingPathComponent:[DAEMON_UNINSTALL_LAUNCHD_PATH lastPathComponent]];
    [fileMgr removeItemAtPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil];
    if (![fileMgr copyItemAtPath:uninsatllLaunchSrcPath toPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil]) {
        return QMINST_ERR_COPYPLIST;
    }
    [fileMgr setAttributes:rootAttr ofItemAtPath:DAEMON_UNINSTALL_LAUNCHD_PATH error:nil];
    loadPlist(DAEMON_UNINSTALL_LAUNCHD_PATH);
    
    
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
    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl unload %@", DAEMON_LAUNCHD_PATH];
    system([unloadCmd UTF8String]);
    // 旧版本plist中使用的Label是MAIN_APP_BUNDLEID非DAEMON_APP_BUNDLEID，所以确保残留在杀进程前先remove一次
    NSString *removeCmd = [NSString stringWithFormat:@"launchctl remove %@", MAIN_APP_BUNDLEID];
    system([removeCmd UTF8String]);
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
    
    NSString *loadCmd = [NSString stringWithFormat:@"launchctl load -w %@", DAEMON_LAUNCHD_PATH];
    system([loadCmd UTF8String]);
    
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
        
        unloadCmd = [NSString stringWithFormat:@"launchctl unload %@", MONITOR_LAUNCHD_PATH];
        system([unloadCmd UTF8String]);
        system("killall Lemon\ Menu\ bar");
        //        loadCmd = [NSString stringWithFormat:@"launchctl load -w %@", MONITOR_LAUNCHD_PATH];
        //        system([loadCmd UTF8String]);
    }
    else
    {
        // 直接root权限拉起的更新过程
        NSString *unloadCmd = [NSString stringWithFormat:@"launchctl bsexec %d su %s -c 'launchctl unload %@'",
                               nUserPid, szUserName, MONITOR_LAUNCHD_PATH];
        system([unloadCmd UTF8String]);
        //killall命令有时候无法正常kill进程，废弃，使用kill -9来执行
        system("killall Lemon\ Menu\ bar");
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
    
    // 删除文件
    for (NSString *removeKey in removeKeyArray)
    {
        if ([removeKey length] == 0)
            continue;
        
        NSString *destPath = [chromeFolder stringByAppendingPathComponent:removeKey];
        [fileMgr removeItemAtPath:destPath error:nil];
    }
}



// 升级
int UpdateCastle(char *newAppPath, const char *szUserName, const char *szVersion, int nUserPid)
{
    // 移动文件时先把卸载监听unload掉
    unloadPlistByLable(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    unloadAgentPlistByLableForAllUser(DAEMON_UNINSTALL_LAUNCHD_LABLE);
    if (fileMoveTo(newAppPath, (char *)[DEFAULT_APP_PATH UTF8String], MCCMD_MOVEFILE_MOVE) == -1)
    {
        NSLog(@"Update fail when replacing APP file");
        return -1;
    }
    
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
    NSString *removeCmd = [NSString stringWithFormat:@"launchctl remove %@", MAIN_APP_BUNDLEID];
    system([removeCmd UTF8String]);
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
            NSString *unloadCmd = [NSString stringWithFormat:@"launchctl bsexec %@ su %@ -c 'launchctl unload %@'",
                                   userPid, userName, MONITOR_LAUNCHD_PATH];
            //NSLog(@"unload cmd: %@", unloadCmd);
            system([unloadCmd UTF8String]);
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
