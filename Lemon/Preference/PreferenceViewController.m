//
//  PreferenceViewController.m
//  Lemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "PreferenceViewController.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/COSwitch.h>
#import "LemonDaemonConst.h"
#import "PreferenceWindowController.h"
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMUICommon/NSFontHelper.h>
#import "LemonDaemonConst.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

#ifndef APPSTORE_VERSION
#import "AppTrashDel.h"
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import <QMUICommon/LMAlertViewController.h>
#import <QMUICommon/LMPermissionGuideWndController.h>
#import <QMCoreFunction/LMAuthorizationManager.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#endif


#define DOCK_ON_OFF_STATE @"dock_on_off_state"

@interface PreferenceViewController ()
{
    //    NSTextField * m_tfMonitorWarningTips;
    NSInteger  testCount;
}
@property(weak) NSView *languageLineView;
@property(weak) NSView* themeLineView;
@property(weak) NSView* uninstallLineView;
@property(weak) NSView* trashSizeCheckLineView;
@property(weak) NSButton *lightThemeRadioBtn;
@property(weak) NSButton *darkThemeRadioBtn;
@property(weak) NSButton *followSystemThemeRadioBtn;
@property(weak) COSwitch *autoUninstallSwitch;


@property(weak) NSButton *overSizeRadioBtn;
@property(weak) NSButton *deleteFileRadioBtn;
@property(weak) NSPopUpButton *popUpButton;
@property(weak) COSwitch *trashSizeCheckSwitch;


@property (strong,nonatomic) LMPermissionGuideWndController *permissionGuideWndController;


@end

@implementation PreferenceViewController

-(id)initWithPreferenceWindowController:(PreferenceWindowController *)wdControle{
    self = [super init];
    if (self) {
        self.myWC = wdControle;
    }
    
    return self;
}

-(NSTextField *)createLabelForTitleWithKey: (NSString *)titleKey{
    //[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]
   return [self createLabel:NSLocalizedStringFromTableInBundle(titleKey, nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
}

-(NSTextField *)createLabelForItem: (NSString *)itemKey{
    return [self createLabel:NSLocalizedStringFromTableInBundle(itemKey, nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:12] color:[LMAppThemeHelper getTitleColor]];
}


- (NSTextField*)createLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentLeft;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}

-(NSButton *)createRadioButtonWithSelector: (SEL)selector{
    NSButton *radioBtn = [[NSButton alloc]init];
    radioBtn.frame = NSMakeRect(0, 0, 14, 14);
    radioBtn.wantsLayer = YES;
    [radioBtn setBordered:NO];
    radioBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [radioBtn setButtonType:NSRadioButton];
    radioBtn.allowsMixedState = NO;
    radioBtn.title = @"";
    radioBtn.target = self;
    [radioBtn setAction:selector];
    return radioBtn;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //        [self loadView];
    }
    
    return self;
}

- (void)loadView {
    //doesn't work
    NSRect rect = NSMakeRect(0, 0, 530, 100);
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        rect = NSMakeRect(0, 0, 530, 556);
    }
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
    //    [self viewDidLoad];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _myRadioControls = [[NSMutableDictionary alloc] init];
    [self setupViews];
    [self addObserver];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayout{
    [LMAppThemeHelper setDivideLineColorFor:self.languageLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.themeLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.uninstallLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.trashSizeCheckLineView];
}

-(void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:(@selector(updateUninstallSwitchState)) name:NSWindowDidBecomeMainNotification object:nil];
}

-(void)updateUninstallSwitchState{
//    NSLog(@"%s,called",__FUNCTION__);
//    long startTime = [[NSDate date]timeIntervalSince1970];
//    NSLog(@"%s,startTime:%ld",__FUNCTION__,startTime);
    BOOL authorizationStatus = [self checkFullDiskAuthorizationStatus];
    BOOL trashWatchStatus = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH];
    BOOL trashSizeWatchStatus = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_SIZE_WATCH];
    
//    NSLog(@"%s, authorizationStatus : %d", __FUNCTION__, authorizationStatus);
//    NSLog(@"%s, IS_ENABLE_TRASH_WATCH : %d", __FUNCTION__, trashWatchStatus);
//    NSLog(@"%s, IS_ENABLE_TRASH_SIZE_WATCH : %d", __FUNCTION__, trashSizeWatchStatus);
    
    self.autoUninstallSwitch.on = authorizationStatus && trashWatchStatus;
    self.trashSizeCheckSwitch.on = authorizationStatus && trashSizeWatchStatus;
//    long endTime = [[NSDate date]timeIntervalSince1970];
//    NSLog(@"%s,endTime:%ld",__FUNCTION__,endTime);
//    long runTime = endTime - startTime;
//    NSLog(@"%s,runtime:%ld",__FUNCTION__,runTime);
}

