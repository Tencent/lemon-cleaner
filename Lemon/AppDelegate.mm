//
//  AppDelegate.m
//  Lemon
//

//  Copyright © 2018  Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import <QMCoreFunction/QMDataCenter.h>
#import <AFNetworking/AFNetworking.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "LemonMainWndController.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/NSTimer+Extension.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <LemonClener/DeamonTimeHelper.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import "QMDataConst.h"
#import <Foundation/Foundation.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import "PreferenceWindowController.h"
#import "PreferenceViewController.h"
#ifndef APPSTORE_VERSION
#import "QMDataConst.h"
#import <QMCoreFunction/LMDaemonStartupHelper.h>
#import "LemonStartUpParams.h"
#import "LMVersionHelper.h"
#import "AppTrashDel.h"
#import "LMInstallerHelper.h"
#import "LemonDaemonConst.h"
#import "PreLaunch.h"
#import <QMCoreFunction/STPrivilegedTask.h>
#import "RegisterWindowController.h"
#import "RegisterUtil.h"
#import "LMSplashWindowController.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import <LemonSpaceAnalyse/McSpaceAnalyseWndController.h>
#import "LemonVCModel.H"
#endif
#import "MasLoginItemManager.h"
#import <LemonClener/LMWebWindowController.h>
#import "LMAboutWindow.h"
#import "LemonDNCClient.h"
#import "LemonDNCServier.h"

#define IS_INIT_PREFRENCE_CONFIGURERATION @"is_init_prefrence_configureration"
#define DOCK_ON_OFF_STATE @"dock_on_off_state"
#define NEED_RELAUNCH_APP @"need_relaunch_app"
#define helperAppBundleIdentifier @"com.tencent.LemonASMonitor"
#define terminateNotification @"TERMINATEHELPER"
#define IS_APPSTORE_FIRST_INSTALL @"is_appstore_first_install"
#define SHOW_PREF_SETTING_NOTI @"show_pref_setting_noti"
#define LEMON_SHOW_FULL_VERSION_SPLASH_GUIDE_BOOL @"lemon_show_full_version_splash_guide_bool"

#define IS_INIT_PREFRENCE_TRASH_CHECK @"is_init_prefrence_configureration_trash_check"
#define IS_SHOW_REQUEST_FULL_DISK_PERMISSION_AT_BEGIN @"is_show_request_full_disk_permission_at_begin"

extern "C" int CmcGetCurrentAppVersion(char *version, int version_size, char *buildver, int buildver_size);

#ifndef APPSTORE_VERSION
@interface AppDelegate () <QMWindowDelegate> {
    AppTrashDel *appTashDel;
    //    RegisterWindowController *registerWC;
    LMSplashWindowController *splashWC;
#else
    @interface AppDelegate () <NSUserNotificationCenterDelegate> {
#endif
        LemonMainWndController *mainWC;
        McSpaceAnalyseWndController *spaceWC;
        LMWebWindowController *webWC;
        NSWindowController* _aboutWC;
        NSTimer *repeatTimer;
        
        BOOL _appRelaunch;
    }
    
    @property (weak) IBOutlet NSWindow *window;
    @property (strong) PreferenceWindowController* prefWindowController;
#ifndef APPSTORE_VERSION
    @property (nonatomic, assign) LemonAppRunningType runningType;
#else
    @property (nonatomic,strong) NSStatusItem *statusItem;
#endif
    @property (nonatomic,strong) NSDate *versionDate;
    @property (nonatomic, assign) BOOL getGuidResult;
    @end
    
