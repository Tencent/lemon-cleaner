//
//  MainTabController.m
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMMonitorTabController.h"
#import "LMBaseLineSegmentedControl.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMOpenButton.h>
#import "QMDataConst.h"
#import "LemonDaemonConst.h"
#import "McStatInfoConst.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/QMBubble.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMUICommon/LMCommonHelper.h>
#import <QMUICommon/QMButton.h>
#import "AppDelegate.h"
#import "LMAboutWindow.h"

#define MONITOR_OPNE_LEMON_505      @"MONITOR_OPNE_LEMON_505" // 505活动入口标记

static const CGFloat kTopPadding = 10;


@interface LMMonitorTabController ()
{
    NSArray *_viewControllers;
    
    NSButton* launchSettingsBtn;
    NSBundle *myBundle;
    BOOL bNeedUpdate;
    NSImageView* mUpdateRedpointForSettings;
    LMSettingsViewController* _settingsViewController;
    QMBubble* _settingsBubble;
    NSView *bottomContainerView;
    
    id statusMonitorGlobal;
    id statusMonitorLocal;
    NSWindowController* _aboutWC;
}
@property (strong, nonatomic) NSTabViewItem *currentItem;
@property(weak)  NSView *divisionLineView;;
@property(nonatomic, assign) long timerNum;
@property(nonatomic, strong) QMButton *happyBirthBtn; // 三周年入口按钮
@property(nonatomic, strong) NSTimer *happyBirTimer; // 三周年动画定时器
@property(nonatomic, strong) NSString *currentGuid; // 当前用户guid
@property(nonatomic, strong) NSImageView *finishImageView;  //活动提醒红点
@property(nonatomic, strong) NSImageView *backImageView;
@property(nonatomic, strong) NSImageView *signImageView;

@end


@implementation LMMonitorTabController



- (instancetype)initWithControllers:(NSArray *)controllers titles:(NSArray *)titles
{
    if(controllers == nil || titles == nil || [controllers count] != [titles count]){
        NSLog(@"tabViewController controllers and titile must not be null and size must be equal");
        [NSException raise:@"MonitorTabControllerInitError" format:@"tabViewController controllers and titile must not be null and size must be equal"];
    }
    self = [self initWithNibName:NULL bundle:NULL];
    if (self) {
        _viewControllers = controllers;
        if (controllers.count > 0) {
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:controllers.count];
            [_viewControllers enumerateObjectsUsingBlock:^(NSViewController *controller, NSUInteger idx, BOOL *stop) {
                NSString *title = titles[idx];
                NSString *identifier = [NSString stringWithFormat:@"%lu-%@[%p]", (unsigned long)idx, title, controller];
                NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:identifier];
                item.view = controller.view;
                item.label = title;
                [items addObject:item];
            }];
            self.tabItems = items;
            _tabIndex = 0;
        
        }
    }
    
    myBundle = [NSBundle bundleForClass:[self class]];

    return self;
}

- (void)dealloc
{
    if (_viewControllers.count > 0) {
        [self.segmentedControl unbind:@"selectedSegment"];
    }
}

- (void)loadView
{
    NSRect rect = NSMakeRect(0, 0, 340, 444); //不包括箭头
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
    view.wantsLayer = YES;
//    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    if ([LMCommonHelper isMacOS11]) {
        view.layer.cornerRadius = 10;
    } else {
        view.layer.cornerRadius = 5;
    }
    view.layer.masksToBounds = YES;
//    [self viewDidLoad];  // 这里不需要调用了 在调用 _tabViewController.view时会调用一次viewDidLoad.
}