- (void)checkPermissionAndOpenWindowWithSwitchBtn:(COSwitch *)button {
    //如果没有授权，状态栏在，“前往授权”
    if(![self checkFullDiskAuthorizationStatus] && button.on && [self isAppRunningBundleId:MONITOR_APP_BUNDLEID])
    {
        [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_checkFullDiskAccess_need_permission_tips", nil, [NSBundle mainBundle], @"") windowCloseBlock:^{
            button.on = NO;
        } okButtonBlock:^{
            if(button == self.autoUninstallSwitch){
                [self saveTrahCheckStatus:YES];
            }else if(button == self.trashSizeCheckSwitch){
                [self saveTrashSizeCheckStatus:YES];
            }
            
            [self openFullDiskPermissinGuideWindow];
        } cancelBtnBlock:^{
        }];
        
        return;
    }
    
    //如果没有授权，状态栏不在, "开启并授权"
    if(![self checkFullDiskAuthorizationStatus] && button.on && ![self isAppRunningBundleId:MONITOR_APP_BUNDLEID])
    {
        [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_checkFullDiskAccess_need_permission_open_monitor_tips", nil, [NSBundle mainBundle], @"") description:@"" okBtnTitle:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_checkFullDiskAccess_need_permission_open_monitor_ok_button_title", nil, [NSBundle mainBundle], @"") windowHeight: 140 windowCloseBlock:^{
            button.on = NO;
        } okButtonBlock:^{
            if(button == self.autoUninstallSwitch){
                [self saveTrahCheckStatus:YES];
            }else if(button == self.trashSizeCheckSwitch){
                [self saveTrashSizeCheckStatus:YES];
            }
            
            [self openMonitor];
            [self openFullDiskPermissinGuideWindow];
        } cancelButtonBlock:^{
        }];
        return;
    }
    
    //如果已经授权，状态栏不在，“打开状态栏”
    if([self checkFullDiskAuthorizationStatus] && button.on && ![self isAppRunningBundleId:MONITOR_APP_BUNDLEID])
    {
        [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_checkFullDiskAccess_need_open_monitor_tips", nil, [NSBundle mainBundle], @"") description:@"" okBtnTitle: NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_checkFullDiskAccess_need_open_monitor_ok_button_title", nil, [NSBundle mainBundle], @"") windowHeight:133 windowCloseBlock:nil okButtonBlock:^{
            [self openMonitor];
            button.on = YES;
            if(button == self.autoUninstallSwitch){
                [self saveTrahCheckStatus:YES];
            }else if(button == self.trashSizeCheckSwitch){
                [self saveTrashSizeCheckStatus:YES];
            }
            
        } cancelButtonBlock:^{
            button.on = NO;
        }];
        return;
    }
}

