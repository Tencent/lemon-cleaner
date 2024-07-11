//
//  LMMonitorController.m
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMMonitorController.h"
#import "QMValueHistory.h"
#import "QMStatusMonitorView.h"
#import "LMMonitorPoppverController.h"
#import <CoreFoundation/CFPreferences.h>
#import <CoreFoundation/CFBase.h>

#import <QMCoreFunction/QMEnvironmentInfo.h>
#import "LMVisibleViewController.h"

#import "McStatMonitor.h"
#import <QMCoreFunction/McProcessInfoData.h>

#import <LemonStat/McDiskInfo.h>
#import "LMSystemFeatureViewController.h"
#import "LMMonitorTrashManager.h"
#import "QMDragEffectView.h"

#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <PrivacyProtect/OwlWindowController.h>
#import <LemonHardware/LemonHardwareWindowController.h>
#import <LemonHardware/MachineModel.h>
#import <LemonUninstaller/AppTrashDel.h>
#import "LMHardWareDataUtil.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import <LemonHardware/DiskModel.h>
#include <sys/sysctl.h>

// 常量
#import "QMDataConst.h"
#import "LemonDaemonConst.h"
#import "McStatInfoConst.h"

#define USER_LANGUAGE_CHANGE @"user_language_change"
#define kLMMonitorControllerTip @"kLMMonitorControllerTip"

enum
{
    QMBubbleTips,
    QMBubbleMiniFloat,
    QMBubbleMiniStatus
};

@interface NSStatusBar (Private)
- (id)_statusItemWithLength:(double)fp8 withPriority:(int)fp12;
@end


@interface LMMonitorController ()<ToolCongireDelegate, QMWindowDelegate>
{
    // 上传下载速度历史
    QMValueHistory *_upSpeedHistory;
    QMValueHistory *_downSpeedHistory;
    //配置存储
    QMDataCenter *dataCenter;
    
    QMStatusMonitorView *statusView;
    
    NSImageView *menubarNetworkIcon;
    
    //管理各种弹框
    LMMonitorPoppverController *_popover;
    
    // 当前上传下载速度
    float _upSpeed;
    float _downSpeed;
    
    NSUInteger _lastSelectedTabIndex;
    QMEffectMode showMode;
    BOOL _isUserChangeLanguage;
    NSInteger _statusInitType;
    
    DiskModel *diskModel;
}

@property (nonatomic, strong) OwlWindowController *owlController;
@property (nonatomic, strong) LemonHardwareWindowController *hardwareController;
@property (nonatomic, strong) NSString *mainDiskName;
@property NSTimer *checkFullDiskAccessTimer;
@property(nonatomic, strong) NSTimer *timer;

@end

@implementation LMMonitorController


- (id)init
{
    self = [super init];
    if (self) {
        [self setupData];
        [self loadWindow];
        _isUserChangeLanguage = NO;
    }
    return self;
}

-(void)setupData
{
    _upSpeedHistory = [[QMValueHistory alloc] initWithCapacity:32];
    _downSpeedHistory = [[QMValueHistory alloc] initWithCapacity:32];
    dataCenter = [QMDataCenter defaultCenter];
    if ([dataCenter stringForKey:QMMonitorShowNetworkKey].length == 0) {
        [dataCenter setBool:YES forKey:QMMonitorShowNetworkKey];
    }
    
}

- (void)loadWindow {
    
    // 不需要配置 window
    //    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 340, 435)
    //                                              styleMask:NSWindowStyleMaskTitled
    //                   | NSWindowStyleMaskClosable
    //                   | NSWindowStyleMaskMiniaturizable
    //                   | NSWindowStyleMaskFullSizeContentView
    //                                                backing:NSBackingStoreBuffered defer:YES];
    //    [self.window setTitleVisibility:NSWindowTitleVisible];
    //    self.window.titlebarAppearsTransparent = YES;
    //    self.window.movableByWindowBackground = NO;
    //    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    //    [self.window setLevel:NSStatusWindowLevel+2];
    //    [self.window setIgnoresMouseEvents:YES];
    //    [self.window setAcceptsMouseMovedEvents:YES];
    //    [self.window setOpaque:NO];
    //    [self.window setHasShadow:NO];
    //    [self.window setBackgroundColor:[NSColor clearColor]];
    
    [self windowDidLoad];
}