- (void)setupSegment {
    NSView *divisionLineView = [[NSView alloc]init];
//    divisionLineView.wantsLayer = YES;
//    divisionLineView.layer.backgroundColor = [NSColor colorWithHex:0xF1F1F1].CGColor;
    self.divisionLineView = divisionLineView;
    [self.view addSubview:self.divisionLineView];
    
    _segmentedControl = [[LMBaseLineSegmentedControl alloc] init]; // 22px height
    [self.view addSubview:_segmentedControl];

    _segmentedControl.focusRingType = NSFocusRingBelow;
    [_segmentedControl setFrameSize:NSMakeSize(180, 43)];
    _segmentedControl.target = self;
    _segmentedControl.action = @selector(onClickSemgnetControl:);
    [_segmentedControl addObserver:self forKeyPath:@"selectedSegment" options:NSKeyValueObservingOptionNew context:NULL];
    [self.segmentedControl bind:@"selectedSegment" toObject:self withKeyPath:@"tabIndex" options:nil];
    NSSegmentedControl *segmentedControl = self.segmentedControl;
   
    [_segmentedControl setSegmentCount:_tabItems.count];
    CGFloat width = segmentedControl.frame.size.width / _viewControllers.count;
    [_tabItems enumerateObjectsUsingBlock:^(NSTabViewItem *item, NSUInteger idx, BOOL *stop) {
        //        [_segmentedControl setLabel:objc_msgSend(item, @selector(label)) forSegment:idx];  // obj msg_send 奇怪的方法.
        [_segmentedControl setLabel:item.label forSegment:idx];
        [_segmentedControl setWidth:width forSegment:idx];

    }];
    
    if (self.tabItems.count > 0) {
        self.currentItem = self.tabItems[0];
    }
 
    
    [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@180);
        make.height.equalTo(@43);
        make.left.equalTo(self.view).offset(5);
        make.top.equalTo(self.view);
    }];
    
    [divisionLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.left.equalTo(self.view);
        make.height.equalTo(@1);
        make.top.equalTo(_segmentedControl.mas_bottom).offset(0);
    }];
    
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.divisionLineView];
    bottomContainerView.layer.backgroundColor = [LMAppThemeHelper getMonitorTabBottomBgColor].CGColor;
}

// viewDidLoad 可能被多次调用的原因:loadView 手动调用了一次, 调用_tabViewController.view时有调用了一次
- (void)viewDidLoad{
    [self setupSegment];
    [self setupLauncherView];
    
    
    // 监控更新
    [[NSNotificationCenter defaultCenter] addObserver:self
                                selector:@selector(receivedVersionUpdateNotification:)
                                            name:@"LemonHasNewVersion"
                                               object:nil];
    
    // 关于窗口
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                selector:@selector(receiveAboutOpenNotification:)
                                                     name:@"open_about"
                                                    object:nil];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
  
    if (mUpdateRedpointForSettings != nil)
    {
        if ([self CheckVersionUpdate])
        {
            mUpdateRedpointForSettings.hidden = false;
        }
        else
        {
            mUpdateRedpointForSettings.hidden = true;
        }
    }
    
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    if(self.happyBirthBtn) {
        [self.happyBirthBtn removeFromSuperview];
    }
    if(self.finishImageView) {
        [self.finishImageView removeFromSuperview];
    }
    if(self.backImageView) {
        [self.backImageView removeFromSuperview];
    }
    self.currentGuid = @"";
}

- (void)viewDidAppear {
    [super viewDidAppear];
//    获取云配参数保留
//    CFPreferencesAppSynchronize((__bridge CFStringRef)(MAIN_APP_BUNDLEID));
//    CFBooleanRef kAnniActivityEnter = CFPreferencesCopyAppValue((__bridge CFStringRef)(@"kAnniActivityEnter"), (__bridge CFStringRef)(MAIN_APP_BUNDLEID));
//     bug:偶现读取不到数据
//    if (kAnniActivityEnter == NULL) {
//        return;
//    }
}

