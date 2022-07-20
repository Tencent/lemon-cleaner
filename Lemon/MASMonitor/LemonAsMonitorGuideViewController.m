//
//  LemonAsMonitorGuideVIewController.m
//  Lemon
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LemonAsMonitorGuideViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMGradientTitleButton.h>
#import "QMUICommon/LMBorderButton.h"
#import "QMUICommon/LMRectangleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import "MasLoginItemManager.h"
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LemonSuiteUserDefaults.h>

#define CAN_MAS_MONITOR_START @"can_mas_monitor_start"

typedef NS_ENUM(NSUInteger, UserSelectType) {
    UserSelectTypeNoSelect,
    UserSelectTypeSelectOnce,
    UserSelectTypeSelectAlways,
};

@interface LemonAsMonitorGuideViewController ()

@property (nonatomic, assign) UserSelectType selectType;
@property (nonatomic, weak) NSButton *onceBtn;//仅本次展示
@property (nonatomic, weak) NSButton *alwayBtn;//开机默认显示
@property (nonatomic, weak) NSButton *showBtn;//确认按钮

@end

@implementation LemonAsMonitorGuideViewController

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 420, 220);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    
    view.wantsLayer = YES;
    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    view.layer.cornerRadius = 5;
    view.layer.masksToBounds = YES;
    self.view = view;
//    [self viewDidLoad];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectType = UserSelectTypeNoSelect;
    [self setupWindow];
    [self setupViews];
}

- (void)setupWindow {
//    self.view.window.delegate = self;
    self.view.window.title = @"";
    self.title = @"";
}

- (void)viewWillAppear {
    NSWindow *window = self.view.window;
    if (window) {
        window.titleVisibility = NSWindowTitleHidden;
        window.titlebarAppearsTransparent = YES;
        window.styleMask = NSWindowStyleMaskFullSizeContentView ;
        
        
        window.opaque = NO;
        window.showsToolbarButton = NO;
        //        window.movableByWindowBackground = YES; //window 可随拖动移动
        [window setBackgroundColor:[NSColor clearColor]];
        
        CGFloat xPos = NSWidth([[window screen] frame])/2 - NSWidth([window frame])/2;
        CGFloat yPos = NSHeight([[window screen] frame])/2 - NSHeight([window frame])/2;
        if(_parentViewController){
            NSWindow *parentWindow = _parentViewController.view.window;
            if (parentWindow) {
                xPos = NSWidth([parentWindow frame])/2 - NSWidth([window frame])/2 + parentWindow.frame.origin.x;
                yPos = NSHeight([parentWindow frame])/2 - NSHeight([window frame])/2 + parentWindow.frame.origin.y;
            }
        }
        
        [window setFrame:NSMakeRect(xPos, yPos, NSWidth([window frame]), NSHeight([window frame])) display:YES];
    }
}

- (void)setupViews{
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:titleLabel];
    titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    titleLabel.maximumNumberOfLines = 2;
    
    //副标题
    NSTextField *descLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979b]];
    [self.view addSubview:descLabel];
    descLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_descLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    descLabel.maximumNumberOfLines = 2;
    
    NSButton *onceBtn = [[NSButton alloc]init];
    onceBtn.frame = NSMakeRect(0, 0, 14, 14);
    onceBtn.wantsLayer = YES;
    [onceBtn setBordered:NO];
    onceBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [onceBtn setButtonType:NSRadioButton];
    onceBtn.allowsMixedState = NO;
    onceBtn.target = self;
    [onceBtn setAction:@selector(onceDockBtnClick:)];
    onceBtn.state = NSControlStateValueOff;
    [self.view addSubview:onceBtn];
    self.onceBtn = onceBtn;
    
    NSTextField *onceTitle = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:onceTitle];
    onceTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_onceTitle_1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSButton *alwayBtn = [[NSButton alloc]init];
    alwayBtn.frame = NSMakeRect(0, 0, 14, 14);
    alwayBtn.wantsLayer = YES;
    [alwayBtn setBordered:NO];
    alwayBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    [alwayBtn setButtonType:NSRadioButton];
    alwayBtn.allowsMixedState = NO;
    alwayBtn.target = self;
    [alwayBtn setAction:@selector(alwaysDockBtnClick:)];
    alwayBtn.state = NSControlStateValueOff;
    [self.view addSubview:alwayBtn];
    self.alwayBtn = alwayBtn;
    
    NSTextField *alwayTitle = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:alwayTitle];
    alwayTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_alwayTitle_1", nil, [NSBundle bundleForClass:[self class]], @"");;
    
    NSString *showString = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_showString _2", nil, [NSBundle bundleForClass:[self class]], @"");
