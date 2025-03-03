//
//  AppDelegate.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "AppDelegate.h"
#import "QMDataConst.h"
#import "LemonDaemonConst.h"
#import <LemonUninstaller/AppTrashDel.h>
#import "LMMonitorController.h"
#import <QMCoreFunction/QMDataCenter.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/TimeUitl.h>

#import "QMEarlyWarning.h"
#import <QMCoreFunction/NSTimer+Extension.h>
#ifndef APPSTORE_VERSION
#import <PrivacyProtect/OwlManager.h>
#endif
#import <AFNetworking/AFNetworking.h>
#import <PrivacyProtect/QMUserNotificationCenter.h>
#import <UserNotifications/UserNotifications.h>
//#import <Rqd/CrashReporter.h>
#import <QMCoreFunction/CCMBase64.h>
#import <QMCoreFunction/CCMCryptor.h>
#import <QMCoreFunction/CCMPublicKey.h>
#import <QMCoreFunction/CCMKeyLoader.h>
#import <QMCoreFunction/LMKeychain.h>
#import <QMCoreFunction/LMDaemonStartupHelper.h>
#import "LemonMonitroHelpParams.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import "LMTrashSizeCheckWindowController.h"
#import "NSDate+LMCalendar.h"
#import "LemonMonitorDNCServer.h"

@interface AppDelegate () <NSUserNotificationCenterDelegate>
{
    BOOL mgrUpdate;
    AppTrashDel *appTashDel;
    LMMonitorController *monitorController;
    NSDistributedNotificationCenter *center;
    LMTrashSizeCheckWindowController *trashSizeCheckWndController;
    id statusMonitorGlobal;
    id statusMonitorLocal;
}

@property (nonatomic, assign) BOOL needShowBulle;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.currentNet = CurrentNetworkStatusUnknown;
    self.needShowBulle = NO;

    NSLog(@"applicationDidFinishLaunching enter");    
#ifdef DEBUG
    // 在 debug版, 使主线程的 unCaughtException 不被自动捕获,触发崩溃逻辑,方便定位问题.(默认逻辑不会崩溃,只是打印 log).
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
#endif
    
    NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
    if(languageString != nil){
        [NSBundle setLanguage:languageString bundle:[NSBundle mainBundle]];
    }
    if(languageString != nil){
        NSLog(@"middle to hook language string = %@", languageString);
        [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[AppTrashDel class]]];
    }
    
    [LMDaemonStartupHelper shareInstance].agentPath = [[[NSBundle bundleWithPath:DEFAULT_APP_PATH] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
    [LMDaemonStartupHelper shareInstance].arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kReloadListenPlist], nil];
    [LMDaemonStartupHelper shareInstance].cmdPath = DAEMON_ACTIVATOR_CMD;
    int ret = [[LMDaemonStartupHelper shareInstance] activeDaemon];
    
//同步主界面偏好设置中关于托盘的设置（保护作用，防止主界面异常无法关闭）
//主界面通过runningApplicationsWithBundleIdentifier方式查找来terminate，有不少用户反馈无法关闭Monitor，
#ifndef DEBUG
    [self needTeminateSelf];
#endif
        
    // 滚动条显示
    [[NSUserDefaults standardUserDefaults] setObject:@"WhenScrolling" forKey:@"AppleShowScrollBars"];
    
    // 浮窗监控
    monitorController = [[LMMonitorController alloc] init];
    [monitorController load];
    
    appTashDel = [[AppTrashDel alloc] init];
    
    [self startup];
    
    // 预警提示(仅针对10.8以上系统)
    if ([QMEnvironmentInfo systemVersion] >= QMSystemVersionMountainLion)
    {
        [QMEarlyWarning sharedInstance];
    }
            
    [self addObserver];
    [self loadMonitorNotification];
    //先stat一次内存，方便首次show出进程信息时进程的内存准确
    [[LemonMonitroHelpParams sharedInstance] startStatMemory];
    [[LemonMonitroHelpParams sharedInstance] stopStatMemory];
    
    [self aFNetworkStatus];
    [self handerMonitorGlobal];
    [[LemonMonitorDNCServer sharedInstance] addServer];
}