    @implementation AppDelegate
    
#pragma mark - NSApplicationDelegate
    - (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
        [self redirctNSlog];
        if (@available(macOS 10.14, *)) {
            //        [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
        }
    
        _appRelaunch = NO;
        _hasShowSplashPage = YES;
#ifdef DEBUG
        // 在 debug版, 使主线程的 unCaughtException 不被自动捕获,触发崩溃逻辑,方便定位问题.(默认逻辑不会崩溃,只是打印 log).
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
#endif
        
#ifndef APPSTORE_VERSION
        self.runningType = (LemonAppRunningType)[[LemonStartUpParams sharedInstance] paramsCmd];
        
        // [McCoreFunction setAppStoreVersion:NO];
#else
        NSLog(@"start to connect lemonas");
        [McCoreFunction setAppStoreVersion:YES];
#endif
        [QMDataCenter defaultCenter];
        
        NSLog(@"applicationDidFinishLaunching");
        // Insert code here to initialize your application
        
#ifndef DEBUG
        
#ifndef APPSTORE_VERSION
        // 关键目录不存在（包括/Applications/Tencent lemon.app）, 版本号不一样，则进行覆盖安装
        int installType = LemonAppRunningNormal;
        if ([PreLaunch needToInstall:&installType]) {
            self.runningType = (LemonAppRunningType)installType;
            NSLog(@"%s needToInstall and runningType: %ld", __FUNCTION__, self.runningType);
            [self installLemon];
        }
        NSLog(@"replaceInstall end");
        if (installType == LemonAppRunningFirstInstall){
            // 这个判断不太准. NSFileManager 去判断 系统目录下 如"/Library/Application Support/Lemon"是否存在时, 即使真实存在,系统也可能返回不存在(Lemon 低权限).
            _hasShowSplashPage = NO;
        }
        // 使用 UserDefault 辅助判断(只要原来显示过,则不在显示)
        BOOL hasShowFullVersionSplash = [[NSUserDefaults standardUserDefaults] boolForKey:LEMON_SHOW_FULL_VERSION_SPLASH_GUIDE_BOOL];
        if(hasShowFullVersionSplash){
            _hasShowSplashPage = hasShowFullVersionSplash;
        }
#endif
        
#endif
        
#ifndef APPSTORE_VERSION
        [LMDaemonStartupHelper shareInstance].agentPath = [[[NSBundle bundleWithPath:DEFAULT_APP_PATH] privateFrameworksPath] stringByAppendingPathComponent:DAEMON_APP_NAME];
        [LMDaemonStartupHelper shareInstance].arguments = [NSArray arrayWithObjects:[NSString stringWithUTF8String:kReloadListenPlist], nil];
        [LMDaemonStartupHelper shareInstance].cmdPath = DAEMON_ACTIVATOR_CMD;
        int ret = [[LMDaemonStartupHelper shareInstance] activeDaemon];
        NSLog(@"activeDaemon end");
        [self initData];
        
        appTashDel  = [[AppTrashDel alloc] init];
        
        
#ifndef DEBUG
        [self keepMonitorAlive];
#endif
        
        // 主界面
        mainWC = [[LemonMainWndController alloc] init];
        //[mainWC.window makeKeyAndOrderFront:nil];
        
        [self showMainWindowByState];
        
        [self loadLemonNotification];
                                             
        if ([[LemonStartUpParams sharedInstance] paramsCmd] == 1030){
            
            [self lemonSpaceShow];
            [mainWC.window orderOut:nil];
        }
        if ([[LemonStartUpParams sharedInstance] paramsCmd] == 1031){
            
            [self lemonWebShow];
            [mainWC.window orderOut:nil];
        }
        NSInteger startUpCmd = [[LemonStartUpParams sharedInstance] paramsCmd];
        switch (startUpCmd) {
            case LEMON_PARAMS_CMD_START_OWL_WINDOW:
                break;
            case LEMON_PARAMS_CMD_START_PREFERENCES_WINDOW:
                if (!self.prefWindowController)
                {
                    self.prefWindowController = [[PreferenceWindowController alloc] init];
                }
                
                //
                [mainWC.window orderOut:nil];
                //            [registerWC.window orderOut:nil];
                
                //
                [self.prefWindowController.window  makeKeyAndOrderFront:nil];
                break;
                
            default:
                break;
        }
#else
        mainWC = [[LemonMainWndController alloc] init];
        [mainWC.window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
        //    [self addStatusItem];
        [[MasLoginItemManager sharedManager] setupMASXpcWhenLogItemRunning];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asPrefrecesSet:) name:OPEN_LOGIN_ITEM_PREFRENCE object:nil];
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        if (![SharedPrefrenceManager getBool:IS_APPSTORE_FIRST_INSTALL]) {
            [SharedPrefrenceManager putBool:YES withKey:IS_APPSTORE_FIRST_INSTALL];
        }
        
#endif

        [[NSUserDefaults standardUserDefaults] setObject:@"WhenScrolling" forKey:@"AppleShowScrollBars"];
        if (@available(macOS 10.14, *)){
            [self updateTheme];
        }
                
        NSString *uploadVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonUploadVersion"];
        NSString *strVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *strBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString *strVersionAndBuild = [NSString stringWithFormat:@"%@(%@)", strVersion, strBuild];
        
        if (uploadVersion == nil || ![strVersionAndBuild isEqualToString:uploadVersion] ) {
            NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
            if (infoDic) {
                NSString *vendorCode = [infoDic objectForKey:@"VendorCode"];
                if (vendorCode) {
                    [[NSUserDefaults standardUserDefaults] setObject:strVersionAndBuild forKey:@"kLemonUploadVersion"];
                }
            }
        }
        