//NSLocalizedStringFromTableInBundle(@"RunningAppPopViewController_setupViews_cancelButton_2", nil, [NSBundle bundleForClass:[self class]], @"")
    NSButton *showButton = [LMViewHelper createSmallGreenButton:12 title:showString];
    [self.view addSubview:showButton];
    showButton.wantsLayer = YES;
    showButton.layer.cornerRadius = 2;
    showButton.target = self;
    showButton.enabled = NO;
    showButton.action = @selector(onShowStatusBarIconButtonClick);
    self.showBtn = showButton;
    
    NSString *cancelString = NSLocalizedStringFromTableInBundle(@"LemonAsMonitorGuideViewController_setupViews_cancelString _3", nil, [NSBundle bundleForClass:[self class]], @"");
    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    cancelButton.title = cancelString;
    cancelButton.target = self;
    cancelButton.action = @selector(onCancelButtonClick);
    cancelButton.font = [NSFont systemFontOfSize:12];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(31);
        make.left.equalTo(self.view).offset(44);
        make.width.lessThanOrEqualTo(@334);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(7);
        make.left.equalTo(self.view).offset(44);
        make.width.lessThanOrEqualTo(@334);
    }];
    
    [onceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(descLabel.mas_bottom).offset(19);
        make.left.equalTo(self.view).offset(45);
        make.width.equalTo(@14);
        make.height.equalTo(@14);
    }];
    
    [onceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(onceBtn.mas_right).offset(12);
        make.centerY.equalTo(onceBtn);
    }];
    
    [alwayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(onceBtn.mas_bottom).offset(19);
        make.left.equalTo(self.view).offset(45);
        make.width.equalTo(@14);
        make.height.equalTo(@14);
    }];
    
    [alwayTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(alwayBtn.mas_right).offset(12);
        make.centerY.equalTo(alwayBtn);
    }];
    
    [showButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(24);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view).offset(-10);
    }];
    
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(24);
        make.right.equalTo(showButton.mas_left).offset(-10);
        make.centerY.equalTo(showButton);
    }];

}

-(void)onceDockBtnClick:(id)sender{
    self.selectType = UserSelectTypeSelectOnce;
    self.alwayBtn.state = NSControlStateValueOff;
    self.onceBtn.state = NSControlStateValueOn;
    self.alwayBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    self.onceBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
    if (!self.showBtn.enabled) {
        self.showBtn.enabled = YES;
    }
}

-(void)alwaysDockBtnClick:(id)sender{
    self.selectType = UserSelectTypeSelectAlways;
    self.alwayBtn.state = NSControlStateValueOn;
    self.onceBtn.state = NSControlStateValueOff;
    self.alwayBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_down"];
    self.onceBtn.image = [[NSBundle mainBundle] imageForResource:@"radio_normal"];
    if (!self.showBtn.enabled) {
        self.showBtn.enabled = YES;
    }
}

- (void)onShowStatusBarIconButtonClick{
//    NSLog(@"%s", __FUNCTION__);
    [[MasLoginItemManager sharedManager] disAbleLoginItem];
    
    if (self.selectType == UserSelectTypeSelectAlways) {
        NSLog(@"select UserSelectTypeSelectAlways set IS_USER_REGISTER_LOGIN_ITEM to yes");
        [LemonSuiteUserDefaults putBool:YES withKey:IS_USER_REGISTER_LOGIN_ITEM];
    }else if(self.selectType == UserSelectTypeSelectOnce){
        NSLog(@"select UserSelectTypeSelectOnce set IS_USER_REGISTER_LOGIN_ITEM to false");
        [LemonSuiteUserDefaults putBool:NO withKey:IS_USER_REGISTER_LOGIN_ITEM];
        [LemonSuiteUserDefaults putBool:YES withKey:CAN_MAS_MONITOR_START];
        [LemonSuiteUserDefaults putBool:YES withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
    }
    
    [[MasLoginItemManager sharedManager] enableLoginItemAndXpcAtGuidePage];
    
    [self.view.window close];
}

- (void)onCancelButtonClick{
//    NSLog(@"%s", __FUNCTION__);    
    [self.view.window close];
    
    NSLog(@"set IS_USER_REGISTER_LOGIN_ITEM to false");
    [[MasLoginItemManager sharedManager] disAbleLoginItem];
    [LemonSuiteUserDefaults putBool:NO withKey:IS_USER_REGISTER_LOGIN_ITEM];
    [LemonSuiteUserDefaults putBool:NO withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
}
@end