// mark: notification : 交换数据: view 相关
-(void)setupViewNotification
{
    // NSWorkspaceActiveSpaceDidChangeNotification :Posted when a Spaces change has occurred.  用户的 workspace 变化?
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(activeSpaceDidChange:)
                                                               name:NSWorkspaceActiveSpaceDidChangeNotification
                                                             object:nil];
    
    // 这个通知的 发送者是: ->QMBubble
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitiorDismiss:) name:QMMonitorDismiss object:nil];
    
    // NSDistributedNotificationCenter 进程间通知
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receivedStatusChanged:)
                                                            name:kStatusChangedNotification
                                                          object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(receiveDarkModeChanged:)
                                                            name:LMAppleInterfaceThemeChangedNotification
                                                          object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(configureMenuBarForDarkModeChange) name:LMAppleInterfaceThemeChangedNotification object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(userChangeLanguage:)
                                                            name:USER_LANGUAGE_CHANGE
                                                          object:nil];
}

// mark: notification : 交换数据: system info 相关
- (void)setupSystemInfoNotification {
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedRAMInfoChanged:)
                                                 name:kMemoryCPUInfoNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNetworkInfoChanged:)
                                                 name:kNetworkInfoNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTempCpuInfoChanged:)
                                                 name:kTempCpuInfoNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedSensorError:)
                                                 name:@"SensorError"
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(receivedDiskInfoChanged:)
//                                                 name:kDiskInfoNotification
//                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFanCpuInfoChanged:)
                                                 name:kFanCpuInfoNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(receivedCPUInfoChanged:)
                                                    name:kStatCPUInfoNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(receivedGpuInfoChanged:)
                                                    name:kStatGpuInfoNotification
                                                  object:nil];
}

- (void)dealloc
{
    NSLog(@"%s,dealloc---",__FUNCTION__);
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setupViews];
    [self setupViewNotification];
    [self startTrashScan];
    [self startTimerToUpdateDiskInfo];
}


-(void)setupViews
{
    [self setupStatusItem];
    [self configureMenuBarForDarkModeChange];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.timer && [MachineModel isLiquidScreen]) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(processAnimate) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)processAnimate {
    BOOL alreadyTip = [[NSUserDefaults standardUserDefaults] boolForKey:kLMMonitorControllerTip];
    
    if (!(statusView.window.occlusionState & NSApplicationOcclusionStateVisible) && (alreadyTip == NO)) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLMMonitorControllerTip];
        [self alert];
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}

- (void)alert
{
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"beObscured", nil, [NSBundle bundleForClass:[self class]], @"")];
    if (statusView.statusNum <= 1) {
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel_Tip", nil, [NSBundle mainBundle], @"")];
    } else {
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OK_Tip", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel_Tip", nil, [NSBundle mainBundle], @"")];
    }
    
    NSModalResponse result = [alert runModal];
    if (statusView.statusNum > 1) {
        if (result == 1000) {
            if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count == 0)
            {
                NSArray *arguments = @[[NSString stringWithFormat:@"2"]];
                [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:DEFAULT_APP_PATH]
                                                              options:NSWorkspaceLaunchWithoutAddingToRecents
                                                        configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
                                                                error:NULL];
            }
            else
            {
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kShowPreferenceWindow
                                                                               object:nil
                                                                             userInfo:nil
                                                                   deliverImmediately:YES];
            }
        }
    }
}

