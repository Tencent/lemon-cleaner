//
//  OwlViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlViewController.h"
#import <QMUICommon/COSwitch.h>
#import "OwlWindowController.h"
#import "OwlLogViewController.h"
#import "OwlWhiteListViewController.h"
#import "Owl2Manager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import "QMUserNotificationCenter.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LemonDaemonConst.h"
#import "OwlNotificationPermissionViewController.h"
#import <QMCoreFunction/LMReferenceDefines.h>
#import <QMUICommon/LMTitleButton.h>
#import "owl2deviceprotectionswitchview.h"
#import "NSAlert+OwlExtend.h"

@interface OwlBorderView : NSView

@end

@implementation OwlBorderView
- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
}
@end

@interface OwlContentView : NSVisualEffectView

@end

@implementation OwlContentView
- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
}
@end


@interface OwlViewController () <NSUserNotificationCenterDelegate, Owl2DeviceProtectionSwitchDelegate>
@property (nonatomic, strong) NSView *loadingView;
@property (nonatomic, strong) NSView *ccView;
@property (nonatomic, strong) NSButton *wlistBtn;
@property (nonatomic, strong) OwlContentView *bottomBgView;

@property (nonatomic, strong) Owl2DeviceProtectionSwitchView *videoSwitchView;

@property (nonatomic, strong) Owl2DeviceProtectionSwitchView *audioSwitchView;

@property (nonatomic, strong) Owl2DeviceProtectionSwitchView *screenSwitchView;

@end

@implementation OwlViewController

- (NSView*)buildBoxView{
    NSView *view = [[NSView alloc] init];
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.borderColor = [NSColor colorWithWhite:0.94 alpha:1].CGColor;
    borderLayer.borderWidth = 0;
    borderLayer.cornerRadius = 4;
    view.layer = borderLayer;
    return view;
}
- (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentCenter;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    return labelTitle;
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        OwlContentView *containView = [[OwlContentView alloc] initWithFrame:frame];
        _loadingView = [[NSView alloc] initWithFrame:frame];
        _ccView = [[NSView alloc] initWithFrame:frame];
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        _ccView.layer = layer;
        self.view = containView;
        if ([Owl2Manager sharedManager].isFetchDataFinish) {
            [self setFinishUI:frame];
        } else {
            [self setLoadingUI:frame];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteListChange:) name:OwlWhiteListChangeNotication object:nil];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:@"OwlVideoCheckOnceNotification"];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:@"OwlAudioCheckOnceNotification"];
        
        //NSTableView
    }
    return self;
}

- (void)viewWillAppear {
    [super viewWillAppear];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.ccView];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.wlWindowController) {
        [self.wlWindowController close];
        self.wlWindowController = nil;
    }
    if (self.logWindowController) {
        [self.logWindowController close];
        self.logWindowController = nil;
    }
}
- (void)removeNotifyDelegate{
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:@"OwlVideoCheckOnceNotification" flagsBlock:nil];
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:@"OwlAudioCheckOnceNotification" flagsBlock:nil];
}

// 一键开启
- (void)oneClick {
    Owl2Manager *owl2Manager = [Owl2Manager sharedManager];
    
    if (!owl2Manager.isWatchAudio) {
        self.audioSwitchView.config.on = YES;
        [self owl2DeviceProtectionSwitchValueDidChange:self.audioSwitchView.config];
        [self.audioSwitchView updateUI];
    }
    
    if (!owl2Manager.isWatchVideo) {
        self.videoSwitchView.config.on = YES;
        [self owl2DeviceProtectionSwitchValueDidChange:self.videoSwitchView.config];
        [self.videoSwitchView updateUI];
    }
    
    if (!owl2Manager.isWatchScreen) {
        self.screenSwitchView.config.on = YES;
        [self owl2DeviceProtectionSwitchValueDidChange:self.screenSwitchView.config];
        [self.screenSwitchView updateUI];
    }
}

- (void)whiteListChange:(NSNotification*)no{
    _wlistBtn.title = [NSString stringWithFormat:LMLocalizedSelfBundleString(@"白名单（%lu）", nil), (unsigned long)[Owl2Manager sharedManager].wlDic.count];
}

