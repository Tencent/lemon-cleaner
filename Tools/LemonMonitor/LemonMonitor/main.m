//
//  main.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "LemonMonitroHelpParams.h"
#import "LemonDaemonConst.h"
#import "TrashCheckMonitor.h"
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>

CFAbsoluteTime g_startTime = 0;

void redirctNSlog()
{
    NSLog(@"redirctNSlog ...");
    NSString *logPath;
    NSString *logName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
    
    // do not redirect in test mode
    //if ([[[NSBundle mainBundle] executablePath] containsString:@"/Library"])
    //    return;
    
    NSString *rootLogPath = [NSString stringWithFormat:@"/Library/Logs/%@", logName];
    rootLogPath = [rootLogPath stringByAppendingPathExtension:@"log"];
    
    if (getuid() == 0)
    {
        // root
        logPath = rootLogPath;
    }
    else
    {
        // user
        logPath = [NSHomeDirectory() stringByAppendingPathComponent:rootLogPath];
    }
    
    // clean log file
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:logPath]) {
        [fileMgr createFileAtPath:logPath contents:[NSData data] attributes:nil];
    }
    
    id handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    
    NSDictionary *fileAttributes = [fileMgr attributesOfItemAtPath:logPath error:nil];
    BOOL isLeastSevenDays = NO;
    if (fileAttributes) {
        NSDate *date = [fileAttributes objectForKey:NSFileCreationDate];
        NSTimeInterval createTimeInterval = [date timeIntervalSince1970];
        NSTimeInterval todayTimeInterval = [[NSDate date] timeIntervalSince1970];
        if ((todayTimeInterval - createTimeInterval) <= 7 * 24 * 3600) {
            isLeastSevenDays = YES;
        }else{
            [fileMgr createFileAtPath:logPath contents:[NSData data] attributes:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        }
    }
    if (isLeastSevenDays) {
        [handle seekToEndOfFile];
    }
    
    if (handle != nil)
    {
        dup2([handle fileDescriptor], STDERR_FILENO);
    }
}

BOOL isAppRunningBundleId(NSString *bundelId){
    NSArray *runnings= [NSRunningApplication runningApplicationsWithBundleIdentifier:bundelId];
    NSLog(@"[TrashDel, running%@:%@", bundelId, runnings);
    return [runnings count] > 0;
}

Boolean trashCheck(){
    //每次废纸篓变化都需要更新保存的APP记录
    TrashCheckMonitor *trashCheck = [[TrashCheckMonitor alloc] init];
    NSArray *appTrashItems  = [trashCheck getNewTashApps];
    
    BOOL isTrashWatchEnable = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH];
    if(!isTrashWatchEnable){
        NSLog(@"%s, trash watch app disable", __FUNCTION__);
        return false;
    }
    NSLog(@"%s appTrashItems is \n %@", __FUNCTION__,  [appTrashItems componentsJoinedByString:@",  "]);
    
    if ([appTrashItems count] > 0) {
        NSLog(@"[TrashDel__trashCheck_from Monitor] postnotification: changed apps: %@", [appTrashItems componentsJoinedByString:@","]);
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        [info setObject:appTrashItems forKey:@"items"];
        [info setObject:@"this notify is from moniotor" forKey:@"from"];
        
        if (isAppRunningBundleId(MONITOR_APP_BUNDLEID)) {
            NSLog(@"[TrashDel], post to monitor trashItem:%@", appTrashItems);
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRASH_CHANGE_TO_MONITOR
                                                                           object:nil
                                                                         userInfo:info
                                                                          options:NSNotificationPostToAllSessions | NSDistributedNotificationDeliverImmediately];
        }
        return true;
    }else{
        NSLog(@" %s can't get new apps", kTrashChanged_cstr);
        return false;
    }
    // sleep 100ms,保证日志写完.
    usleep(100 *1000);
}