- (void) setupLauncherView
{
    bottomContainerView = [LMViewHelper createPureColorView:[LMAppThemeHelper getMonitorTabBottomBgColor]];
    [self.view addSubview:bottomContainerView];
    
    launchSettingsBtn = [LMViewHelper createNormalButton];
    launchSettingsBtn.image = [myBundle imageForResource:@"lemon_setting"];
    [self.view addSubview:launchSettingsBtn];
    launchSettingsBtn.target = self;
    launchSettingsBtn.action = @selector(onLaunchSettings);
    [launchSettingsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(13);
        make.centerY.equalTo(bottomContainerView);
        make.width.equalTo(@32);
        make.height.equalTo(@32);
    }];
    
    // redpoint for update
    NSImageView* updateRedpoint  = [[NSImageView alloc] init];
    [updateRedpoint setImage:[myBundle  imageForResource:@"redpoint2"]];
    [self.view addSubview:updateRedpoint];
    [updateRedpoint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(launchSettingsBtn.mas_left).offset(20);
        make.bottom.mas_equalTo(launchSettingsBtn.mas_top).offset(8);
        make.width.equalTo(@6);
        make.height.equalTo(@6);
    }];
    
    if ([self CheckVersionUpdate])
    {
        updateRedpoint.hidden = false;
    }
    else
    {
        updateRedpoint.hidden = true;
    }
    
    mUpdateRedpointForSettings = updateRedpoint;
    
    // launch Lemon
    //    NSButton* launchLemonBtn = [NSButton buttonWithTitle:@"打开 Lemon" target:self action:@selector(onLaunchLemon)];
    LMOpenButton *launchLemonBtn = [[LMOpenButton alloc] init];
    [launchLemonBtn setFont:[NSFontHelper getRegularSystemFont:12]];
    launchLemonBtn.title = NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_setupLauncherView_launchLemonBtn_1", nil, [NSBundle bundleForClass:[self class]], @"");
    launchLemonBtn.target = self;
    launchLemonBtn.action = @selector(onLaunchLemon);
    [self.view addSubview:launchLemonBtn];
    [launchLemonBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.centerY.equalTo(bottomContainerView);
        make.width.equalTo(@130);
        make.height.equalTo(@28);
    }];
    
    NSImageView *signImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 6, 6)];
    NSImage *image = [NSImage imageNamed:@"Ellipse" withClass:self.class];
    signImageView.image = image;
    self.signImageView = signImageView;
    [launchLemonBtn addSubview:signImageView];
    [signImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(launchLemonBtn);
        make.left.equalTo(launchLemonBtn.mas_left).offset(20);
    }];
    self.signImageView.hidden = YES;
    
    //launch feedback
    NSButton* launchFeebBackBtn = [LMViewHelper createNormalButton];
    launchFeebBackBtn.image = [myBundle imageForResource:@"lemon_feedback"];
    launchFeebBackBtn.target = self;
    launchFeebBackBtn.action = @selector(onLaunchFeebBack);
    [launchFeebBackBtn setBordered:NO];
    [self.view addSubview:launchFeebBackBtn];
    [launchFeebBackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view).offset(-13);
        make.centerY.equalTo(bottomContainerView);
        make.width.equalTo(@32);
        make.height.equalTo(@32);
    }];
    
    [bottomContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.left.equalTo(self.view);
        make.height.equalTo(@50);
        make.bottom.equalTo(self.view);
    }];
}



- (NSViewController *)selectedController
{
    if (_viewControllers.count == 0) return nil;
    return _viewControllers[self.tabIndex];
}

- (void)setSelectedController:(NSViewController *)controller
{
    NSInteger idx = [_viewControllers indexOfObject:controller];
    if (idx != NSNotFound) {
        self.tabIndex = idx;
    }
}



#pragma mark - Action Responder
- (void)onClickSemgnetControl:(NSSegmentedControl *)sender
{
    if (_currentItem == [self _selectedItem]) return;
    self.currentItem = [self _selectedItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _segmentedControl && [keyPath isEqualToString:@"selectedSegment"]) {
        [self onClickSemgnetControl:object];
    }
}

#pragma mark - Private Methods
- (NSTabViewItem *)_selectedItem
{
    if (self.tabItems.count == 0) return nil;
    if (_segmentedControl.selectedSegment < 0 || _segmentedControl.selectedSegment >= self.tabItems.count) return nil;
    return self.tabItems[_segmentedControl.selectedSegment];
}