- (void)setLoadingUI:(NSRect)frame{
    NSLog(@"owl setLoadingUI");
    [self.ccView removeFromSuperview];
    [self.view addSubview:self.loadingView];
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc] init];
    indicator.style = NSProgressIndicatorStyleSpinning;
    [_loadingView addSubview:indicator];
    NSTextField *loadingLabelSpec = [self buildLabel:LMLocalizedSelfBundleString(@"正在初始化数据...", nil) font:[NSFont systemFontOfSize:18]color:[NSColor lightGrayColor]];
    loadingLabelSpec.backgroundColor = [NSColor clearColor];
    [_loadingView addSubview:loadingLabelSpec];
    [indicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.centerY.equalTo(self.loadingView).offset(-20);
        make.width.height.equalTo(@48);
    }];
    [loadingLabelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.centerY.equalTo(self.loadingView).offset(20);
    }];
    
    [indicator startAnimation:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (![Owl2Manager sharedManager].isFetchDataFinish)
        {
            sleep(1);
            [[Owl2Manager sharedManager] loadOwlDataFromMonitor];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setFinishUI:frame];
            [indicator stopAnimation:nil];
        });
    });
}

- (void)setFinishUI:(NSRect)frame{
    NSLog(@"owl setFinishUI");
    [self.loadingView removeFromSuperview];
    [self.view addSubview:self.ccView];
    
    NSTextField *labelTitle = [self buildLabel:LMLocalizedSelfBundleString(@"设备隐私保护", nil) font:[NSFont systemFontOfSize:32]color:[LMAppThemeHelper getTitleColor]];
    labelTitle.backgroundColor = [NSColor clearColor];
    [self.ccView addSubview:labelTitle];

    NSFont *origFont = [NSFont systemFontOfSize:32];
    NSFontDescriptor* origDescriptor = origFont.fontDescriptor;
    NSFontDescriptor* newDescriptor = [origDescriptor fontDescriptorByAddingAttributes:@{ NSFontTraitsAttribute: @{ NSFontWeightTrait: @(0.0) } }];
    NSFont* newFont = [NSFont fontWithDescriptor:newDescriptor size:origFont.pointSize];
    [labelTitle setFont:newFont];
    
    [self.ccView addSubview:self.videoSwitchView];
    [self.ccView addSubview:self.audioSwitchView];
    [self.ccView addSubview:self.screenSwitchView];
    
    self.bottomBgView = [[OwlContentView alloc] init];
    [self.ccView addSubview:self.bottomBgView];
    
    NSView *bLineview = [[NSView alloc] init];
    CALayer *lineLayer = [[CALayer alloc] init];
    lineLayer.backgroundColor = [NSColor colorWithWhite:0.87 alpha:1].CGColor;
    bLineview.layer = lineLayer;
    [self.bottomBgView addSubview:bLineview];
    
    NSButton *logBtn = [[NSButton alloc] init];
    logBtn.title = LMLocalizedSelfBundleString(@"监控日志", nil);
    [logBtn setButtonType:NSButtonTypeMomentaryChange];
    logBtn.target = self;
    logBtn.action = @selector(clickLogBtn:);
    logBtn.bordered = NO;
    logBtn.font = [NSFont systemFontOfSize:12];
    [self.bottomBgView addSubview:logBtn];
    
    _wlistBtn = [[NSButton alloc] init];
    _wlistBtn.title = [NSString stringWithFormat:LMLocalizedSelfBundleString(@"白名单（%lu）", nil), (unsigned long)[Owl2Manager sharedManager].wlDic.count];
    [_wlistBtn setButtonType:NSButtonTypeMomentaryChange];
    _wlistBtn.target = self;
    _wlistBtn.action = @selector(clickWlistBtn:);
    _wlistBtn.bordered = NO;
    _wlistBtn.font = [NSFont systemFontOfSize:12];
    [self.bottomBgView addSubview:_wlistBtn];
    
    @weakify(self);
    [self getNotificationPermissionGrantedWithCompletionHandler:^(BOOL isAuthorized) {
        @strongify(self);
        if (isAuthorized) {
            return;
        }
        NSTextField *notificationTipLabel = [self buildLabel:LMLocalizedSelfBundleString(@"请开启通知权限以接收隐私保护提示", nil) font:[NSFontHelper getLightSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        notificationTipLabel.backgroundColor = [NSColor clearColor];
        
        LMTitleButton *detailBtn = [[LMTitleButton alloc] initWithFrame:NSMakeRect(0, 0, 58, 20)];
        [detailBtn setBezelStyle:NSBezelStylePush];
        detailBtn.bordered = NO;
                
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [LMAppThemeHelper getColor:LMColor_Blue_Normal]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"查看详情", nil) attributes:attributes];
        [detailBtn setAttributedTitle:attributedTitle];
        [detailBtn setTarget:self];
        [detailBtn setAction:@selector(detailBtnClicked:)];
        
        NSStackView *stackView = [NSStackView stackViewWithViews:@[notificationTipLabel, detailBtn]];
        stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        stackView.spacing = 0;
        [self.ccView addSubview:stackView];
        
        [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(0);
            make.bottom.mas_equalTo(self.bottomBgView.mas_top).offset(-24);
        }];
    }];
    
    int space = 10;
    [labelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.ccView.mas_top).offset(OwlWindowTitleHeight + 6);
        make.left.right.mas_equalTo(self.ccView);
    }];
    [self.videoSwitchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(labelTitle.mas_bottom).offset(33);
        make.left.mas_equalTo(52);
        make.size.mas_equalTo(NSMakeSize(220, 220));
    }];
    [self.audioSwitchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(labelTitle.mas_bottom).offset(33);
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(220, 220));
    }];
    [self.screenSwitchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(labelTitle.mas_bottom).offset(33);
        make.right.mas_equalTo(-52);
        make.size.mas_equalTo(NSMakeSize(220, 220));
    }];
    [self.bottomBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoSwitchView.mas_bottom).offset(60);
        make.bottom.equalTo(self.ccView);
        make.left.right.equalTo(self.ccView);
    }];
    [logBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(self.ccView.mas_left).offset(space*3);
    }];
    [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(logBtn.mas_right).offset(space/2);
        make.height.equalTo(@10);
        make.width.equalTo(@1);
    }];
    [_wlistBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(logBtn.mas_right).offset(space+1);
    }];
    NSLog(@"owl setFinishUI end");
}