- (void)setupViews {
    // 自动卸载残留
    NSTextField* autoUnintallresidualTitle =[self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    NSTextField* autoUnintallresidualDesc =[self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_2", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    if (@available(macOS 10.11, *)) {
        autoUnintallresidualDesc.maximumNumberOfLines = 2;
    }
    
    ///MARK: 卸载残留设置
    COSwitch *autoUninstallSwitch = [[COSwitch alloc] init];
    self.autoUninstallSwitch = autoUninstallSwitch;
    autoUninstallSwitch.on = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH] && [self checkFullDiskAuthorizationStatus];
    [autoUninstallSwitch setOnValueChanged:^(COSwitch *button) {
        
        
        [self checkPermissionAndOpenWindowWithSwitchBtn:button];
        
        BOOL btnState = button.isOn;
        [self saveTrahCheckStatus:btnState];
//        [[McCoreFunction shareCoreFuction] enableTrashWatch:btnState];
#ifndef APPSTORE_VERSION
//        [AppTrashDel enableTrashWatch:btnState];
#endif
    }];
    

    //卸载残留下方的分割线
    NSView* uninstallLineView = [[NSView alloc] init];
    self.uninstallLineView = uninstallLineView;
    [self.view addSubview:uninstallLineView];
    
    //MARK: 废纸篓清理提醒
    NSTextField *trashSizeCheckTitle = [self createLabelForTitleWithKey:@"PreferenceViewController_trash_size_check_title"];
    [self.view addSubview:trashSizeCheckTitle];
    
    COSwitch *trashSizeCheckSwitch = [[COSwitch alloc] init];
    self.trashSizeCheckSwitch = trashSizeCheckSwitch;
    [self.view addSubview:trashSizeCheckSwitch];
    [self updateUninstallSwitchState];
//    trashSizeCheckSwitch.on = [SharedPrefrenceManager getBool:IS_ENABLE_TRASH_SIZE_WATCH];
    [trashSizeCheckSwitch setOnValueChanged:^(COSwitch *button) {
        [self checkPermissionAndOpenWindowWithSwitchBtn: button];
        [self saveTrashSizeCheckStatus:button.isOn];
    }];
    
    
    NSButton *deleteFileRadioBtn = [self createRadioButtonWithSelector:@selector(trashSizeCheckWhenDeleteFile)];
    deleteFileRadioBtn.title = @"";
    self.deleteFileRadioBtn = deleteFileRadioBtn;
    NSTextField *deleteFileRadioBtnDesc = [self createLabelForItem:@"PreferenceViewController_trash_size_check_when_delete_file"];
    NSButton *overSizeRadioBtn = [self createRadioButtonWithSelector:@selector(trashSizeCheckWhenOverSize)];
    self.overSizeRadioBtn = overSizeRadioBtn;
    NSTextField *overSizeRadioBtnDesc = [self createLabelForItem:@"PreferenceViewCOntroller_trash_size_check_when_over_size_first"];
    

    NSPopUpButton *popUpButton = [[NSPopUpButton alloc]init];
    self.popUpButton = popUpButton;
    popUpButton.alignment = NSTextAlignmentCenter;
    [popUpButton addItemsWithTitles:@[@"500 MB", @"1 GB", @"2 GB"]];
    [popUpButton selectItemAtIndex:1];
    [popUpButton setTarget:self];
    [popUpButton setAction:@selector(popUpBtnAction:)];
    
    
    NSTextField *overSizeRadioBtnDescEnd = [self createLabelForItem:@"PreferenceViewCOntroller_trash_size_check_when_over_size_second"];
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
         [self.view addSubview:overSizeRadioBtnDescEnd];
    }
    
    [self.view addSubview:popUpButton];
    [self.view addSubview:deleteFileRadioBtn];
    [self.view addSubview:deleteFileRadioBtnDesc];
    [self.view addSubview:overSizeRadioBtn];
    [self.view addSubview:overSizeRadioBtnDesc];
    
    [self initPopUpButton];
    [self updateTrashSizeCheckRadioBtn];
    
    //卸载残留下方的分割线
    NSView* trashSizeCheckLineView = [[NSView alloc] init];
    self.trashSizeCheckLineView = trashSizeCheckLineView;
    [self.view addSubview:trashSizeCheckLineView];
    
    
    //MARK: 关闭主面板，Docker栏图标显示
    NSTextField* dockTitle = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_3", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    NSButton *dockRadioBtnMin = [[NSButton alloc]init];
    dockRadioBtnMin.frame = NSMakeRect(0, 0, 14, 14);
    dockRadioBtnMin.wantsLayer = YES;
    [dockRadioBtnMin setBordered:NO];
    dockRadioBtnMin.layer.backgroundColor = [NSColor clearColor].CGColor;
    [dockRadioBtnMin setButtonType:NSRadioButton];
    dockRadioBtnMin.allowsMixedState = NO;
    dockRadioBtnMin.target = self;
    [dockRadioBtnMin setAction:@selector(dockMinValueChange:)];
    
    NSTextField* dockRadioBtnMinDes = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_4", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    
    NSButton *dockRadioBtnExit = [[NSButton alloc]init];
    dockRadioBtnExit.frame = NSMakeRect(0, 0, 14, 14);
    dockRadioBtnExit.wantsLayer = YES;
    [dockRadioBtnExit setBordered:NO];
    dockRadioBtnExit.layer.backgroundColor = [NSColor clearColor].CGColor;
    [dockRadioBtnExit setButtonType:NSRadioButton];
    dockRadioBtnExit.allowsMixedState = NO;
    dockRadioBtnExit.target = self;
    [dockRadioBtnExit setAction:@selector(dockExitValueChange:)];
    
    NSTextField* dockRadioBtnExitDes = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_5", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    
    NSTextField* javaOsTipLabel = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_6", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x999999]];
    if (@available(macOS 10.11, *)) {
        javaOsTipLabel.maximumNumberOfLines = 2;
    }
    
    //更改设置
    NSTextField* systemSettingBtn = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_7", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x057cff]];
    NSClickGestureRecognizer *clickGes = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(gotoSystemSettingPage)];
    [systemSettingBtn addGestureRecognizer:clickGes];
    
    
    [_myRadioControls setObject:dockRadioBtnMin forKey:@1];
    [_myRadioControls setObject:dockRadioBtnExit forKey:@0];
    
    if ([SharedPrefrenceManager getBool:DOCK_ON_OFF_STATE] )
    {
        dockRadioBtnMin.state = NSControlStateValueOn;
        dockRadioBtnExit.state = NSControlStateValueOff;
        dockRadioBtnMin.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
        dockRadioBtnExit.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    }
    else
    {
        dockRadioBtnMin.state = NSControlStateValueOff;
        dockRadioBtnExit.state = NSControlStateValueOn;
        dockRadioBtnMin.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
        dockRadioBtnExit.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
    }
    
    //    NSView* dockLineView = [[NSView alloc] init];
    //    CALayer *dockLineLayer = [[CALayer alloc] init];
    //    dockLineLayer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.05].CGColor;
    //    dockLineView.layer = dockLineLayer;
    
    //语言设置
    NSView* languageLineView = [[NSView alloc] init];
    self.languageLineView = languageLineView;
    
    NSButton *languageRadioBtnCh = [[NSButton alloc]init];
    languageRadioBtnCh.frame = NSMakeRect(0, 0, 14, 14);
    languageRadioBtnCh.wantsLayer = YES;
    [languageRadioBtnCh setBordered:NO];
    languageRadioBtnCh.layer.backgroundColor = [NSColor clearColor].CGColor;
    [languageRadioBtnCh setButtonType:NSRadioButton];
    languageRadioBtnCh.allowsMixedState = NO;
    languageRadioBtnCh.target = self;
    [languageRadioBtnCh setAction:@selector(languageChangeToCh:)];
    
    NSTextField* languageRadioBtnChDesc = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_languageRadioBtnChDesc_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    
    NSButton *languageRadioBtnEn = [[NSButton alloc]init];
    languageRadioBtnEn.frame = NSMakeRect(0, 0, 14, 14);
    languageRadioBtnEn.wantsLayer = YES;
    [languageRadioBtnEn setBordered:NO];
    languageRadioBtnEn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [languageRadioBtnEn setButtonType:NSRadioButton];
    languageRadioBtnEn.allowsMixedState = NO;
    languageRadioBtnEn.target = self;
    [languageRadioBtnEn setAction:@selector(languageChangeToEn:)];
    
    NSTextField* languageRadioBtnEnDesc = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_languageRadioBtnEnDesc_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    
    [_myRadioControls setObject:languageRadioBtnCh forKey:@3];
    [_myRadioControls setObject:languageRadioBtnEn forKey:@2];
    
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese)
    {
        languageRadioBtnCh.state = NSControlStateValueOn;
        languageRadioBtnEn.state = NSControlStateValueOff;
        languageRadioBtnCh.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
        languageRadioBtnEn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    }
    else
    {
        languageRadioBtnCh.state = NSControlStateValueOff;
        languageRadioBtnEn.state = NSControlStateValueOn;
        languageRadioBtnCh.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
        languageRadioBtnEn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
    }
    
    NSTextField* languageTitle = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_languageTitle_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    ///主题设置
    NSTextField *themeTitle = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_themeTitle", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    NSTextField* themeDesc =[self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_themeDesc", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    
    NSButton *lightThemeRadioBtn = [[NSButton alloc]init];
    lightThemeRadioBtn.frame = NSMakeRect(0, 0, 14, 14);
    lightThemeRadioBtn.wantsLayer = YES;
    [lightThemeRadioBtn setBordered:NO];
    lightThemeRadioBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [lightThemeRadioBtn setButtonType:NSRadioButton];
    lightThemeRadioBtn.allowsMixedState = NO;
    lightThemeRadioBtn.target = self;
    [lightThemeRadioBtn setAction:@selector(changeThemeToLight:)];
    self.lightThemeRadioBtn = lightThemeRadioBtn;
    
    NSButton *darkThemeRadioBtn = [[NSButton alloc]init];
    darkThemeRadioBtn.frame = NSMakeRect(0, 0, 14, 14);
    darkThemeRadioBtn.wantsLayer = YES;
    [darkThemeRadioBtn setBordered:NO];
    darkThemeRadioBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [darkThemeRadioBtn setButtonType:NSRadioButton];
    darkThemeRadioBtn.allowsMixedState = NO;
    darkThemeRadioBtn.target = self;
    [darkThemeRadioBtn setAction:@selector(changeThemeToDark:)];
    self.darkThemeRadioBtn = darkThemeRadioBtn;
    
