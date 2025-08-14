//
//  main.m
//  LemonMonitor
//
//  Created by tanhao on 14-7-1.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "LemonMonitroHelpParams.h"
#import "LemonDaemonConst.h"
#import "LMTrashCheckManager.h"
#import "LMUtilFunc.h"

CFAbsoluteTime g_startTime = 0;

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
            [[LMTrashCheckManager manager].task schedule];
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