-(void)setupStatusItem
{
    // 状态栏 view 和状态栏 item
    statusView = [[QMStatusMonitorView alloc] initWithFrame:NSMakeRect(0, 0, 22, 22)];
    [statusView awakeFromNib];
    __weak LMMonitorController *blockSelf = self;
    statusView.mouseDownBlock = ^{   // 设置状态栏 view 的 mouse 事件
        __strong LMMonitorController *sself = blockSelf;
        if (sself) {
            [sself setupPopover];
            sself->_popover.statusItem = sself.statusItem; //statusItem 赋值给其它模块
            if(sself->_popover.bubbleWindow.isVisible){
                [sself->_popover dismissPopover];
            }else{
                [[McStatMonitor shareMonitor] setIsTrayPageOpen:YES];
                [sself->_popover showPopover];
            }
        }
    };
    // 读取配置(从主 app中同步配置)
    CFPreferencesAppSynchronize((__bridge CFStringRef)(MAIN_APP_BUNDLEID));
    NSNumber *type = (__bridge_transfer NSNumber *)CFPreferencesCopyAppValue((__bridge CFStringRef)(kLemonShowMonitorCfg), (__bridge CFStringRef)(MAIN_APP_BUNDLEID));
    _statusInitType = type.integerValue;
    NSLog(@"%s type:is %lu", __FUNCTION__, [type longValue]);
    
    //MARK: 如果先添加View会触发一个BUG：部分11.0系统上状态栏的logo是灰色的
//    [statusView setStatusType:type.integerValue];

    if (!_statusItem)
    {
        // 对于statusItem对于的 view的宽度可变的情况, 需要设置其statusItemWithLength为NSVariableStatusItemLength, 否则在 10.11 系统上, 当更改statusView的frame 时,statusItem显示不正常.
        NSStatusBar * statusBar = [NSStatusBar systemStatusBar];
        if ([statusBar respondsToSelector:@selector(_statusItemWithLength:withPriority:)]){
            _statusItem = [statusBar _statusItemWithLength:NSVariableStatusItemLength withPriority:USHRT_MAX - 1];
            NSLog(@"NSStatusBar setup with _statusItemWithLength:withPriority: method ");
        }else{
            _statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
        }
        
        [_statusItem setTitle:@""];
        [_statusItem setToolTip:@""];
        [_statusItem setView:statusView];
    }
    [statusView setStatusType:type.integerValue];
    
}

-(void)userChangeLanguage:(NSNotification *)notification{
    NSLog(@"userChangeLanguage  _popover set to nil ");
    _isUserChangeLanguage = YES;
    //hook monitor多语言
    NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
    if(languageString != nil){
        [NSBundle setLanguage:languageString bundle:[NSBundle mainBundle]];
    }
    //    NSLog(@"start to hook 删除软件弹窗");
    if(languageString != nil){
        NSLog(@"middle to hook language string = %@", languageString);
        [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[AppTrashDel class]]];
    }
    //    NSLog(@"end to hook 删除软件弹框");
    //    [self setupPopover];
    //    self->_popover.statusItem = self->statusItem;
    if (self.owlController != nil) {
        [self.owlController close];
    }
    if (self.hardwareController != nil) {
        [self.hardwareController close];
    }
}

-(void)startTrashScan
{
    [[LMMonitorTrashManager sharedManager] startTrashScan];
}


// mark: 暗黑模式/非暗黑模式时 显示 状态栏图标
- (void)configureMenuBarForDarkModeChange
{
    NSString *imageName = nil;
    if ([QMEnvironmentInfo isDarkMode]) {
        imageName = @"status_network_traffic_dark";
    } else {
        imageName = @"status_network_traffic";
    }
    menubarNetworkIcon.image = [[NSBundle bundleForClass:self.class] imageForResource:imageName];
}

- (void)monitiorDismiss:(NSNotification *)notification
{
    __weak LMMonitorController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!weakSelf.isShow) {
        }
    });
}

//  当使用Multiple Desktops,并且 DeskTop 切换的时候调用
- (void)activeSpaceDidChange:(NSNotification *)notification
{
    //监控窗口隐藏或关闭情况下不做任何处理
    if ([dataCenter boolForKey:kQMMonitorClosed] || [dataCenter integerForKey:kQMMonitorShowMode] == QMEffectStatusMode)
    {
        return;
    }
    
    // 获取多个桌面
    //    NSArray *windowsInSpace = (__bridge_transfer NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionAll|kCGWindowListOptionOnScreenAboveWindow, kCGNullWindowID);
}