//    NSButton *followSystemThemeRadioBtn = [[NSButton alloc]init];
//    followSystemThemeRadioBtn.frame = NSMakeRect(0, 0, 14, 14);
//    followSystemThemeRadioBtn.wantsLayer = YES;
//    [followSystemThemeRadioBtn setBordered:NO];
//    followSystemThemeRadioBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
//    [followSystemThemeRadioBtn setButtonType:NSRadioButton];
//    followSystemThemeRadioBtn.allowsMixedState = NO;
//    followSystemThemeRadioBtn.target = self;
//    [followSystemThemeRadioBtn setAction:@selector(changeThemeToFollowSystem:)];
//
    NSButton *followSystemThemeRadioBtn = [self createRadioButtonWithSelector:@selector(changeThemeToFollowSystem:)];
    self.followSystemThemeRadioBtn = followSystemThemeRadioBtn;
    
    [self updateThemeRadioBtn];
    
    NSTextField* themeRadioBtnLightDesc = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_theme_radioBtn_lightDesc", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    NSTextField* themeRadioBtnDarkDesc = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_theme_radioBtn_darkDesc", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    NSTextField* followSystemThemeRadioBtnDesc = [self createLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_theme_radioBtn_follow_system", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    
    NSView* themeLineView = [[NSView alloc] init];
    self.themeLineView = themeLineView;
    
    [self.view addSubview:autoUnintallresidualTitle];
    [self.view addSubview:autoUnintallresidualDesc];
    [self.view addSubview:autoUninstallSwitch];
    
    //
    [self.view addSubview:dockTitle];
    [self.view addSubview:dockRadioBtnMin];
    [self.view addSubview:dockRadioBtnExit];
    [self.view addSubview:dockRadioBtnMinDes];
    [self.view addSubview:dockRadioBtnExitDes];
    [self.view addSubview:javaOsTipLabel];
    [self.view addSubview:systemSettingBtn];
    //    [self.view addSubview:dockLineView];
    
    //
    [self.view addSubview:languageLineView];
    [self.view addSubview:languageTitle];
    [self.view addSubview:languageRadioBtnCh];
    [self.view addSubview:languageRadioBtnChDesc];
    [self.view addSubview:languageRadioBtnEn];
    [self.view addSubview:languageRadioBtnEnDesc];
    
    ///主题设置
    [self.view addSubview:themeTitle];
    [self.view addSubview:themeDesc];
    [self.view addSubview:lightThemeRadioBtn];
    [self.view addSubview:darkThemeRadioBtn];
    [self.view addSubview:followSystemThemeRadioBtn];
    [self.view addSubview:themeRadioBtnDarkDesc];
    [self.view addSubview:themeRadioBtnLightDesc];
    [self.view addSubview:followSystemThemeRadioBtnDesc];
    [self.view addSubview:themeLineView];
    
    NSView *cView = self.view;
    ///setViewConstraints
    ///语言设置
    [languageTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cView).offset(28);
        make.top.equalTo(cView).offset(20);
    }];
    [languageRadioBtnCh mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(languageTitle.mas_right).offset(34);
        make.centerY.equalTo(languageTitle);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    [languageRadioBtnChDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(languageRadioBtnCh.mas_right).offset(8);
        make.centerY.equalTo(languageRadioBtnCh.mas_centerY);
    }];
    [languageRadioBtnEn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(languageRadioBtnChDesc.mas_right).offset(28);
        make.centerY.equalTo(languageRadioBtnCh);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    
    [languageRadioBtnEnDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(languageRadioBtnEn.mas_right).offset(8);
        make.centerY.equalTo(languageRadioBtnEn.mas_centerY);
    }];
    
    [languageLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(languageTitle.mas_bottom).offset(20);
        make.centerX.equalTo(cView);
        make.width.equalTo(cView);
        make.height.equalTo(@(1));
    }];
    
    ///主题设置
    [themeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(languageLineView.mas_bottom).offset(20);
        make.left.equalTo(cView).offset(28);
    }];
    
    if(@available(macOS 10.14,*)){
        [themeDesc setHidden:YES];
        [lightThemeRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(cView).offset(29);
            make.top.equalTo(themeTitle.mas_bottom).offset(11);
            make.width.equalTo(@(14));
            make.height.equalTo(@(14));
        }];
    }else{
        [themeDesc setHidden:NO];
        [lightThemeRadioBtn setEnabled:NO];
        [darkThemeRadioBtn setEnabled:NO];
        [followSystemThemeRadioBtn setEnabled:NO];
        [themeRadioBtnLightDesc setTextColor:[self getDisableTextColor]];
        [themeRadioBtnDarkDesc setTextColor:[self getDisableTextColor]];
        [followSystemThemeRadioBtnDesc setTextColor:[self getDisableTextColor]];
        [themeDesc mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(themeTitle.mas_bottom).offset(9);
            make.left.equalTo(cView).offset(28);
        }];
        [lightThemeRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(cView).offset(29);
            make.top.equalTo(themeDesc.mas_bottom).offset(8);
            make.width.equalTo(@(14));
            make.height.equalTo(@(14));
        }];
        
    }
    
    [themeRadioBtnLightDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lightThemeRadioBtn.mas_right).offset(8);
        make.centerY.equalTo(lightThemeRadioBtn.mas_centerY);
    }];
    [darkThemeRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(themeRadioBtnLightDesc.mas_right).offset(28);
        make.centerY.equalTo(themeRadioBtnLightDesc);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    [themeRadioBtnDarkDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(darkThemeRadioBtn.mas_right).offset(8);
        make.centerY.equalTo(darkThemeRadioBtn.mas_centerY);
    }];
    
    [followSystemThemeRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(themeRadioBtnDarkDesc.mas_right).offset(28);
        make.centerY.equalTo(themeRadioBtnDarkDesc);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    [followSystemThemeRadioBtnDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(followSystemThemeRadioBtn.mas_right).offset(8);
        make.centerY.equalTo(followSystemThemeRadioBtn.mas_centerY);
    }];
    
    [themeLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(themeRadioBtnLightDesc.mas_bottom).offset(20);
        make.left.equalTo(cView);
        make.width.equalTo(cView);
        make.height.equalTo(@1);
    }];
    
    ///自动检测卸载残留
    [autoUnintallresidualTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cView).offset(28);
        make.top.equalTo(themeLineView.mas_bottom).offset(20);
    }];
    [autoUninstallSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(autoUnintallresidualTitle.mas_centerY);
        make.right.equalTo(cView).offset(-30);
        make.width.equalTo(@(40));
        make.height.equalTo(@(19));
    }];
    [autoUnintallresidualDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(autoUnintallresidualTitle.mas_bottom).offset(9);
        make.leading.equalTo(cView).offset(29);
        make.right.equalTo(cView).offset(-20);
    }];
    
    [uninstallLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(autoUnintallresidualDesc.mas_bottom).offset(20);
        make.left.right.equalTo(cView);
        make.height.mas_equalTo(1);
    }];
    
    //MARK: constraint:废纸篓检测
    [trashSizeCheckTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(uninstallLineView.mas_bottom).offset(20);
        make.leading.equalTo(cView).offset(29);
    }];
    [trashSizeCheckSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
       make.centerY.equalTo(trashSizeCheckTitle.mas_centerY);
       make.right.equalTo(cView).offset(-30);
       make.width.equalTo(@(40));
       make.height.equalTo(@(19));
    }];
    [deleteFileRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(trashSizeCheckTitle);
        make.top.equalTo(trashSizeCheckTitle.mas_bottom).offset(11);
    }];
    [deleteFileRadioBtnDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(deleteFileRadioBtn.mas_right).offset(5);
        make.centerY.equalTo(deleteFileRadioBtn);
    }];
    [overSizeRadioBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(deleteFileRadioBtn.mas_bottom).offset(11);
        make.left.equalTo(deleteFileRadioBtn);
    }];
    [overSizeRadioBtnDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(overSizeRadioBtn.mas_right).offset(5);
        make.centerY.equalTo(overSizeRadioBtn);
    }];
    [popUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(overSizeRadioBtnDesc.mas_right).offset(5);
        make.centerY.equalTo(overSizeRadioBtnDesc);
        make.height.equalTo(@19);
        make.width.equalTo(@75);
    }];
    
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
         [overSizeRadioBtnDescEnd mas_makeConstraints:^(MASConstraintMaker *make) {
             make.left.equalTo(popUpButton.mas_right).offset(5);
             make.centerY.equalTo(popUpButton);
         }];
    }
    
    [trashSizeCheckLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(overSizeRadioBtn.mas_bottom).offset(20);
        make.left.right.equalTo(cView);
        make.height.mas_equalTo(1);
    }];
    
    ///关闭主面板
    [dockTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(trashSizeCheckLineView.mas_bottom).offset(20);
        make.leading.equalTo(cView).offset(29);
    }];
    [dockRadioBtnMin mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cView).offset(29);
        make.top.equalTo(dockTitle.mas_bottom).offset(11);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    [dockRadioBtnExit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dockRadioBtnMinDes.mas_right).offset(28);
        make.centerY.equalTo(dockRadioBtnMin);
        make.width.equalTo(@(14));
        make.height.equalTo(@(14));
    }];
    [dockRadioBtnMinDes mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dockRadioBtnMin.mas_right).offset(8);
        make.centerY.equalTo(dockRadioBtnMin.mas_centerY);
    }];
    
    [dockRadioBtnExitDes mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dockRadioBtnExit.mas_right).offset(8);
        make.centerY.equalTo(dockRadioBtnExit.mas_centerY);
    }];
    [javaOsTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dockRadioBtnMin.mas_bottom).offset(10);
        make.left.equalTo(dockRadioBtnMin.mas_left);
    }];
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        [systemSettingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(javaOsTipLabel.mas_bottom);
            make.left.equalTo(javaOsTipLabel.mas_right).offset(-5);
        }];
    }else{
        [systemSettingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(javaOsTipLabel);
            make.right.equalTo(cView).offset(-340);
        }];
    }
    
}