- (void)_configViewByTabItems
{
    [_segmentedControl setSegmentCount:_tabItems.count];
    [_tabItems enumerateObjectsUsingBlock:^(NSTabViewItem *item, NSUInteger idx, BOOL *stop) {
//        [_segmentedControl setLabel:objc_msgSend(item, @selector(label)) forSegment:idx];  // obj msg_send 奇怪的方法.
         [_segmentedControl setLabel:item.label forSegment:idx];
    }];
    if (_tabItems.count > 0) {
        _segmentedControl.selectedSegment = 0;
    }
    //    [_segmentedControl sizeToFit];
    [_segmentedControl setFrameOrigin:NSMakePoint((NSWidth(self.view.bounds) - NSWidth(_segmentedControl.frame)) / 2, NSHeight(self.view.bounds) - NSHeight(_segmentedControl.frame) - kTopPadding)];
}

- (void)setCurrentItem:(NSTabViewItem *)item
{
    if (_currentItem) {
        [_currentItem.view removeFromSuperview];
    }
    [self.view addSubview:item.view];
    [item.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.left.equalTo(self.view);
        make.top.equalTo(self.view).offset(44);
        make.bottom.equalTo(self.view).offset(-50);
    }];
    _currentItem = item;
}


#pragma mark - Getters



-(void)receiveAboutOpenNotification:(NSNotification *)notification
{
    [self rightAboutAction:nil];
}


-(void)receivedVersionUpdateNotification:(NSNotification *)notification
{
    bNeedUpdate = YES;
}


-(BOOL)CheckVersionUpdate
{
    NSString* newVersionStr = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersion];
    NSString* ignoredVersionStr = [[NSUserDefaults standardUserDefaults] objectForKey:kIgnoreLemonNewVersion];
    if (newVersionStr != nil && (ignoredVersionStr == nil || ![newVersionStr isEqualToString:ignoredVersionStr]))
    {
        NSBundle *mainAppBundle = [NSBundle bundleWithPath:DEFAULT_APP_PATH];
        NSString *myVer = [[mainAppBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersionInfo];
        NSString *strNewVersion = [versionInfo objectForKey:@"version"];
        if (myVer && [strNewVersion compareVersion:myVer])
        {
            bNeedUpdate = YES;
        } else {
            bNeedUpdate = NO;
        }
    }
    else
    {
        bNeedUpdate = NO;
    }
    
    return bNeedUpdate;
}