        [self aFNetworkStatus];
        
        [[LemonDNCServier sharedInstance] addServer];
        if (@available(macOS 13.0, *)) {
            [self checkFullDiskAccessAndRestartMonitorIfNeeded];
        }
    }
    
    /// 检测完全磁盘访问权限是否变化
    - (void)checkFullDiskAccessAndRestartMonitorIfNeeded {
        BOOL lastValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"kLemonFullDiskAccessFlag"];
        BOOL currentValue = [QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized;
        [[NSUserDefaults standardUserDefaults] setBool:currentValue forKey:@"kLemonFullDiskAccessFlag"];
        if (lastValue != currentValue) {
            [[LemonDNCClient sharedInstance] restart:LemonDNCRestartTypeMonitor reason:LemonDNCRestartReasonFullDiskAccess];
        }
    }
    
    - (void)aFNetworkStatus {
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            //这里是监测到网络改变的block  可以写成switch方便
            //在里面可以随便写事件
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    NSLog(@"未知网络状态");
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    NSLog(@"无网络");
                    [userInfo setValue:@(0) forKey:@"network"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"K_Curent_NetWork" object:nil userInfo:userInfo];
                    break;
                default:
                  
                    [userInfo setValue:@(1) forKey:@"network"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"K_Curent_NetWork" object:nil userInfo:userInfo];
                    NSLog(@"蜂窝数据网/WiFi网络");
                    break;
            }
        }] ;
        [manager startMonitoring];
    }
    
    - (void)applicationWillTerminate:(NSNotification *)aNotification {
        NSLog(@"applicationDidFinishLaunching");
        // Insert code here to tear down your application
#ifndef APPSTORE_VERSION
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
        
        [[LMDaemonStartupHelper shareInstance] notiflyDaemonClientExit];
#else
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
#endif
        if(_appRelaunch){
            _appRelaunch = NO;
            
            @try {
                NSString *path = [[NSBundle mainBundle] bundlePath];
                NSURL *appUrl = [NSURL fileURLWithPath:path];
                [[NSWorkspace sharedWorkspace] launchApplicationAtURL:appUrl options:NSWorkspaceLaunchNewInstance configuration:@{} error:NULL];
            }
            @catch (NSException *exption) {
                NSURL *appUrl = [NSURL fileURLWithPath:@"/Applications/Tencent Lemon.app"];
                [[NSWorkspace sharedWorkspace] launchApplicationAtURL:appUrl options:NSWorkspaceLaunchNewInstance configuration:@{} error:NULL];
            }
            
        }
        
    }
    
    - (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
    {
            NSLog(@"applicationShouldHandleReopen");
#ifndef APPSTORE_VERSION
        [self showMainWindowByState];
#else
        [mainWC.window makeKeyAndOrderFront:nil];
#endif
        
        return YES;
    }
    
#ifndef APPSTORE_VERSION
    - (void)initData{
        BOOL isInitConfigure = [SharedPrefrenceManager getBool:IS_INIT_PREFRENCE_CONFIGURERATION];
        BOOL isInitTrashCheck = [SharedPrefrenceManager getBool:IS_INIT_PREFRENCE_TRASH_CHECK];
        NSLog(@"%s isInitConfig:%d", __FUNCTION__, isInitConfigure);
        BOOL trashWatchAppEnable = YES;
        BOOL trashWatchSizeEnable = YES;

        if (!isInitConfigure) {
            [SharedPrefrenceManager putBool:YES withKey:DOCK_ON_OFF_STATE];
            [SharedPrefrenceManager putBool:YES withKey:IS_INIT_PREFRENCE_CONFIGURERATION];
        }
        else {
            trashWatchAppEnable = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH];
        }
        //4.0版本之前没有废纸篓检测项，需要适配覆盖安装的场景
        if(isInitTrashCheck){
            trashWatchSizeEnable = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_SIZE_WATCH];
        }
        
        [self saveTrahCheckStatus:trashWatchAppEnable sizeCheck:trashWatchSizeEnable];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AppTrashDel enableTrashWatch:YES]; //始终对废纸篓进行检测，根据开关状态判断是否提示
        });
    }
    
    -(void)saveTrahCheckStatus: (BOOL)appCheck sizeCheck: (BOOL)sizeCheck{
        [SharedPrefrenceManager putBool:appCheck withKey:IS_ENABLE_TRASH_WATCH];
        [SharedPrefrenceManager putBool:sizeCheck withKey:IS_ENABLE_TRASH_SIZE_WATCH];
        [SharedPrefrenceManager putBool:YES withKey:IS_INIT_PREFRENCE_TRASH_CHECK];
        CFPreferencesSetAppValue((__bridge CFStringRef)(IS_ENABLE_TRASH_WATCH), (__bridge CFNumberRef)[NSNumber numberWithBool:appCheck], (__bridge CFStringRef)MONITOR_APP_BUNDLEID);
        CFPreferencesAppSynchronize((__bridge CFStringRef)MONITOR_APP_BUNDLEID);
    }
    
    //MARK: 设置应用主题
    -(void)updateTheme{
        NSInteger theme = [[NSUserDefaults standardUserDefaults] integerForKey:K_THEME_MODE_SETTED];
        switch (theme) {
            case V_LIGHT_MODE:
                [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
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
        
        CFPreferencesSetAppValue((__bridge CFStringRef)(K_THEME_MODE_SETTED), (__bridge CFNumberRef)[NSNumber numberWithInteger:theme], (__bridge CFStringRef)MONITOR_APP_BUNDLEID);
        CFPreferencesAppSynchronize((__bridge CFStringRef)MONITOR_APP_BUNDLEID);
    }
    
    - (void)loadLemonNotification{
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(showOwlWindowFromMonitor) name:kShowOwlWindowFromMonitor object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lemonPeferenceShow) name:kShowPreferenceWindow object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needRelaucnApp) name:NEED_RELAUNCH_APP object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lemonSpaceShow) name:@"kLEMON_MONITOR_NEED_DISK_SPACE" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lemonWebShow) name:@"kLEMON_MONITOR_NEED_HAPPY_BIR" object:nil];
    }
    
    - (void)lemonWebShow {
        webWC =  [self getLMWebWindowControllerByClassname:@"LMWebWindowController"];
        [webWC.window makeKeyAndOrderFront:nil];
    }
    
    -(LMWebWindowController *)getLMWebWindowControllerByClassname:(NSString *)className{
        LMWebWindowController *controller = nil;
        controller = [[LemonVCModel shareInstance].toolConMap objectForKey:className];
        if (controller == nil) {
            controller = [[LMWebWindowController alloc] init];
            controller.delegate = self;
            [[LemonVCModel shareInstance].toolConMap setValue:controller forKey:className];
        }
        return controller;
    }
    
    - (void)lemonSpaceShow {
        spaceWC =  [self getWindowControllerByClassname:@"McSpaceAnalyseWndController"];
        [spaceWC.window makeKeyAndOrderFront:nil];
    }
    
    - (McSpaceAnalyseWndController *)getWindowControllerByClassname:(NSString *)className{
        McSpaceAnalyseWndController *controller = nil;
        controller = [[LemonVCModel shareInstance].toolConMap objectForKey:className];
        if (controller == nil) {
            controller = [[McSpaceAnalyseWndController alloc] init];
            controller.delegate = self;
            [[LemonVCModel shareInstance].toolConMap setValue:controller forKey:className];
        }
        return controller;
    }
    -(void)windowWillDismiss:(NSString *)clsName{
        [[LemonVCModel shareInstance].toolConMap setValue:nil forKey:clsName];
    }
    -(void)needRelaucnApp{
        _appRelaunch = YES;
        [NSApp terminate:self];
    }
    
    -(void)showOwlWindowFromMonitor{
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self showMainWCAfterRegister];
    }
    
    -(void)showMainWCAfterRegister{
        [mainWC.window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    
    //首先显示引导页, 如果引导页已经显示过,显示注册页,如果注册页也显示过,则显示主界面
    -(void) showMainWindowByState{
        NSLog(@"%s :_hasShowSplashPage:%d, stacktrace: %@", __FUNCTION__, _hasShowSplashPage, [NSThread callStackSymbols]);
        if(_hasShowSplashPage){
            [self showMainWCAfterRegister];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LEMON_SHOW_FULL_VERSION_SPLASH_GUIDE_BOOL];
        }else{
            [self showSplashWC];
        }
        
    }
    
    - (void)showSplashWC{
        NSLog(@"%s :_hasShowSplashPage:%d, stacktrace: %@", __FUNCTION__, _hasShowSplashPage, [NSThread callStackSymbols]);
        if(!splashWC){
            splashWC =  [[LMSplashWindowController alloc] init];
            [splashWC.window center];
        }
        [splashWC.window makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    
    -(void)clearSplashWC{
        splashWC = nil;
    }
    
#pragma mark - init prelaunch
    - (int)removeMonitorAndDaemon
    {
        NSLog(@"remove old daemon and monitor");
        //monitor是Agent 需要用非root权限unload
        NSString *cmd = [NSString stringWithFormat:@"launchctl unload %@", MONITOR_LAUNCHD_PATH];
        system([cmd UTF8String]);
        
        NSString *script = [[NSBundle mainBundle] pathForResource:@"removeDaemonAndMonitor.sh" ofType:nil];
        NSArray *arguments = [NSArray arrayWithObjects:script,nil];
        STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/bin/sh" arguments:arguments];
        [instTask waitUntilExit];
        int retcode = [instTask terminationStatus];
        NSLog(@"removeDaemonAndMonitor.sh return: %d", retcode);
        return retcode;
    }
    
    - (int)createMoveFlagFile
    {
        NSLog(@"createMoveFlagFile");
        NSString *script = [[NSBundle mainBundle] pathForResource:@"createRemoveFlagFile.sh" ofType:nil];
        NSArray *arguments = [NSArray arrayWithObjects:script,nil];
        STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/bin/sh" arguments:arguments];
        [instTask waitUntilExit];
        int retcode = [instTask terminationStatus];
        NSLog(@"createRemoveFlagFile.sh return: %d", retcode);
        return retcode;
    }
    
    - (BOOL)isExistMovedflagFile
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = @"/Library/Application Support/Lemon/movedFlag";
        BOOL isExist = [fm fileExistsAtPath:path];
        NSLog(@"isExistMovedflagFile %d", isExist);
        return isExist;
    }
    
    - (int)killDaemonAndMonitor
    {
        NSLog(@"kill remove old daemon and monitor");
        NSString *script = [[NSBundle mainBundle] pathForResource:@"killDeamonAndMonitor.sh" ofType:nil];
        NSArray *arguments = [NSArray arrayWithObjects:script,nil];
        STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/bin/sh" arguments:arguments];
        [instTask waitUntilExit];
        int retcode = [instTask terminationStatus];
        NSLog(@"killDaemonAndMonitor return: %d", retcode);
        return retcode;
    }
    
    - (int)copyLemonToApplicationAppPath:(NSString *)srcPath
    {
        NSLog(@"copyLemonToApplication");
        NSString *script = [[NSBundle mainBundle] pathForResource:@"copyLemonToApplication.sh" ofType:nil];
        NSString *appName = [srcPath lastPathComponent];
        NSLog(@"copyLemonToApplication, srcPath:%@, appName:%@", srcPath, appName);
        //srcPath必须要放最后，因为path中间可能会空格，正常sh会将参数从空格分开，这里把srcPath放在最后，copyLemonToApplication.sh接收参数时会将第二个以后后所有参数合成一个参数。
        NSArray *arguments = [NSArray arrayWithObjects:script, srcPath, nil];
        STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/bin/sh" arguments:arguments];
        [instTask waitUntilExit];
        int retcode = [instTask terminationStatus];
        NSLog(@"copyLemonToApplication return: %d", retcode);
        return retcode;
    }
    
    - (int)renameLemonApp:(NSString *)appName {
        NSLog(@"renameLemonApp");
        NSString *script = [[NSBundle mainBundle] pathForResource:@"renameApp.sh" ofType:nil];
        NSLog(@"renameApp.sh, appName:%@ to Tencent Lemon.app", appName);
        NSArray *arguments = [NSArray arrayWithObjects:script, appName, nil];
        STPrivilegedTask *instTask = [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/bin/sh" arguments:arguments];
        [instTask waitUntilExit];
        int retcode = [instTask terminationStatus];
        NSLog(@"renameApp.sh return: %d", retcode);
        return retcode;
    }
    
    - (void)moveUsingShell:(NSString *)selfPath {
        //移动前先杀掉原来的进程，不然如果原来的进程在执行卸载操作可能会把Lemon.app又干掉。
        int ret = [self removeMonitorAndDaemon];
        if (ret == STPrivilegedAuthorizationError) {
            NSLog(@"killDaemonAndMonitor STPrivilegedAuthorizationError");
            exit(0);
            return;
        }
        
        ret = [self createMoveFlagFile];
        if (ret == STPrivilegedAuthorizationError) {
            NSLog(@"createMoveFlagFile STPrivilegedAuthorizationError");
            exit(0);
            return;
        }
        
        ret = [self copyLemonToApplicationAppPath:selfPath];
        if (ret == STPrivilegedAuthorizationError) {
            NSLog(@"copyLemonToApplicationAppPath STPrivilegedAuthorizationError");
            exit(0);
            return;
        }
        
        NSString *appName = [selfPath lastPathComponent];
        if (![appName isEqualToString:@"Tencent Lemon"]){
            ret = [self renameLemonApp:appName];
            if (ret == STPrivilegedAuthorizationError) {
                NSLog(@"copyLemonToApplicationAppPath STPrivilegedAuthorizationError");
                exit(0);
                return;
            }
        }
        
        
    }
    
    - (void)moveUsingFinder:(NSString *)appPath dstPath:(NSString *)dstPath selfPath:(NSString *)selfPath {
        NSAppleScript *script = nil;
        if (![selfPath hasPrefix:appPath])
        {
            NSString *finderPathFormat = [selfPath stringByReplacingOccurrencesOfString:@"/" withString:@":"];
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
            
            NSDictionary * error;
            [script executeAndReturnError:&error];
            NSLog(@"script executeAndReturnError %@", error);
        }
        
        // 是否要重命名
        NSString *strCurAppName = [selfPath lastPathComponent];
        if ([strCurAppName compare:MAIN_APP_NAME options:NSCaseInsensitiveSearch] != NSOrderedSame)
        {
            // rename
            NSString *moveScript = [NSString stringWithFormat:@"tell application \"Finder\"\n"
                                    "set appname to \"%@\"\n"
                                    "set destapp to ((startup disk as text) & \":Applications:%@\") as alias\n"
                                    "set name of destapp to appname\n"
                                    "end tell", MAIN_APP_NAME, strCurAppName];
            script = [[NSAppleScript alloc] initWithSource:moveScript];
            [script executeAndReturnError:nil];
        }
    }
    
    - (void)moveMgrBiz{
        // 先判断自己是否在 Application 目录下，不是则拷贝后再运行
        NSString *selfPath = [[NSBundle mainBundle] bundlePath];
        NSString *appPath = [DEFAULT_APP_PATH stringByDeletingLastPathComponent];// @"/Applications"
        NSString *dstPath = [appPath stringByAppendingPathComponent:MAIN_APP_NAME];
        {
            SInt32 versionMajor=0, versionMinor=0;
            Gestalt(gestaltSystemVersionMajor, &versionMajor);
            Gestalt(gestaltSystemVersionMinor, &versionMinor);
            
            // 尝试kill掉之前的进程
            NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
            NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID];
            for (NSRunningApplication *mainApp in runningApps)
            {
                NSLog(@"kill app %@", mainApp);
                if (mainApp.processIdentifier != currentApp.processIdentifier)
                    [mainApp forceTerminate];
            }
            
            [self moveUsingShell:selfPath];
        }
    }
    - (void)moveMgr
    {
        // 先判断自己是否在 Application 目录下，不是则拷贝后再运行
        NSString *selfPath = [[NSBundle mainBundle] bundlePath];
        if ([selfPath isEqualToString:DEFAULT_APP_PATH])
        {
            return;
        }
        NSString *appPath = [DEFAULT_APP_PATH stringByDeletingLastPathComponent];// @"/Applications"
        NSString *dstPath = [appPath stringByAppendingPathComponent:MAIN_APP_NAME];
        
        NSString *myVer = [LMVersionHelper fullVersionFromBundle:[NSBundle mainBundle]];
        NSString *dstVer = [LMVersionHelper fullVersionFromVersionLogFile];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isExistInApplication = [fm fileExistsAtPath:dstPath];
        BOOL isSameAsInstalledVersion = dstVer == nil ? FALSE:[myVer isEqualToString:dstVer];
        NSLog(@"moveMge, oldVer = %@, newVer = %@", dstVer, myVer);
        NSLog(@"moveMgr selfPath=%@, dstPath=%@\nisExistInApplication:%d, isSameAsInstalledVersion:%d", selfPath, dstPath, isExistInApplication, isSameAsInstalledVersion);
        
        if (!isExistInApplication || !isSameAsInstalledVersion)
        {
            [self moveMgrBiz];
        }
    }
    
    -(void)installLemon {
        NSLog(@"%s", __FUNCTION__);
        
        // 尝试kill掉之前的进程， 这里只能找出并杀死当前登陆用户下的app, 其他用户下也可能有运行的Lemon.app但这里没有权限杀，daemon覆盖安装时会杀一遍。
        NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
        NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID];
        
        for (NSRunningApplication *mainApp in runningApps)
        {
            NSLog(@"%s kill app %@", __FUNCTION__, mainApp);
            if (mainApp.processIdentifier != currentApp.processIdentifier)
                [mainApp forceTerminate];
        }
        
        NSArray *monitorRunningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
        for (NSRunningApplication *monitorApp in monitorRunningApps)
        {
            NSLog(@"%s kill app %@", __FUNCTION__, monitorApp);
            [monitorApp forceTerminate];
        }
                
        //记录安装开始时间
        CFAbsoluteTime timeBegin = CFAbsoluteTimeGetCurrent();
        int installStatus = [PreLaunch copySelfToApplication];
        if (installStatus == STPrivilegedAuthorizationError)
        {
            exit(0);
            return;
        }
        
        // 记录老版本
        NSString *strOldVer = [PreLaunch oldInstalledVersion];
        
        // 开始真实安装,并返回结果,
        installStatus = [PreLaunch startToInstall];
        if (installStatus == STPrivilegedAuthorizationError)
        {
            exit(0);
            return;
        }
        
        if(@available(macOS 10.15, *)){
            if([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized){
            }
        }
    }
    
#pragma mark - monitor
    -(NSInteger)getMonitorCoinfig
    {
        // 迁移老的数据
        NSInteger newType = STATUS_TYPE_LOGO;
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kLemonShowMonitorCfg])
        {
            NSLog(@"%s, %@", __FUNCTION__, @"has no kLemonShowMonitorCfg");
            
            // 不存在旧的配置
            newType = STATUS_TYPE_BOOTSHOW | STATUS_TYPE_LOGO ;
            self.runningType = LemonAppRunningFirstInstall;
            // 保存到新配置中
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:newType] forKey:kLemonShowMonitorCfg];
        }
        else
        {
            NSLog(@"%s, %@", __FUNCTION__, @"has kLemonShowMonitorCfg");
            // 已经存在，以存在的为准
            newType = [[[NSUserDefaults standardUserDefaults] objectForKey:kLemonShowMonitorCfg] integerValue];
        }
        
        if (newType == STATUS_TYPE_BOOTSHOW ||
            newType == STATUS_TYPE_GLOBAL)
        {
            newType = STATUS_TYPE_LOGO;
            newType |= STATUS_TYPE_DISK;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:newType] forKey:kLemonShowMonitorCfg];
        }
        
        // 容错处理如果newType没有选择类型，要默认显示logo
        if ((newType & ~STATUS_TYPE_BOOTSHOW) == 0)
        {
            newType |= STATUS_TYPE_LOGO;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:newType] forKey:kLemonShowMonitorCfg];
        }
        
        return newType;
    }
    
    - (void)keepMonitorAlive
    {
        //
        [self getMonitorCoinfig];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
            if (runningApps.count == 0)
            {
                NSLog(@"keepMonitorAlive load monitor");
                NSArray *params = @[[NSString stringWithFormat:@"%d", (int)self.runningType]];
                
                NSRunningApplication *app = nil;
                NSError *error = NULL;
                //防止安装copymonitor未完成时无法正常启动的情况
                int count = 0;
                while (app == nil) {
                    app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:MONITOR_APP_PATH]
                                                                        options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation
                                                                  configuration:@{NSWorkspaceLaunchConfigurationArguments: params}
                                                                          error:&error];
                    NSLog(@"open lemon monitor: %@, %@", app, error);
                    sleep(1);
                    if (count > 100) {
                        break;
                    }
                    count++;
                }
            }
        });
    }
    