void trashSizeCheck(){
    NSLog(@"%s, trash size check", __FUNCTION__);
    //如果是从废纸篓中放回原处，也会触发该方法，需要过滤掉场景
    //如果没有开启，也需要更新废纸篓中的数量
    TrashCheckMonitor *trashCheck = [[TrashCheckMonitor alloc] init];
    if(![trashCheck isTrashItemsChanged]){
        NSLog(@"%s, trash size not changed", __FUNCTION__);
        return;
    };
    
    Boolean isTrashWatchHasSet = false;
    NSInteger watchStatus = 0;
    //是否开启
    BOOL isTrashSizeWatchEnable = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)(IS_ENABLE_TRASH_SIZE_WATCH), (__bridge CFStringRef)(MAIN_APP_BUNDLEID), &isTrashWatchHasSet);
    if(!isTrashWatchHasSet){
        isTrashSizeWatchEnable = YES;
        watchStatus = V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE;
        NSLog(@"%s, trash size check not set", __FUNCTION__);
    }
    
    if(!isTrashSizeWatchEnable){
        NSLog(@"%s, trash size check disabled", __FUNCTION__);
        return;
    }
    
    if(watchStatus == 0){
        watchStatus = CFPreferencesGetAppIntegerValue((__bridge CFStringRef)(K_TRASH_SIZE_WATCH_STATUS), (__bridge CFStringRef)(MAIN_APP_BUNDLEID), &isTrashWatchHasSet);
        if(!isTrashWatchHasSet){
            watchStatus = V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE;
        }
    }
    
    
    NSInteger thresholdSize = 1024;    //默认阈值为1G
    Boolean isThresholdSizeHasSet;
    if(watchStatus == V_TRASH_SIZE_WATCH_WHEN_DELETE_FILE){
        thresholdSize = 0;
    }else{
        thresholdSize = CFPreferencesGetAppIntegerValue((__bridge CFStringRef)TRASH_SIZE_WATCH_THRESHOLD, (__bridge CFStringRef)(MAIN_APP_BUNDLEID), &isThresholdSizeHasSet);
        if(!isThresholdSizeHasSet){
            NSLog(@"trash watch size not set, set default value 1G");
            thresholdSize = 1024;
        }
            
    }
    NSLog(@"%s, thresholdSize value is: %ld" , __FUNCTION__, (long)thresholdSize);
//    thresholdSize = thresholdSize == 0 ? 20 : thresholdSize;
    NSString *path = [@"~/.trash" stringByExpandingTildeInPath];
    NSString *cmd = [NSString stringWithFormat:@"du -sk %@", path];
    NSString *result = [QMShellExcuteHelper excuteCmd:cmd];
    NSString *subString = @"";
    NSRange range = [result rangeOfString:@"\t"];
    BOOL resultStatus = NO;
    if(range.location != NSNotFound){
        subString = [result substringToIndex:range.location];
        NSLog(@"%s,result: %@, subString : %@", __FUNCTION__, result,subString);
        if(subString && ![subString isEqualToString:@""])
            resultStatus = YES;
    }
    float actualSize = 0;
    //如果通过命令没有获取到大小，则遍历文件获取
    if(resultStatus){
        actualSize = [subString floatValue];
        actualSize = actualSize * 1024; //拿到是KB，换算成byte
    }else{
        NSLog(@"%s, cannot get size by cmd!", __FUNCTION__);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        actualSize = [fileManager fileSizeAtPath:path];
    }
    
    NSLog(@"%s, trash size: %ld", __FUNCTION__, (long)actualSize);
    NSLog(@"%s, thresholdSize : %ld", __FUNCTION__, (long)thresholdSize);
    
    if(actualSize >= thresholdSize * 1024 * 1024){
        NSLog(@"%s, size is over threshold !!!",__FUNCTION__);
        
       if (isAppRunningBundleId(MONITOR_APP_BUNDLEID)) {
           NSLog(@"%s, notifiction to watch size !!!",__FUNCTION__);
           NSMutableDictionary *info = [[NSMutableDictionary alloc]init];
           [info setObject:@(actualSize) forKey:@"trashSize"];
           [[NSDistributedNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TRASH_SIZE_OVER_THRESHOLD object:nil userInfo:info options:NSNotificationPostToAllSessions | NSDistributedNotificationDeliverImmediately];
       }
    }
    // sleep 100ms,保证日志写完.
    usleep(100 *1000);

}


int main(int argc, const char * argv[])
{
//    trashSizeCheck();
#ifndef DEBUG
    redirctNSlog();
#endif
    // 记录启动时间
    g_startTime = CFAbsoluteTimeGetCurrent();
    
#ifdef DEBUG
    return NSApplicationMain(argc, argv);
#endif
    
    
    // command line
    for (int i=0; i<argc; i++)
    {
        NSLog(@"\n\n\n\n"); // 分隔之前的日志
        NSLog(@"LemonMonitor main: argc=%d;argv[%d]=%@", argc, i, [NSString stringWithUTF8String:argv[i]]);
    }
    
    //
    if (argc==2)
    {
        if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonAppRunningNormal]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonAppRunningNormal];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonAppRunningFirstInstall]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonAppRunningFirstInstall];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonAppRunningReInstallAndMonitorExist]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonAppRunningReInstallAndMonitorExist];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonAppRunningReInstallAndMonitorNotExist]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonAppRunningReInstallAndMonitorNotExist];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonMonitorRunningOSBoot]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonMonitorRunningOSBoot];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", LemonMonitorRunningMenu]])
        {
            [[LemonMonitroHelpParams sharedInstance] setStartParamsCmd:LemonMonitorRunningMenu];
        }
        else if(strcmp(argv[1], kTrashChanged_cstr) == 0){
            NSLog(@"LemonMonitor main received notify for trash changed....");
            trashCheck();
            trashSizeCheck();
            //如果删除的应用，只弹出卸载残留提示；
            // Boolean appCheck = trashCheck();
//            if(!appCheck){
//                NSLog(@"appcheck is false");
//                trashSizeCheck();
//            }
            
            return 0;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
    
    return NSApplicationMain(argc, argv);
}