-(void)saveTrahCheckStatus: (BOOL)status{
    [SharedPrefrenceManager putBool:status withKey:IS_ENABLE_TRASH_WATCH];
    CFPreferencesSetAppValue((__bridge CFStringRef)(IS_ENABLE_TRASH_WATCH), (__bridge CFNumberRef)[NSNumber numberWithBool:status], (__bridge CFStringRef)MONITOR_APP_BUNDLEID);
    CFPreferencesAppSynchronize((__bridge CFStringRef)MONITOR_APP_BUNDLEID);
}

-(void)saveTrashSizeCheckStatus: (BOOL)status{
    NSLog(@"%s, set trash size watch: %d", __FUNCTION__, status);
    [SharedPrefrenceManager putBool:status withKey:IS_ENABLE_TRASH_SIZE_WATCH];
    if(!status){
        [self resetTrashSizeCheckRadioBtn];
        return;
    }
    //默认选择废纸篓大小超过1G时提醒
//    [self resetTrashSizeCheckRadioBtn];
    [self updateTrashSizeCheckRadioBtn];
//    [SharedPrefrenceManager putInteger:V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE withKey:K_TRASH_SIZE_WATCH_STATUS];
    
}

//-(void)saveTrashSizeThreshold{
//    NSLog(@"saveTrashSizeThreshold received notify...");
//    NSString *stringValue = self.inputSizeText.stringValue;
//    if([self isPureInt:stringValue]){
//        NSInteger size = stringValue.integerValue;
//        [SharedPrefrenceManager putInteger:size withKey:TRASH_SIZE_WATCH_THRESHOLD];
//        NSLog(@"%s, input size: %ld",__FUNCTION__, (long)size);
//    }
//
//}