-(void) onLaunchSettings
{
    NSLog(@"onLaunchSettings enter.");
        
    if (false) {
        
        //    if (!settingsPopover) {
        //        //用于显示弹窗
        //        settingsPopover = [[QMMonitorPopover alloc] init];
        //        settingsPopover.floatWindow = self.view.window;
        //        settingsPopover.statusView = nil;
        //        settingsPopover.dismissCompletion = nil;
        //    }
        //
        //    [settingsPopover showPopover];
        _settingsViewController = [[LMSettingsViewController alloc] init];
        _settingsBubble = [[QMBubble alloc] init];
        _settingsBubble.distance = 30;
        _settingsBubble.direction = QMArrowCornerTopRight;
        _settingsBubble.keyWindow = YES;
        _settingsBubble.draggable = YES;
        [_settingsBubble setCornerRadius:2.0];
        //    [_settingsBubble setDrawArrow:NO];
        //    [_settingsBubble setArrowHeight:160.0];
        //    [_settingsBubble setArrowWidth:100.0];
        //    [_settingsBubble setArrowDistance:30];
        [_settingsBubble setBorderColor:[NSColor clearColor]];
        [_settingsBubble setContentView:_settingsViewController.view];
        
        //    _settingsBubble.arrowDistance = 100;
        //    _settingsBubble.arrowOffset = 0;
        _settingsBubble.titleMode = QMBubbleTitleModeArrow; //QMBubbleTitleModeTitleBar;
        if (_settingsBubble.isVisible && !_settingsBubble.attachedToParentWindow)
            return;
        //    convertPointToScreen:[NSEvent mouseLocation]
        //显示的参照点
        //    NSRect statusRect = [self.view convertRect:self.view.bounds toView:nil];
        //    statusRect = [self.view.window convertRectToScreen:statusRect];
        //    NSPoint showPoint = NSMakePoint(NSMidX(statusRect), NSMinY(statusRect));
        NSPoint showPoint;
//        NSPoint settingsBtnLoc = launchSettingsBtn.frame.origin;
        NSRect pointOnScreen = [[launchSettingsBtn window] convertRectToScreen:launchSettingsBtn.frame];
        showPoint = pointOnScreen.origin;
        [_settingsBubble showToPoint:showPoint ofWindow:nil];
        
        void (^handler)(NSEvent *) = ^void(NSEvent *event){
            //        QMFullViewController *sself = settings;
            NSRect frame = _settingsViewController.view.window.frame;
//            NSPoint point = [NSEvent mouseLocationInView:_settingsViewController.view];
            
            if (NSPointInRect([NSEvent mouseLocation], NSInsetRect(frame, -2, -2)))
            {
                return;
            }
            [_settingsBubble dismiss];
        };
        
        if (!statusMonitorGlobal) {
            statusMonitorGlobal = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:handler];
        }
        if (!statusMonitorLocal) {
            statusMonitorLocal = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:^NSEvent *(NSEvent *event) {
                handler(event);
                return event;
            }];
        }
        
        return;
    }
    
    
    // check version update
    bNeedUpdate = [self CheckVersionUpdate];
    
    // UI
    NSMenu* rightClickMenu = [[NSMenu alloc] init];
    //    rightClickMenu.minimumWidth = 300.0f;
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_onLaunchSettings_item1 _1", nil, [NSBundle bundleForClass:[self class]], @""),
                                                                            @"") action:@selector(rightAboutAction:) keyEquivalent:@""];
    //    NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"隐私政策", @"") action:@selector(rightPrivacyAction:) keyEquivalent:@""];
    //    NSMenuItem *item3 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"语言设置", @"") action:@selector(rightLanguageAction:) keyEquivalent:@""];
//    NSMenuItem *item4 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_onLaunchSettings_item4 _2", nil, [NSBundle bundleForClass:[self class]], @""),
//                                                                            @"") action:@selector(onRightUpdateAction:) keyEquivalent:@""];
    //    NSMenuItem *item5 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"退出", @"") action:@selector(rightQuitAction:) keyEquivalent:@""];
    NSMenuItem *item6 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_onLaunchSettings_item6 _3", nil, [NSBundle bundleForClass:[self class]], @""),
                                                                            @"") action:@selector(rightOpenPreference:) keyEquivalent:@""];
    NSMenuItem *item7 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_onLaunchSettings_item7 _4", nil, [NSBundle bundleForClass:[self class]], @""),
                                                                            @"") action:@selector(rightQuitAction:) keyEquivalent:@""];
    if (bNeedUpdate) {
//        item4.image = [myBundle imageForResource:@"redpoint"];
        item1.image = [myBundle imageForResource:@"redpoint_transparent"];
        item6.image = [myBundle imageForResource:@"redpoint_transparent"];
        item7.image = [myBundle imageForResource:@"redpoint_transparent"];
        NSLog(@"backingScaleFactor: %f", [NSScreen mainScreen].backingScaleFactor);
    }
    
    [item1 setTarget:self];
    //    [item2 setTarget:self];
    //    [item3 setTarget:self];
//    [item4 setTarget:self];
    //    [item5 setTarget:self];