- (void)showToastForFirst:(BOOL)isVedio{
    BOOL isShow = NO;
    if (isVedio) {
        NSString *strFirst = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonVedioFirstUsing"];
        if (!strFirst) {
            isShow = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@"strFirst" forKey:@"kLemonVedioFirstUsing"];
        }
    } else {
        NSString *strFirst = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonAudioFirstUsing"];
        if (!strFirst) {
            isShow = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@"strFirst" forKey:@"kLemonAudioFirstUsing"];
        }
    }
    if (isShow) {
        NSLog(@"showToastForFirst");
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title =  isVedio ? LMLocalizedSelfBundleString(@"摄像头保护已开启", nil) :
        LMLocalizedSelfBundleString(@"麦克风保护已开启", nil);
        notification.informativeText = isVedio ? LMLocalizedSelfBundleString(@"将在摄像头被调用时提醒你哦！", nil) :
        LMLocalizedSelfBundleString(@"将在麦克风被调用时提醒你哦！", nil);
        notification.hasActionButton = NO;
        notification.otherButtonTitle = LMLocalizedSelfBundleString(@"关闭", nil);
        notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], isVedio, [[NSDate date] description]];
        //[notification setDeliveryDate: [NSDate dateWithTimeIntervalSinceNow: 3]];
        //[[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        if (isVedio) {
            [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                       key:@"OwlVideoCheckOnceNotification"];
        } else {
            [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                       key:@"OwlAudioCheckOnceNotification"];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center removeDeliveredNotification:notification];
        });
    }
}

#pragma mark - 启通知提醒权限