#pragma mark - lemon menu
    - (BOOL)hasNewVersion{
        NSBundle *mainAppBundle = [NSBundle bundleWithPath:[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]];
        NSString *myVer = [[mainAppBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersionInfo];
        NSString *strNewVersion = [versionInfo objectForKey:@"version"];
        if (myVer && [strNewVersion compareVersion:myVer])
        {
            //has new version
            return YES;
        } else {
            return NO;
        }
    }
    
    - (IBAction)update:(id)sender {
        NSLog(@"installLemon");
        
        CFPreferencesAppSynchronize((__bridge CFStringRef)(MONITOR_APP_BUNDLEID));
        NSString *strNewVersion = (__bridge_transfer NSString *)CFPreferencesCopyAppValue((__bridge CFStringRef)(kLemonNewVersion), (__bridge CFStringRef)(MONITOR_APP_BUNDLEID));
        if (strNewVersion) {
            CFPreferencesSetAppValue((__bridge CFStringRef)(kIgnoreLemonNewVersion), (__bridge CFStringRef)strNewVersion, (__bridge CFStringRef)(MONITOR_APP_BUNDLEID));
            CFPreferencesAppSynchronize((__bridge CFStringRef)(MONITOR_APP_BUNDLEID));
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString * bundlePath = [[NSBundle mainBundle] bundlePath];
            NSLog(@"update bundlePath=%@", bundlePath);
            NSString *updatePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Frameworks"];
            updatePath = [updatePath stringByAppendingPathComponent:UPDATE_APP_NAME];
            NSArray *arguments = @[];
            if ([self hasNewVersion]) {
                NSDictionary *versionInfo = (__bridge_transfer NSDictionary *)CFPreferencesCopyAppValue((__bridge CFStringRef)(kLemonNewVersionInfo), (__bridge CFStringRef)(MONITOR_APP_BUNDLEID));
            }
            NSLog(@"installLemon: %@, %@", updatePath, arguments);
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:updatePath]
                                                          options:NSWorkspaceLaunchWithoutAddingToRecents
                                                    configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
                                                            error:NULL];
        });
    }
    
    - (void)lemonPeferenceShow {
        if (!self.prefWindowController) {
            self.prefWindowController = [[PreferenceWindowController alloc] init];
        }
        [NSApp activateIgnoringOtherApps:YES];
        [self.prefWindowController.window  makeKeyAndOrderFront:nil];
    }
    
    - (IBAction)lemonPeference:(id)sender {
        
        [self lemonPeferenceShow];
    }
    
    - (IBAction)lemonOpenTray:(id)sender {
        
        NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID];
        if (runningApps.count == 0)
        {
            NSLog(@"lemonOpenTray open monitor");
            NSError *error = NULL;
            NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:MONITOR_APP_PATH]
                                                                                      options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation
                                                                                configuration:@{NSWorkspaceLaunchConfigurationArguments: @[[NSString stringWithFormat:@"%lu", LemonMonitorRunningMenu]]}
                                                                                        error:&error];
            NSLog(@"open lemon monitor: %@, %@", app, error);
        }
    }
    - (IBAction)collectLemonLogInfoAction:(id)sender {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *homeDir = [NSString getUserHomePath];
            [[McCoreFunction shareCoreFuction] collectLemonLogInfo:homeDir];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *homeDir = [NSString getUserHomePath];
            NSString *strPath = [homeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@/lemonLogInfoTemp", MAIN_APP_BUNDLEID]];
            NSLog(@"strPath: %@", strPath);
            [[NSWorkspace sharedWorkspace] openFile:strPath withApplication:@"Finder"];
            //[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:strPath]];
        });
    }