-(void)openMonitor{
    NSLog(@"%s, open monitor", __FUNCTION__);
    NSError *error = NULL;
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:MONITOR_APP_PATH]
                                                                              options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation
                                                                        configuration:@{NSWorkspaceLaunchConfigurationArguments: @[[NSString stringWithFormat:@"%lu", LemonMonitorRunningMenu]]}
                                                                                error:&error];
    NSLog(@"%s, open lemon monitor: %@, %@",__FUNCTION__, app, error);
}


-(BOOL)isAppRunningBundleId: (NSString *)bundelId{
    NSArray *runnings= [NSRunningApplication runningApplicationsWithBundleIdentifier:bundelId];
    NSLog(@"%s, running %@:%@",__FUNCTION__, bundelId, runnings);
    return [runnings count] > 0;
}

-(CGPoint)getCenterPoint
{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}


-(void)openFullDiskPermissinGuideWindow{
    CGPoint centerPoint = [self getCenterPoint];
    if(!self.permissionGuideWndController){
        NSString *imageName = @"setstep_ch";
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            imageName = @"setstep_en";
        }
        NSString *title = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_full_disk_access_guide_window_title", nil, [NSBundle bundleForClass:[self class]], @"");
        NSString *descText = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_monitor_full_disk_access_guide_window_desc", nil, [NSBundle bundleForClass:[self class]], @"");
        self.permissionGuideWndController = [[LMPermissionGuideWndController alloc] initWithParaentCenterPos:centerPoint title:title descText:descText image:[NSImage imageNamed:imageName withClass:self.class] guideImageViewHeight:680];
        self.permissionGuideWndController.needCheckMonitorFullDiskAuthorizationStatus = YES;
        self.permissionGuideWndController.settingButtonEvent = ^{
            [QMFullDiskAccessManager openFullDiskAuthPrefreence];
        };
        __weak PreferenceViewController *weakSelf = self;
        self.permissionGuideWndController.finishButtonEvent = ^{
            NSLog(@"finishButtonEvent----");
            if(![weakSelf isAppRunningBundleId:MONITOR_APP_BUNDLEID]){
                [weakSelf openMonitor];
            }
            [SharedPrefrenceManager putBool:YES withKey:IS_ENABLE_TRASH_WATCH];
        };
    }
    [self.permissionGuideWndController loadWindow];
    [self.permissionGuideWndController.window makeKeyAndOrderFront:nil];