- (LMMonitorPoppverController *)setupPopover
{
    if(_isUserChangeLanguage){
        _isUserChangeLanguage = NO;
        _popover = nil;
    }
    if(_popover == nil){
        if(_popover != nil){
            LMSystemFeatureViewController *networkVC = _popover.systemFeatureViewController;
            networkVC.delegate = nil;
        }
        //hook monitor多语言
        NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
        if(languageString != nil){
            [NSBundle setLanguage:languageString bundle:[NSBundle mainBundle]];
        }
        //用于显示弹窗
        _popover = [[LMMonitorPoppverController alloc] init];
        _popover.statusView = statusView;
        _popover.diskModel = diskModel;
        
        LMSystemFeatureViewController *networkVC = _popover.systemFeatureViewController;
        networkVC.upSpeedHistory = _upSpeedHistory;
        networkVC.downSpeedHistory = _downSpeedHistory;
        networkVC.upSpeed = _upSpeed;
        networkVC.downSpeed = _downSpeed;
        networkVC.delegate = self;
        [_popover.tabViewController setTabIndex:_lastSelectedTabIndex];
        _popover.dismissCompletion = nil;
    }
    
    return _popover;
}

// 加载时调用，读取配置并显示浮窗
- (void)load
{
    NSLog(@"LMMonitorController load enter");
    
    //    BOOL monitorClosed = [dataCenter boolForKey:kQMMonitorClosed];
    //    if (monitorClosed)
    //        return;
    [self show];
}

- (void)show
{
    NSLog(@"LMMonitorController show enter");
    
    [self setupSystemInfoNotification];
    [[McStatMonitor shareMonitor] setTrayType:_statusInitType];
    _isShow = YES;
    [[McStatMonitor shareMonitor] startRunMonitor];
}


- (void)dismiss
{
    [_popover dismissPopover];
    //注销RAM信息的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMemoryCPUInfoNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNetworkInfoNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTempCpuInfoNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"SensorError"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDiskInfoNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatCPUInfoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStatGpuInfoNotification object:nil];
    
    [[McStatMonitor shareMonitor] stopRunMonitor];
    [dataCenter setBool:YES forKey:kQMMonitorClosed];
    
    //关闭界面
    if (_statusItem)
    {
        [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
        _statusItem = nil;
    }
    _isShow = NO;
}


// mark: notification
///收到RAM改变的通知
- (void)receivedRAMInfoChanged:(NSNotification *)notify
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //从通知信息中读取内存区域，第一个值为FreeSize
        NSArray *memInfo = [(NSDictionary *)notify.object objectForKey:@"SizeArray"];
        uint64_t totalSize = [memInfo[4] unsignedLongLongValue];
        uint64_t usedSize = totalSize - [memInfo[5] unsignedLongLongValue];
        double usedRate = usedSize*1.0/totalSize;
        
        //做释放结束的动画
        //        if (round(floatView.ramUsed*100) != round(usedRate*100))
        //            floatView.ramUsed = usedRate;
        if (round(statusView.ramUsed*100) != round(usedRate*100))
            statusView.ramUsed = usedRate;
    });
}

///收到网络改变的通知
- (void)receivedNetworkInfoChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float upSpeed = [[notification.object objectForKey:@"UpSpeed"] floatValue];
        float downSpeed = [[notification.object objectForKey:@"DownSpeed"] floatValue];
        _upSpeed = upSpeed;
        _downSpeed = downSpeed;
        
        [_upSpeedHistory feed:@(upSpeed)];
        [_downSpeedHistory feed:@(downSpeed)];
        [statusView setUpSpeed:upSpeed];
        [statusView setDownSpeed:downSpeed];
    });
}

// cpu temp&fanspeed
-(void)receivedTempCpuInfoChanged:(NSNotification *)notification
{
    NSDictionary* dict = notification.object;
    double tempCpu = [[dict objectForKey:@"CpuTemp"] doubleValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusView setTemperatureValue:tempCpu];
    });
}

-(void)receivedFanCpuInfoChanged:(NSNotification *)notification{
    NSDictionary* dict = notification.object;
    float fanSpeed  = 0;
    NSArray* arrayFans = [dict objectForKey:@"fanArray"];
    if (arrayFans && arrayFans.count > 0) {
        for (NSDictionary*dictFan in arrayFans)
        {
            float speed = [[dictFan objectForKey:@"fanSpeed"] floatValue];
            if (speed > fanSpeed)
            {
                fanSpeed = speed;
            }
        }
        //        NSDictionary* dictFan1 = arrayFans[0];
        //        fanSpeed = [[dictFan1 objectForKey:@"fanSpeed"] floatValue];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusView setFanSpeedValue:fanSpeed];
    });
}