//    [rightClickMenu addItem:item4];
    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    [rightClickMenu addItem:item1];
    //    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    //    [rightClickMenu addItem:item2];
    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    [rightClickMenu addItem:item6];
    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    [rightClickMenu addItem:item7];
    //    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    //    [rightClickMenu addItem:item3];
    //    [rightClickMenu addItem:[NSMenuItem separatorItem]];
    //    [rightClickMenu addItem:item5];
    //     [self.view setMenu:rightClickMenu];
    
    id sender = launchSettingsBtn;
    NSRect frame = [(NSButton *)sender frame];
    NSPoint menuOrigin = [[(NSButton *)sender superview] convertPoint:NSMakePoint(frame.origin.x, frame.origin.y) toView:nil];
    
    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                         location:menuOrigin
                                    modifierFlags:NSLeftMouseDownMask
                                        timestamp:0
                                     windowNumber:[[(NSButton *)sender window] windowNumber]
                                          context:[[(NSButton *)sender window] graphicsContext]
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
    
    // contextMenu可以直接在XIB里初始化一个菜单
    NSMenu* contextMenu = rightClickMenu;
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:(NSButton *)sender];
}


- (void) onLaunchLemon
{
    NSLog(@"onLaunchLemon enter.");
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MONITOR_OPNE_LEMON_505];
        
    [[NSWorkspace sharedWorkspace] launchApplication:DEFAULT_APP_PATH];
//    [[NSWorkspace sharedWorkspace] launchApplication:@"Calculator.app"];
    
    [self notifyDimissPopover];
}

- (void) onLaunchFeebBack
{
    NSLog(@"onLaunchFeebBack enter.");
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
        return;
    }
    #ifndef APPSTORE_VERSION
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
    #else
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/52728"]];
    #endif
    
    
    [self notifyDimissPopover];
}

- (void)notifyDimissPopover
{
    [[NSNotificationCenter defaultCenter] postNotificationName:QMPopoverDismiss object:nil];
}
-(void) onRightUpdateAction:(id)sender
{
    [self notifyDimissPopover];
}

- (BOOL)hasNewVersion{
    NSBundle *mainAppBundle = [NSBundle bundleWithPath:DEFAULT_APP_PATH];
    NSString *myVer = [[mainAppBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kLemonNewVersionInfo];
    NSString *strNewVersion = [versionInfo objectForKey:@"version"];
    //NSLog(@"hasNewVersion: %@, %@, %ld, %ld, %ld", myVer, strNewVersion, (long)[myVer compare:strNewVersion], NSOrderedAscending, NSOrderedDescending);
    if (myVer && [strNewVersion compareVersion:myVer])
    {
        //has new version
        return YES;
    } else {
        return NO;
    }
}

-(void) rightOpenPreference:(id)sender
{
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
    
    [self notifyDimissPopover];
}

-(void) rightAboutAction:(id)sender
{
    if (_aboutWC)
    {
        [_aboutWC showWindow:self];
        [self notifyDimissPopover];
        return;
    }
    
    NSString *versionTime =  [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemon_Version_Time"];
    NSWindow* windowAbout = [LMAboutWindow windowWithVersionTimeString:versionTime];
    _aboutWC = [[NSWindowController alloc] initWithWindow:windowAbout];
    [windowAbout center];
    [_aboutWC showWindow:self];
                             
    [self notifyDimissPopover];
}
- (void)setTextFieldNormal:(NSTextField*) textField
{
    textField.font = [NSFontHelper getLightSystemFont:12];
    textField.textColor = [NSColor colorWithHex:0x7E7E7E alpha:1.0];
}
-(void) rightPrivacyAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://privacy.qq.com/"]];
    [self notifyDimissPopover];
}

-(void) rightLanguageAction:(id)sender
{
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable ;
    NSWindow* _windowLanguage = [[NSWindow alloc]initWithContentRect:CGRectMake(0, 0, 600, 600) styleMask:style backing:NSBackingStoreBuffered defer:YES];
    
    [_windowLanguage center];
    _windowLanguage.title = NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_rightLanguageAction__windowLanguage_1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSButton* radioButtonChinese = [NSButton radioButtonWithTitle:@"CHINESE" target:self action:@selector(languageSelected:)];
    radioButtonChinese.tag = 1;
    [radioButtonChinese setButtonType:NSButtonTypeRadio];
    [_windowLanguage.contentView addSubview:radioButtonChinese];
    [radioButtonChinese mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_windowLanguage.contentView);
        make.centerY.equalTo(_windowLanguage.contentView);
    }];
    
    //
    NSButton* radioButtonEnglish = [NSButton radioButtonWithTitle:@"ENGLISH" target:self action:@selector(languageSelected:)];
    radioButtonEnglish.tag = 2;
    [radioButtonEnglish setButtonType:NSButtonTypeRadio];
    [_windowLanguage.contentView addSubview:radioButtonEnglish];
    [radioButtonEnglish mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_windowLanguage.contentView);
        make.top.mas_equalTo(radioButtonChinese.mas_bottom);
    }];
    
    //
    NSWindowController *wc = [[NSWindowController alloc] initWithWindow:_windowLanguage];
    [wc showWindow:nil];
    
    //
    [self notifyDimissPopover];
}