-(void)addObserver{
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    //卸载残留检测，由Monitor检测
    [center addObserver:self selector:@selector(trashChanged:) name:NOTIFICATION_TRASH_CHANGE_TO_MONITOR object:nil];
    [center addObserver:self selector:@selector(trashSizeOverThreshold:) name:NOTIFICATION_TRASH_SIZE_OVER_THRESHOLD object:nil];
    //注册主题设置监听
    if (@available(macOS 10.14, *)){
        [center addObserver:self selector:@selector(updateTheme) name:NOTIFICATION_THEME_CHANGED object:nil];
        [self updateTheme];
    }
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                              selector: @selector(willSleepNotification:)
                                                                  name: NSWorkspaceWillSleepNotification object: NULL];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                              selector: @selector(didWakeNotification:)
                                                                  name: NSWorkspaceDidWakeNotification object: NULL];
}

-(void)updateTheme{
    NSLog(@"%s,received notification",__FUNCTION__);
    NSInteger theme = [[NSUserDefaults standardUserDefaults] integerForKey:K_THEME_MODE_SETTED];
    NSLog(@"%s,received notification, theme:%ld",__FUNCTION__,(long)theme);
//    CFPreferencesAppSynchronize((__bridge CFStringRef)(MAIN_APP_BUNDLEID));
//    NSNumber *type = (__bridge_transfer NSNumber *)CFPreferencesCopyAppValue((__bridge CFStringRef)(K_THEME_MODE_SETTED), (__bridge CFStringRef)(MAIN_APP_BUNDLEID));
//    theme = type.integerValue;
    switch (theme) {
        case V_LIGHT_MODE:
            [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
//            [NSApplication appear]
            break;
        case V_DARK_MODE:
            if (@available(macOS 10.14, *)) {
                [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
            }
            break;
        case V_FOLLOW_SYSTEM:
            [[NSApplication sharedApplication] setAppearance:nil];
            break;
        default:
            break;
    }
}



- (void)teminateSelf{
    NSLog(@"%s ....\n", __FUNCTION__);
    [[NSApplication sharedApplication] terminate:nil];
}

// 使得跨进程通信相应速度加快. notification center
-(void)applicationDidResignActive:(NSNotification *)notification{
    [center setSuspended:NO];
}


- (void)trashChanged:(NSNotification *)notify {
    NSDictionary *userInfo = [notify userInfo];
    NSArray *appTrash = [userInfo objectForKey:@"items"];
    if (appTrash) {
        [appTashDel delTrashOfApps:appTrash];
    }
    NSLog(@"[TrashDel]  trashChanged, %@", userInfo);
}

-(void)trashSizeOverThreshold: (NSNotification *)notify{
    //垃圾桶；如果用户点击暂不提醒，则当天不提醒。5.1.12
    double lastNextRemindTime = [[NSUserDefaults standardUserDefaults] doubleForKey:@"kTrashSizeNextRemindTime"];
    if (lastNextRemindTime != 0) {
        NSDate *lastNextRemindDate = [NSDate dateWithTimeIntervalSince1970:lastNextRemindTime];
        NSDate *currentDate = [NSDate date];
        if (![currentDate lm_isSameDayAsDate:lastNextRemindDate]) {
            // 不是同一天清空，继续弹出
            [[NSUserDefaults standardUserDefaults] setDouble:0.0 forKey:@"kTrashSizeNextRemindTime"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            // 当天不不在弹出
            return;
        }
    }

    NSDictionary *userInfo = notify.userInfo;
    NSNumber *trashSizeNumber = [userInfo objectForKey:@"trashSize"];
    if(!trashSizeCheckWndController){
        NSLog(@"%s, trashSizeCheckWndController is null", __FUNCTION__);
        trashSizeCheckWndController = [[LMTrashSizeCheckWindowController alloc]init];
    }
    trashSizeCheckWndController.trashSize = trashSizeNumber.floatValue;
    NSLog(@"%s,%@, trashSize: %f",__FUNCTION__,trashSizeCheckWndController, trashSizeCheckWndController.trashSize);
    [trashSizeCheckWndController show];
}

- (void)willSleepNotification:(NSNotification *)notify {
    NSLog(@"系统将要进入休眠");
}

- (void)didWakeNotification:(NSNotification *)notify {
    NSLog(@"系统已唤醒");
}

- (void)needTeminateSelf
{
    NSInteger startParamsCmd = [[LemonMonitroHelpParams sharedInstance] startParamsCmd];
    
    CFPreferencesAppSynchronize((__bridge CFStringRef)(MAIN_APP_BUNDLEID));
    NSNumber *cfg = (__bridge_transfer NSNumber *)CFPreferencesCopyAppValue((__bridge CFStringRef)(kLemonShowMonitorCfg), (__bridge CFStringRef)(MAIN_APP_BUNDLEID));
    
    NSLog(@"needTeminateSelf startParamsCmd=%lu,config=%lx", startParamsCmd, (long)[cfg integerValue]); // %x 16进制打印 
    
    
    if (startParamsCmd == LemonAppRunningFirstInstall)
    {
        // 首次安装，要启动
    }
    else if (startParamsCmd == LemonMonitorRunningMenu)
    {
        // 手动从菜单栏打开，要启动
        [self clearQuitMonitorManaualState];
    }
    else if (startParamsCmd == LemonMonitorRunningOSBoot)
    {
        // 如果开机不重启，要退出
        if (([cfg integerValue] & STATUS_TYPE_BOOTSHOW) == 0)
        {
            [self teminateSelf];
        } else {
             [self clearQuitMonitorManaualState];
        }
    }
}

- (void) clearQuitMonitorManaualState{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:FALSE] forKey:kLemonQuitMonitorManual];
}

- (void)loadMonitorNotification{
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:@"LemonResearchNotification"];
#ifndef APPSTORE_VERSION
    [[OwlManager shareInstance] startOwlProtect];
#endif
}



