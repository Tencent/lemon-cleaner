//
//  LemonDaemonConst.h
//  LemonDaemon
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#ifndef LemonDaemon_QMAgentConst_h
#define LemonDaemon_QMAgentConst_h

#define kInstallFinishNotify    @"InstallFinishNotify"

//Agent启动的任务
#define kLoadCmd_cstr           "loadBySystem"
#define kInstallCmd_cstr        "InstallLemon"
#define kReplaceInstallCmd_cstr "ReplaceInstallLemon"
#define kUninstallCmd_cstr      "UninstallLemon"
#define kTrashChanged_cstr      "trashChanged"
#define kStartupDaemon_cstr     "startup"
#define kCopySelfToApplication  "copySelfToApplication"
#define kReloadListenPlist      "reloadListenPlist"

//APP的BundleID
#define MAIN_APP_BUNDLEID       @"com.tencent.Lemon"
#define MONITOR_APP_BUNDLEID    @"com.tencent.LemonMonitor"
#define DAEMON_APP_BUNDLEID     @"com.tencent.LemonDaemon"

//APP的文件名
#define MAIN_APP_NAME           @"Tencent Lemon.app"
#define MONITOR_APP_NAME        @"LemonMonitor.app"
#define DAEMON_APP_NAME         @"LemonDaemon"
#define UPDATE_APP_NAME         @"LemonUpdate.app"

//路径相关
//#define DEFAULT_APP_PATH        @"/Users/torsysmeng/Library/Developer/Xcode/DerivedData/Lemon-gmfqyfrusrvxopduwpphgyjaxeqx/Build/Products/Release/Lemon.app"
#define DEFAULT_APP_PATH        @"/Applications/Tencent Lemon.app"
#define MONITOR_SRC_APP_PATH    @"/Applications/Tencent Lemon.app/Contents/Frameworks/LemonMonitor.app"
#define MONITOR_APP_PATH        @"/Library/Application Support/Lemon/LemonMonitor.app"

#define DAEMON_ACTIVATOR_CMD   @"/Applications/Tencent\\ Lemon.app/Contents/Frameworks/LemonDaemonActivator"

//使用相对路径，因为该宏会在多个程序中使用，比如主的Lemon.app和LemonMonitor.app中就会有不同的值，所以要使用相对路径，就需要在各自的工程中另外定义
//#define MONITOR_APP_PATH        [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MONITOR_APP_NAME]

#define APP_SUPPORT_PATH                        @"/Library/Application Support/Lemon"
#define APP_SUPPORT_PATH2                       @"/Library/Application Support/com.tencent.Lemon"
#define DAEMON_LAUNCHD_PATH                     @"/Library/LaunchDaemons/com.tencent.Lemon.plist"
#define MONITOR_LAUNCHD_PATH                    @"/Library/LaunchAgents/com.tencent.LemonMonitor.plist"
#define TRASH_MONITOR_LAUNCHD_PATH              @"/Library/LaunchAgents/com.tencent.Lemon.trash.plist"

#define TRASH_MONITOR_LAUNCHD_PATH_OLD          @"/Library/LaunchDaemons/com.tencent.Lemon.trash.plist"
#define DAEMON_STARTUP_LISTEN_LAUNCHD_PATH      @"/Library/LaunchDaemons/com.tencent.Lemon.listen.plist"
#define DAEMON_UNINSTALL_LAUNCHD_PATH           @"/Library/LaunchDaemons/com.tencent.Lemon.uninstall.plist"

#define DAEMON_LAUNCHD_LABLE            @"com.tencent.LemonDaemon"
#define OLD_DAEMON_LAUNCHD_LABLE        @"com.tencent.Lemon"
#define MONITOR_LAUNCHD_LABLE           @"com.tencent.LemonMonitor"
#define TRASH_MONITOR_LAUNCHD_LABLE     @"com.tencent.Lemon.trash"

#define DAEMON_STARTUP_LISTEN_LABLE     @"com.tencent.Lemon.listen"
#define DAEMON_UNINSTALL_LAUNCHD_LABLE  @"com.tencent.Lemon.uninstall"

//配置文件
#define APP_PLIST_PATH          @"/Library/Preferences/com.tencent.Lemon.plist"
#define MONITOR_PLIST_PATH      @"/Library/Preferences/com.tencent.LemonMonitor.plist"

//其它文件名字
#define INST_VERSION_NAME       @"Version.log"
#define APP_DATA_NAME           @"Data"
#define TOOLS_INSTALL_DIR       @"Tools"