//    [self presentViewControllerAsModalWindow:self.permissionGuideWndController.contentViewController];

}

-(NSColor *)getDisableTextColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0x3B3D49];
        }else{
            return [NSColor colorWithHex:0xDCDCDC];
        }
    } else {
        return [NSColor colorWithHex:0xDCDCDC];
    }
}


-(void)updateThemeRadioBtn{
    //reset state
    self.darkThemeRadioBtn.state = NSControlStateValueOff;
    self.lightThemeRadioBtn.state = NSControlStateValueOff;
    self.followSystemThemeRadioBtn.state = NSControlStateValueOff;
    self.darkThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    self.lightThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    self.followSystemThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    
    NSInteger settedTheme = [[NSUserDefaults standardUserDefaults] integerForKey:K_THEME_MODE_SETTED];
    switch (settedTheme) {
        case V_LIGHT_MODE:
            self.lightThemeRadioBtn.state = NSControlStateValueOn;
            self.lightThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
            break;
        case V_DARK_MODE:
            self.darkThemeRadioBtn.state = NSControlStateValueOn;
            self.darkThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
            break;
        case V_FOLLOW_SYSTEM:
            self.followSystemThemeRadioBtn.state = NSControlStateValueOn;
            self.followSystemThemeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
            break;
        default:
            break;
    }
}

-(void)changeThemeToLight:(id)sender{
    if (@available(macOS 10.14, *)) {
        [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
        [self saveThemeSettedWith:V_LIGHT_MODE];
        [self updateThemeRadioBtn];
        [self sendNotifyForThemeChanged];
    } else {
        // Fallback on earlier versions
    }
    
}

-(void)changeThemeToDark:(id)sender{
    if (@available(macOS 10.14, *)) {
        [[NSApplication sharedApplication] setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
        [self saveThemeSettedWith:V_DARK_MODE];
        [self updateThemeRadioBtn];
        [self sendNotifyForThemeChanged];
    } else {
        // Fallback on earlier versions
    }
}

-(void)changeThemeToFollowSystem:(id)sender{
    [[NSApplication sharedApplication] setAppearance:nil];
    [self saveThemeSettedWith:V_FOLLOW_SYSTEM];
    [self updateThemeRadioBtn];
    [self sendNotifyForThemeChanged];
}

-(void)saveThemeSettedWith:(int)themeSetted{
    [[NSUserDefaults standardUserDefaults] setInteger:themeSetted forKey:K_THEME_MODE_SETTED];
    CFPreferencesSetAppValue((__bridge CFStringRef)(K_THEME_MODE_SETTED), (__bridge CFNumberRef)[NSNumber numberWithInt:themeSetted], (__bridge CFStringRef)MONITOR_APP_BUNDLEID);
    CFPreferencesAppSynchronize((__bridge CFStringRef)MONITOR_APP_BUNDLEID);
}

-(void)sendNotifyForThemeChanged{
     [[NSDistributedNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_THEME_CHANGED object:nil userInfo:nil  deliverImmediately:YES];
}

-(BOOL)checkFullDiskAuthorizationStatus{
     if (@available(macOS 10.15, *))
     {
        return [QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized;
     }
    return YES;
}

-(void)gotoSystemSettingPage{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Dock.prefPane"];
}

-(void)dockMinValueChange:(id)sender
{
    NSButton* radioBtn = (NSButton*)sender;
    if (radioBtn.state == NSControlStateValueOn)
    {
        
        [SharedPrefrenceManager putBool:YES withKey:DOCK_ON_OFF_STATE];
        
        ((NSButton*)_myRadioControls[@0]).state = NSControlStateValueOff;
        ((NSButton*)_myRadioControls[@1]).state = NSControlStateValueOn;
        ((NSButton*)_myRadioControls[@0]).image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
        ((NSButton*)_myRadioControls[@1]).image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
    }
}

-(void)dockExitValueChange:(id)sender
{
    NSButton* radioBtn = (NSButton*)sender;
    if (radioBtn.state == NSControlStateValueOn)
    {
        
        [SharedPrefrenceManager putBool:NO withKey:DOCK_ON_OFF_STATE];
        
        ((NSButton*)_myRadioControls[@0]).state = NSControlStateValueOn;
        ((NSButton*)_myRadioControls[@1]).state = NSControlStateValueOff;
        ((NSButton*)_myRadioControls[@0]).image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
        ((NSButton*)_myRadioControls[@1]).image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    }
}

-(void)languageChangeToCh:(id)sender{
    if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
        return;
    }
    [self changeAppLanguageByLanguageString:@"zh-Hans"];
}

-(void)languageChangeToEn:(id)sender{
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        return;
    }
    [self changeAppLanguageByLanguageString:@"en"];
}

-(void)changeAppLanguageByLanguageString:(NSString *)languageString{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert.accessoryView setFrameOrigin:NSMakePoint(0, 0)];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_startAlertWindow_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
    alert.informativeText = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_startAlertWindow_alert_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_startAlertWindow_alert_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_startAlertWindow_alert_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [LanguageHelper setCurrentUserLanguage:languageString];
            NSLog(@"change language send user_language_change noti");
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"user_language_change" object:nil userInfo:nil  deliverImmediately:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"need_relaunch_app" object:nil];
        }
    }];
}