#ifndef APPSTORE_VERSION
-(void)tellMonitorStopOwlProtect{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[OwlManager shareInstance] stopOwlProtect];
    });
}
-(void)tellMonitorStartOwlProtect{
    [[OwlManager shareInstance] startOwlProtect];
}

-(void)receivedVedioStateChanged:(NSNotification *)notification
{
    BOOL state = [[notification.userInfo objectForKey:@"state"] boolValue];
    [[OwlManager shareInstance] setWatchVedio:state toDb:NO];
}
-(void)receivedAudioStateChanged:(NSNotification *)notification
{
    BOOL state = [[notification.userInfo objectForKey:@"state"] boolValue];
    [[OwlManager shareInstance] setWatchAudio:state toDb:NO];
}
#endif

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
    return NSTerminateNow;
}
- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"applicationWillTerminate enter");
    
    // 记录退出时间
    [[QMDataCenter defaultCenter] setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:kQMMonitorExitTime];
    
    // 退出时析构
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:nil];
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    
    [[LMDaemonStartupHelper shareInstance] notiflyDaemonClientExit];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return YES;
}

- (void)mgrRemovedTrash:(NSNotification *)notify
{
    //隐藏浮窗
    [monitorController dismiss];
    
    //展示反馈视图
    //[NSApp runModalForWindow:feedbackWC.window];
    
    //移除Dock上的图标
    [self removeDockIcon];
    
    //移除UserDefauts
    system([[@"defaults delete " stringByAppendingString:MAIN_APP_BUNDLEID] UTF8String]);
    system([[@"defaults delete " stringByAppendingString:MONITOR_APP_BUNDLEID] UTF8String]);
    
    //执行卸载
    [[McCoreFunction shareCoreFuction] unInstallMagican];
    NSLog(@"terminate at remove self");
    [NSApp terminate:nil];
}

- (void)mgrUpdateNotificaton:(NSNotification *)notify
{
    mgrUpdate = YES;
}

extern CFAbsoluteTime g_startTime;
- (void)startup
{
    QMDataCenter *dataCenter = [QMDataCenter defaultCenter];
        
    // 是否第一次运行
    uint16_t firstRun;
    if ([dataCenter valueExistsForKey:kQMMonitorFirstRun] && ![dataCenter boolForKey:kQMMonitorFirstRun])
    {
        firstRun = 0;
    }
    else
    {
        firstRun = 1;
        [dataCenter setBool:NO forKey:kQMMonitorFirstRun];
    }
    
    // 上次的运行时长
    uint32_t lastRunTime = 0;
    if ([dataCenter valueExistsForKey:kQMMonitorLaunchTime] && [dataCenter valueExistsForKey:kQMMonitorExitTime])
    {
        NSTimeInterval startIntreval = [dataCenter doubleForKey:kQMMonitorLaunchTime];
        NSTimeInterval exitIntreval = [dataCenter doubleForKey:kQMMonitorExitTime];
        if (exitIntreval > startIntreval)
        {
            // 秒 -> 分钟
            lastRunTime = (uint32_t)((exitIntreval - startIntreval) / 60);
        }
    }
    
    // 记录本次启动时间
    [dataCenter setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:kQMMonitorLaunchTime];
}