#else
    
#pragma mark - menu
    - (void)addStatusItem{
        
        //获取系统单例NSStatusBar对象
        NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
        
        NSStatusItem *statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
        
        self.statusItem = statusItem;
        
        [statusItem setTarget:self];
        [statusItem setAction:@selector(openMainApp)];
        //    [statusItem setHighlightMode:YES];
        [statusItem setImage: [NSImage imageNamed:@"tray_icon"]]; //设置图标，请注意尺寸
        [statusItem.image setTemplate:YES];
    }
    
    -(void)openMainApp{
        //NSLog(@"openMainApp: %@", [[NSBundle mainBundle] bundlePath]);
        [[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle mainBundle] bundlePath]];
    }
    
#pragma mark NSUserNotificationCenterDelegate
    - (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
    {
        
    }
    
    - (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[notification.userInfo objectForKey:@"URL"]]];
    }
    
    - (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
        
    }
    
    - (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
    {
        return YES;
    }
#endif
    
#pragma mark - menu
    - (IBAction)about:(id)sender {
        //    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"open_about" object:nil userInfo:nil deliverImmediately:YES];
        if (_aboutWC)
        {
            [_aboutWC.window makeKeyAndOrderFront:nil];
            return;
        }
        
        NSWindow* windowAbout = [LMAboutWindow windowWithVersionDate:self.versionDate];
        _aboutWC = [[NSWindowController alloc] initWithWindow:windowAbout];
        [windowAbout center];
        [_aboutWC.window makeKeyAndOrderFront:nil];
    }
    
    - (IBAction)feedback:(id)sender {
        
        if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
            return;
        }
#ifndef APPSTORE_VERSION
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
#else
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/52728"]];
#endif
    }
    
    -(IBAction)asPrefrecesSet:(id)sender{
        //    NSLog(@"偏好设置");
        
        if (!self.prefWindowController) {
            self.prefWindowController = [[PreferenceWindowController alloc] init];
        }
        [NSApp activateIgnoringOtherApps:YES];
        [self.prefWindowController.window  makeKeyAndOrderFront:nil];
    }
    
    - (IBAction)lemonOpenPrivacyPolicy:(id)sender {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kQMPrivacyLicenseLink]];
    }
    
#pragma mark - log
    -(void)redirctNSlog{
        NSLog(@"Appdelegate -> redirctNSlog ...");
        NSString *logPath;
        NSString *logName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
        
        // do not redirect in test mode
        if ([[[NSBundle mainBundle] executablePath] containsString:@"/Library"])
            return;
        
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
    
    
    
    @end