// 浏览器插件目录，都是在 home 目录下
#define FIREFOX_PLUGIN_PATH     @"/Library/Application Support/Mozilla/Extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/QQMacMgrFirefox@tencent.com.xpi"
#define SAFARI_PLUGIN_PATH      @"/Library/Safari/Extensions/QQMacMgrPlugin.safariextz"
#define CHROME_PLUGIN_PATH      @"/Library/Application Support/Google/Chrome/Default/Extensions"
#define CHROME_PREFERENCE_PATH  @"/Library/Application Support/Google/Chrome/Default/Preferences"
#define CHROME_INSTALL_NAME     @"Lemon Plugin"

// 垃圾桶App增加消息
#define NOTIFICATION_TRASH_CHANGE_TO_MONITOR  @"lemon_notification_trash_changed_to_monitor"
#define NOTIFICATION_TRASH_CHANGE_TO_LEMON   @"notification_trash_changed_to_lemon"

// InstallCastle 函数的返回值
// OK
#define QMINST_ERR_OK               0
// 安装程序不在Applications目录下被运行
#define QMINST_ERR_POSITION         1
// 安装程序不拥有root权限
#define QMINST_ERR_PRIVILEGE        2
// 创建support目录失败
#define QMINST_ERR_CREATESUPPORT    3
// 创建data目录失败
#define QMINST_ERR_CREATEDATA       4
// 拷贝后台自身失败
#define QMINST_ERR_COPYSELF         5
// 拷贝后台启动文件失败
#define QMINST_ERR_COPYPLIST        6
// 拷贝监控启动文件失败
#define QMINST_ERR_COPYMONITORPLIST 7


//设备监控
#define OWL_PROC_DELTA          @"OWL_PROC_DELTA"
#define OWL_PROC_ID             @"OWL_PROC_ID"
#define OWL_PROC_NAME           @"OWL_PROC_NAME"
#define OWL_PROC_PATH           @"OWL_PROC_PATH"
#define OWL_DEVICE_TYPE         @"OWL_DEVICE_TYPE"
#define VDCAssistantPath                @"/System/Library/Frameworks/CoreMediaIO.framework/Versions/A/Resources/VDC.plugin/Contents/Resources/VDCAssistant"
#define AppleCameraAssistantPath        @"/Library/CoreMediaIO/Plug-Ins/DAL/AppleCamera.plugin/Contents/Resources/AppleCameraAssistant"
#define AudioAssistantPath        @"/usr/sbin/coreaudiod"

// 状态栏显示方式
#define STATUS_TYPE_LOGO (1 << 0)
#define STATUS_TYPE_MEM  (1 << 1)
#define STATUS_TYPE_DISK (1 << 2)
#define STATUS_TYPE_TEP  (1 << 3)
#define STATUS_TYPE_FAN  (1 << 4)
#define STATUS_TYPE_NET  (1 << 5)
#define STATUS_TYPE_CPU  (1 << 6)
#define STATUS_TYPE_GPU  (1 << 7)
#define STATUS_TYPE_GLOBAL (0x80000000)
#define STATUS_TYPE_BOOTSHOW (0x40000000)
#define STATUS_TYPE_EXIST_SHOW_BELOW_7 64
#define kLemonShowMonitor               @"kLemonShowMonitor"
#define kLemonShowMonitorType           @"kLemonShowMonitorType"
#define kLemonShowMonitorCfg            @"kLemonShowMonitorCfg"
#define kLemonQuitMonitorManual         @"kLemonQuitMonitorManual"
//notification
#define kShowOwlWindowFromMonitor       @"kShowOwlWindowFromMonitor"
#define kShowPreferenceWindow           @"kShowPreferenceWindow"
#define kTellMonitorTeminate            @"kTellMonitorTeminate"
#define kTellMonitorStartOwlProtect     @"kTellMonitorStartOwlProtect"
#define kTellMonitorStopOwlProtect      @"kTellMonitorStopOwlProtect"

typedef NS_ENUM(NSUInteger, LemonAppRunningType) {
    LemonAppRunningNormal = 1020,
    LemonAppRunningFirstInstall = 1021,
    LemonAppRunningReInstall = 1022,
    LemonMonitorRunningOSBoot = 1023,
    LemonMonitorRunningMenu = 1024,
    LemonAppRunningReInstallAndMonitorExist = 1025,
    LemonAppRunningReInstallAndMonitorNotExist = 1026,
};

#endif