// 用于删除Dock上的图标
- (void)removeDockIcon
{
    //读取Dock的配置文件，通过CFPreferences的API可以避免直接读文件不同步的问题
    CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
    NSArray *apps = (__bridge_transfer NSArray *)CFPreferencesCopyAppValue( CFSTR("persistent-apps"), CFSTR("com.apple.dock") );
    
    if (!apps || ![apps isKindOfClass:[NSArray class]])
        return;
    
    NSMutableArray *removeApps = [[NSMutableArray alloc] init];
    for (NSDictionary *appInfo in apps)
    {
        if (![appInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *titleInfo = [appInfo objectForKey:@"tile-data"];
        if (!titleInfo || ![titleInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *fileInfo = [titleInfo objectForKey:@"file-data"];
        if (!fileInfo || ![fileInfo isKindOfClass:[NSDictionary class]])
            continue;
        
        NSString *fileURLString = [fileInfo objectForKey:@"_CFURLString"];
        NSURL *fileURL = [NSURL URLWithString:fileURLString];
        NSString *filePath = [fileURL path];
        if (!filePath)
            continue;
        
        if ([[filePath lastPathComponent] isEqualToString:MAIN_APP_NAME])
        {
            [removeApps addObject:appInfo];
        }
    }
    
    if ([removeApps count] > 0)
    {
        NSMutableArray *tempApps = [apps mutableCopy];
        [tempApps removeObjectsInArray:removeApps];
        
        //写入Dock的配置文件
        //通过CFPreferences的API可以避免直接读文件不同步的问题
        CFPreferencesSetAppValue(CFSTR("persistent-apps"), (__bridge CFArrayRef)tempApps, CFSTR("com.apple.dock"));
        CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
        
        //杀死Dock进程(重启)
        system("killall Dock");
    }
}

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification.identifier isEqualToString:@"LemonAppUpdateNotification"]) {
        [self showInstallLemonPage];
    } else {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[notification.userInfo objectForKey:@"URL"]]];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#pragma mark Update

- (void)handerMonitorGlobal {
    void (^handler)(NSEvent *) = ^void(NSEvent *event){
    //如果 事件在 Monitor窗口触发,则不dismiss 窗口.
        self.needShowBulle = NO;
    };
    
    if (!statusMonitorGlobal) {
        statusMonitorGlobal = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:handler];
        statusMonitorLocal  = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown  handler:^NSEvent *(NSEvent *event) {
            handler(event);
            return event;
        }];
    }
}

- (void)aFNetworkStatus {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        //这里是监测到网络改变的block  可以写成switch方便
        //在里面可以随便写事件
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"未知网络状态");
                self.needShowBulle = NO;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"无网络");
                self.needShowBulle = NO;
                self.currentNet = CurrentNetworkStatusNotReachable;
                break;
            default:
                NSLog(@"蜂窝数据网/WiFi网络");
                if (self.currentNet == CurrentNetworkStatusNotReachable) {
                    self.needShowBulle = YES;
                }
                self.currentNet = CurrentNetworkStatusReachable;
                break;
        }
    }] ;
    
    [manager startMonitoring];
}

- (void)showInstallLemonPage{
    NSString *strNewVersion = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersion];
    if (strNewVersion) {
        [[NSUserDefaults standardUserDefaults] setObject:strNewVersion forKey:kIgnoreLemonNewVersion];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *updatePath = [[DEFAULT_APP_PATH stringByAppendingPathComponent:@"Contents/Frameworks"]
                                stringByAppendingPathComponent:UPDATE_APP_NAME];
        NSArray *arguments = @[];
        
        NSLog(@"showInstallLemonPage: %@, %@", updatePath, arguments);
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:updatePath]
                                                      options:NSWorkspaceLaunchWithoutAddingToRecents
                                                configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
                                                        error:NULL];
    });
}
- (void)checkShowNotification{
    NSString *strNewVersion = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersion];
    if (strNewVersion) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kIgnoreLemonNewVersion]) {
            
        } else {
            if (![strNewVersion isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kIgnoreLemonNewVersion]]) {
            } else {
                return;
            }
        }
    } else {
        return;
    }
    
    //有新版本，但是用户7天没有点击过版本升级，则发出notification
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.identifier = @"LemonAppUpdateNotification";
    notification.title = @"版本升级";
    notification.informativeText = @"有新版本可以升级";
    notification.otherButtonTitle = @"取消";
    notification.actionButtonTitle = @"升级";
    notification.hasActionButton = YES;
    [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                               key:@"LemonResearchNotification"];
}

@end