-(void)startTimerToUpdateDiskInfo{
    diskModel = [[DiskModel alloc]init];
    [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateDiskInfo) userInfo:nil repeats:YES] fire];
}

-(void)updateDiskInfo{
    [diskModel.diskZoneArr removeAllObjects];
    [diskModel getHardWareInfo];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    NSArray *diskInfo = diskModel.diskZoneArr;
    for (DiskZoneModel *zoneModel in diskInfo) {
//            NSLog(@"%s, zoneMode Info : %@", __FUNCTION__, zoneModel);
        if(zoneModel.isMainDisk){
            
            uint64_t usedBytes = zoneModel.maxSize - zoneModel.leftSize;
            if (zoneModel.maxSize > 0)
            {
                double useRate = usedBytes*1.0/zoneModel.maxSize;
                [dict setObject:@(usedBytes) forKey:@"used"];
                [dict setObject:@(zoneModel.maxSize) forKey:@"total"];
//                    NSLog(@"useRate : %f", useRate);
                [statusView setDiskUsed:useRate];
                break;
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_DISK_INFO object:dict];
}

// disk info
-(void)receivedDiskInfoChanged:(NSNotification *)notification
{
    NSDictionary* dict = notification.object;
    if (dict)
    {
        uint64_t freeBytes = 0;
        uint64_t usedBytes = 0;
        uint64_t totalBytes = 0;
        NSArray * volumnesArray = dict[@"Volumnes"];
        [LMHardWareDataUtil calculateDiskUsageInfoWithMainDiskName:self.mainDiskName volumeArray:volumnesArray freeBytes:&freeBytes totalBytes:&totalBytes];
//        NSLog(@"DiskInfo--%s-- freeBytes:%llul, totalBytes:%llul",__FUNCTION__,freeBytes,totalBytes);
       
        usedBytes = totalBytes - freeBytes;
        if (totalBytes > 0)
        {
            double useRate = usedBytes*1.0/totalBytes;
            [statusView setDiskUsed:useRate];
        }
        
    }

}

-(void)receivedSensorError:(NSNotification *)notification
{
    NSString* AlgType = (NSString*)notification.object;
}

-(void)receivedStatusChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger type = 0;
        NSDictionary* dict = notification.userInfo;
        type = ((NSNumber*)dict[@"type"]).integerValue;
        [statusView setStatusType:type];
        [[McStatMonitor shareMonitor] setTrayType:type];
//        NSLog(@"receivedStatusChanged type=%lu", type);
    });
    
}

-(void)receiveDarkModeChanged:(NSNotification *)notification {
    [statusView onDarkModeChange];
}

-(void)receivedCPUInfoChanged:(NSNotification *)notification {
    double cpuUsage = [[(NSDictionary *)notification.object objectForKey:@"CpuUsage"] doubleValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusView setCpuUsed:cpuUsage];
    });
    
}

-(void)receivedGpuInfoChanged:(NSNotification *)notification {
    double cpuUsage = [[(NSDictionary *)notification.object objectForKey:@"usage"] doubleValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusView setGpuUsed:cpuUsage];
    });
    
}

#pragma mark -- ToolCongureDelegate
-(QMBaseWindowController *)getControllerByClassName:(NSString *)clsName{
    QMBaseWindowController *controller = nil;
    if ([clsName isEqualToString:@"OwlWindowController"]) {
        //hook owl多语言
        NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
        if(languageString != nil){
            [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[OwlWindowController class]]];
        }
        if(self.owlController == nil){
            self.owlController = [[OwlWindowController alloc] init];
            self.owlController.delegate = self;
        }
        controller = self.owlController;
    }
        
    if ([clsName isEqualToString:@"LemonHardwareWindowController"]) {
        if(self.hardwareController == nil){
            self.hardwareController = [[LemonHardwareWindowController alloc] init];
            self.hardwareController.delegate = self;
        }
        controller = self.hardwareController;
    }
    
    return controller;
}

-(void)windowWillDismiss:(NSString *)clsName{
    if ([clsName isEqualToString:@"OwlWindowController"]) {
        self.owlController = nil;
    }
        
    if ([clsName isEqualToString:@"LemonHardwareWindowController"]) {
        self.hardwareController = nil;
    }
}

@end
