//
//  QMDataConst.h
//  Lemon
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ProgressViewTypeSys = 0,
    ProgressViewTypeApp,
    ProgressViewTypeInt,
}ProgressViewType;

#ifndef QQMacMgr_QMDataConst_h
#define QQMacMgr_QMDataConst_h

#define kHeaderFont                 @"FZLTXHJW--GB1-0"
#define kHeaderColor                [NSColor colorWithHex:0x616c72]
#define kHeaderDetailColor          [NSColor colorWithHex:0x85949c]

#pragma mark - PublicKey

#pragma mark - 本地存储的Key

// 主程序
#define kQMMainFirstRun             @"QMMainFirstRun"           //第一次运行后，设置为 NO
#define kQMMainLaunchTime           @"QMMainLaunchTime"         //主程序启动时间
#define kQMMainExitTime             @"QMMainExitTime"           //主程序退出时间

// 清理模块
#define kQMCleanerKeepLanguages            @"QMCleanerKeepLanguages"        //保留的语言
#define kQMCleanerDefaultKeepLanguages     @"QMCleanerDefaultKeepLanguages"
#define kQMLastCleanTime                   @"QMLastCleanTime"               //上次清理时间
#define kQMMothCleanSize                   @"QMMothCleanSize"               //每天的清理情况

// 上次清理的大小B
#define kQMLastCleanSize            @"QMLastCleanSize"
// 总共清理的大小
#define kQMTotalCleanSize           @"QMTotalCleanSize"
// 清理用户勾选
#define kQMCleanItemCheck           @"CleanItemCheck"

// 浮窗模块
#define kQMMonitorFirstRun          @"QMMonitorFirstRun"        //第一次运行后,设置为 NO
#define kQMMonitorLaunchTime        @"QMMonitorLaunchTime"      //浮窗的启动时间
#define kQMMonitorExitTime          @"QMMonitorExitTime"        //浮窗的退出时间
#define kQMMonitorShowMode          @"QMMonitorShowMode"        //Monitor显示模式(浮窗/状态栏)
#define kQMMonitorClosed            @"monitorHidden"            //Moniter是否关闭
#define kQMMonitorEarlyWarning      @"QMMonitorEarlyWarning"    //预警的显示版本号

// 软件升级
#define kLemonNewVersion            @"kLemonHasVersion"         //新版通知、新版存储到Key
#define kIgnoreLemonNewVersion      @"kIgnoreLemonNewVersion"   //是否忽略制定版本
#define kBeginInstallLemonApp       @"kBeginInstallLemonApp"    //开始弹出升级检测/安装界面
#define kLemonNewVersionInfo        @"kLemonNewVersionInfo"

// 改变显示的view
#define kLemonChangeDisplayViewNotification   @"QMChangeDisplayViewNotification"

#define kHomeView       0
#define kCleanView      1
#define kSoftView       2
#define kHardwareView   3
#define kToolBoxView    4
#define kStartScanView  5


#define kQMOfficialWebsite          @"https://lemon.qq.com"
#define kQMPrivacyLicenseLink       @"https://docs.qq.com/doc/p/14c9c888a06a856dd3945a4ed50a1f22be92020f?dver=2.1.27135941&pub=1&u=213b091f14ba4c878602e45174f03ad9"
#define kQMServiceLicenseLink       @"https://docs.qq.com/doc/p/2f38b736932904b5dc268ec3e1400dc750511da0"

#endif