- (void)getNotificationPermissionGrantedWithCompletionHandler:(void(^)(BOOL isAuthorized))handler {
    if (@available(macOS 10.14, *)) {
        // 使用 UserNotifications 框架（macOS 10.14 及以上）
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            BOOL result = settings.authorizationStatus == UNAuthorizationStatusAuthorized;
            if ([[NSThread currentThread] isMainThread]) {
                if (handler) handler(result);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) handler(result);
                });
            }
        }];
    } else {
        // 10.14以下系统未提供api来判断。默认认为关闭，与产品已确认
        if (handler) handler(NO);
    }
}

- (void)showNotificationPermissionViewWithCompletionHandler:(void(^)(BOOL isAuthorized))handler {
    @weakify(self);
    [self getNotificationPermissionGrantedWithCompletionHandler:^(BOOL isAuthorized) {
        @strongify(self);
        if (isAuthorized) {
            if (handler) handler(isAuthorized);
        } else {
            [self showNotificationPermissionView];
            if (handler) handler(NO);
        }
    }];
}

- (void)showNotificationPermissionView {
    if (!_npWindowController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - kOwlNPWindowWidth) / 2, prect.origin.y + (prect.size.height - kOwlNPWindowHeight) / 2, kOwlNPWindowWidth, kOwlNPWindowHeight);
        OwlNotificationPermissionViewController *vc = [[OwlNotificationPermissionViewController alloc] initWithFrame:srect];
        self.npWindowController = [[OwlWindowController alloc] initViewController:vc];
        [self.view.window addChildWindow:self.npWindowController.window ordered:NSWindowAbove];
        [self.npWindowController showWindow:nil];
        [self.npWindowController.window setFrame:srect display:NO];
    } else {
        [self.npWindowController showWindow:nil];
    }
}

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
}
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
    [center removeDeliveredNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#pragma mark - action

- (void)clickLogBtn:(id)sender{
    if (!self.logWindowController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - OwlWindowWidth) / 2, prect.origin.y + (prect.size.height - OwlWindowHeight) / 2, OwlWindowWidth, OwlWindowHeight);
        NSViewController *viewController = [[OwlLogViewController alloc] initWithFrame:srect];
        self.logWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.view.window addChildWindow:self.logWindowController.window ordered:NSWindowAbove];
        [self.logWindowController showWindow:nil];
        [self.logWindowController.window setFrame:srect display:NO];
    } else {
        [self.logWindowController showWindow:nil];
    }
}
- (void)clickWlistBtn:(id)sender{
    if (!self.wlWindowController) {
        CGFloat widht = 706;
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - widht) / 2, prect.origin.y + (prect.size.height - OwlWindowHeight) / 2, widht, OwlWindowHeight);
        NSViewController *viewController = [[OwlWhiteListViewController alloc] initWithFrame:srect];
        self.wlWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.view.window addChildWindow:self.wlWindowController.window ordered:NSWindowAbove];
        [self.wlWindowController showWindow:nil];
        [self.wlWindowController.window setFrame:srect display:NO];
    } else {
        [self.wlWindowController showWindow:nil];
    }
}

- (void)detailBtnClicked:(id)sender {
    [self showNotificationPermissionView];
}

#pragma mark - Owl2DeviceProtectionSwitchDelegate

- (void)owl2DeviceProtectionSwitchValueDidChange:(Owl2DeviceProtectionSwitchConfig *)config {
    Owl2Manager *owl2Manager = [Owl2Manager sharedManager];
    if (config.type == Owl2DPSwitchTypeWatchAudio) {
        [self showNotificationPermissionViewWithConfig:config cacheSwitchState:owl2Manager.isWatchAudio];
        
        [[Owl2Manager sharedManager] setWatchAudio:config.on toDb:YES];
        [[NSUserDefaults standardUserDefaults] setBool:config.on forKey:K_IS_WATCHING_AUDIO];
    }
    else if (config.type == Owl2DPSwitchTypeWatchVideo) {
        [self showNotificationPermissionViewWithConfig:config cacheSwitchState:owl2Manager.isWatchVideo];
        
        [[Owl2Manager sharedManager] setWatchVedio:config.on toDb:YES];
        [[NSUserDefaults standardUserDefaults] setBool:config.on forKey:K_IS_WATCHING_VEDIO];
    }
    else if (config.type == Owl2DPSwitchTypeWatchScreen) {
        if (@available(macOS 15.0, *)) {
            [self showNotificationPermissionViewWithConfig:config cacheSwitchState:owl2Manager.isWatchScreen];

            [[Owl2Manager sharedManager] setWatchScreen:config.on toDb:YES];
            [[NSUserDefaults standardUserDefaults] setBool:config.on forKey:K_IS_WATCHING_SCREEN];
        } else {
            self.screenSwitchView.config.on = NO;
            [[Owl2Manager sharedManager] setWatchScreen:NO toDb:YES];
            [self.screenSwitchView updateUI];
            [NSAlert owl_showScreenPrivacyProtection];
        }
    }
}

