//
//  main.m
//  Lemon
//

//  Copyright © 2018  Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifndef APPSTORE_VERSION
#import "LemonStartUpParams.h"
#import "LemonDaemonConst.h"
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <QMCoreFunction/LanguageHelper.h>
#endif
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    NSLog(@"Lemon main: %d", argc);
    
#ifndef APPSTORE_VERSION
    NSString *language = [LanguageHelper getCurrentUserLanguage];
    if(language != nil){
        //hook 主工程多语言
        [NSBundle setLanguage:language bundle:[NSBundle mainBundle]];
    }
    if (argc == 2) {
        NSLog(@"Lemon main1: %@", [NSString stringWithUTF8String:argv[1]]);
        
        if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:@"1"]) {
            [[LemonStartUpParams sharedInstance] setParamsCmd:1];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:@"2"])
        {
            [[LemonStartUpParams sharedInstance] setParamsCmd:2];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:@"1030"]) /// monitor打开磁盘空间分析
        {
            [[LemonStartUpParams sharedInstance] setParamsCmd:1030];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", (unsigned long)LemonAppRunningReInstallAndMonitorExist]])
        {
            [[LemonStartUpParams sharedInstance] setParamsCmd:LemonAppRunningReInstallAndMonitorExist];
        }
        else if ([[NSString stringWithUTF8String:argv[1]] isEqualToString:[NSString stringWithFormat:@"%lu", (unsigned long)LemonAppRunningReInstallAndMonitorNotExist]])
        {
            [[LemonStartUpParams sharedInstance] setParamsCmd:LemonAppRunningReInstallAndMonitorNotExist];
        }
    }
#endif

    return NSApplicationMain(argc, argv);
}