-(void) rightQuitAction:(id)sender
{
    [self notifyDimissPopover];

    NSApplicationTerminateReply ttype = NSTerminateNow;
    
//    NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID];
//    if (runningApps.count > 0) {
//        ttype = NSTerminateNow;
//    } else
    Boolean isTrashWatchHasSet = false;
    BOOL isTrashSizeWatchEnable = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)(IS_ENABLE_TRASH_SIZE_WATCH), (__bridge CFStringRef)(MAIN_APP_BUNDLEID), &isTrashWatchHasSet);
    if(!isTrashWatchHasSet){
        isTrashSizeWatchEnable = YES;
    }
    
    if([SharedPrefrenceManager getBool:K_IS_WATCHING_VEDIO] || [SharedPrefrenceManager getBool:K_IS_WATCHING_AUDIO] || [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH] || isTrashSizeWatchEnable)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_rightQuitAction_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
        //alert.informativeText = @"确定要阻止吗？";
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_rightQuitAction_alert_2", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_rightQuitAction_alert_3", nil, [NSBundle bundleForClass:[self class]], @"")];
        NSInteger responseTag = [alert runModal];
        if (responseTag != NSAlertFirstButtonReturn) {
            ttype = NSTerminateNow;
        } else {
            ttype = NSTerminateCancel;
        }
    }

    if (ttype == NSTerminateNow) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kLemonQuitMonitorManual];
        NSLog(@"use select terminate monitor by click quit button ");
        [[NSApplication sharedApplication] terminate:nil];
    }
}

-(void) languageSelected:(id)sender
{
    NSButton* btn = (NSButton*)sender;
    
    if (btn.tag == 1)
    {
        NSLog(@"CHINESE language selected");
    }
    else if (btn.tag == 2)
    {
        NSLog(@"ENGLISH language selected");
    }
}
@end




@implementation LMSettingsViewController
- (void)loadView
{
    NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 116, 113)];
    self.view = contentView;
    self.view.wantsLayer = true;
    //    self.view.layer.backgroundColor = [NSColor redColor].CGColor;
    self.view.layer.backgroundColor = [NSColor colorWithHex:0xEFF0f0 alpha:0.9].CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL bNeedUpdate = NO;
    
    //    NSView* containerView_1 = [[NSView alloc] init];
    //    [self.view addSubview:containerView_1];
    //    [containerView_1 mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.width.equalTo(self.view.mas_width);
    //        make.height.equalTo(@28);
    //        make.top.equalTo(containerView_1.mas_top).offset(4);
    //    }];
    //
    //    NSTextField* textUpdate = [NSTextField labelWithStringCompat:@"检查更新"];
    //    [containerView_1 addSubview:textUpdate];
    //    [textUpdate mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.centerY.equalTo(containerView_1);
    //        make.left.equalTo(containerView_1.mas_left).offset(21);
    //    }];
}
@end