- (void)showNotificationPermissionViewWithConfig:(Owl2DeviceProtectionSwitchConfig *)config cacheSwitchState:(BOOL)state {
    // 若用户未开启成功任何开关，不展示应对开启权限通知浮窗
    if (config.on && !state) {
        [self showNotificationPermissionViewWithCompletionHandler:^(BOOL isAuthorized) {}];
    }
}

#pragma mark - getter
- (Owl2DeviceProtectionSwitchView *)audioSwitchView {
    if (!_audioSwitchView) {
        Owl2DeviceProtectionSwitchConfig *config = [Owl2DeviceProtectionSwitchConfig new];
        config.type = Owl2DPSwitchTypeWatchAudio;
        config.imageNameOn = @"owl_audio_nomal";
        config.imageNameOff = @"owl_audio_disable";
        config.title = LMLocalizedSelfBundleString(@"系统音频保护", nil);
        config.desc = LMLocalizedSelfBundleString(@"软件调用麦克风或录制音频时提示", nil);
        config.on = [[Owl2Manager sharedManager] isWatchAudio];
        _audioSwitchView = [[Owl2DeviceProtectionSwitchView alloc] initWithFrame:NSMakeRect(0, 0, 220, 220) config:config];
        _audioSwitchView.delegate = self;
        _audioSwitchView.layer = [self switchViewLayer];
    }
    return _audioSwitchView;
}

- (Owl2DeviceProtectionSwitchView *)videoSwitchView {
    if (!_videoSwitchView) {
        Owl2DeviceProtectionSwitchConfig *config = [Owl2DeviceProtectionSwitchConfig new];
        config.type = Owl2DPSwitchTypeWatchVideo;
        config.imageNameOn = @"owl_vedio_nomal";
        config.imageNameOff = @"owl_vedio_disable";
        config.title = LMLocalizedSelfBundleString(@"摄像头保护", nil);
        config.desc = LMLocalizedSelfBundleString(@"软件调用摄像头时提示", nil);
        config.on = [[Owl2Manager sharedManager] isWatchVideo];
        _videoSwitchView = [[Owl2DeviceProtectionSwitchView alloc] initWithFrame:NSMakeRect(0, 0, 220, 220) config:config];
        _videoSwitchView.delegate = self;
        _videoSwitchView.layer = [self switchViewLayer];
    }
    return _videoSwitchView;
}

- (Owl2DeviceProtectionSwitchView *)screenSwitchView {
    if (!_screenSwitchView) {
        Owl2DeviceProtectionSwitchConfig *config = [Owl2DeviceProtectionSwitchConfig new];
        config.type = Owl2DPSwitchTypeWatchScreen;
        config.imageNameOn = @"owl_screen_nomal";
        config.imageNameOff = @"owl_screen_disable";
        config.title = LMLocalizedSelfBundleString(@"屏幕保护", nil);
        config.desc = LMLocalizedSelfBundleString(@"软件截取或录制屏幕信息时提示", nil);
        config.on =  [[Owl2Manager sharedManager] isWatchScreen];
        _screenSwitchView = [[Owl2DeviceProtectionSwitchView alloc] initWithFrame:NSMakeRect(0, 0, 220, 220) config:config];
        _screenSwitchView.delegate = self;
        _screenSwitchView.layer = [self switchViewLayer];
    }
    return _screenSwitchView;
}

- (CALayer *)switchViewLayer {
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.borderColor = [NSColor colorWithWhite:0.94 alpha:1].CGColor;
    borderLayer.borderWidth = 0;
    borderLayer.cornerRadius = 4;
    return borderLayer;
}

@end