-(void)trashSizeCheckWhenDeleteFile{
    
    [SharedPrefrenceManager putInteger:V_TRASH_SIZE_WATCH_WHEN_DELETE_FILE withKey:K_TRASH_SIZE_WATCH_STATUS];
    [self updateTrashSizeCheckRadioBtn];
}

-(void)trashSizeCheckWhenOverSize{
    [SharedPrefrenceManager putInteger:V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE withKey:K_TRASH_SIZE_WATCH_STATUS];
//    [SharedPrefrenceManager putInteger:10 withKey:TRASH_SIZE_WATCH_THRESHOLD];
    [self updateTrashSizeCheckRadioBtn];
}

-(void)updateTrashSizeCheckRadioBtn{
    [self resetTrashSizeCheckRadioBtn];
    if(!self.trashSizeCheckSwitch.isOn)
        return;
    NSInteger status = [SharedPrefrenceManager getInteger:K_TRASH_SIZE_WATCH_STATUS];
    switch (status) {
        case V_TRASH_SIZE_WATCH_DISABLE:
            break;
        case V_TRASH_SIZE_WATCH_WHEN_DELETE_FILE:
           [self.deleteFileRadioBtn setEnabled: YES];
            [self.overSizeRadioBtn setEnabled: YES];
            [self.popUpButton setEnabled:NO];
            self.deleteFileRadioBtn.state = NSControlStateValueOn;
            self.deleteFileRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
            break;
        case 0:
        case V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE:
            [self.deleteFileRadioBtn setEnabled: YES];
            [self.overSizeRadioBtn setEnabled: YES];
            [self.popUpButton setEnabled:YES];
            self.overSizeRadioBtn.state = NSControlStateValueOn;
            self.overSizeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
            break;
            
        default:
            break;
    }
}

-(void)resetTrashSizeCheckRadioBtn{
    self.deleteFileRadioBtn.state = NSControlStateValueOff;
    self.overSizeRadioBtn.state = NSControlStateValueOff;
    self.deleteFileRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    self.overSizeRadioBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    [self.deleteFileRadioBtn setEnabled: NO];
    [self.overSizeRadioBtn setEnabled: NO];
    [self.popUpButton setEnabled: NO];
}

-(void)initPopUpButton{
    NSInteger savedThreshold = [SharedPrefrenceManager getInteger: TRASH_SIZE_WATCH_THRESHOLD];
    switch (savedThreshold) {
        case 500:
            [self.popUpButton selectItemAtIndex:0];
            break;
        case 0:
        case 1024:
            [self.popUpButton selectItemAtIndex:1];
            
            break;
        case 2048:
            [self.popUpButton selectItemAtIndex:2];
        default:
            break;
    }
       
}

-(void)popUpBtnAction: (NSPopUpButton *)sender{
    NSInteger index = sender.indexOfSelectedItem;
    NSInteger size = 1024;
    switch (index) {
        case 0:
            size = 500;
            
        break;
        case 1:
            size = 1024;
            
        break;
        case 2:
            size = 2048;
            
        default:
            break;
    }
    [SharedPrefrenceManager putInteger:size withKey:TRASH_SIZE_WATCH_THRESHOLD];
    NSLog(@"%s,selected size : %ld", __FUNCTION__, (long)size);
}



@end
