//
//  PreferenceASViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

/*
 重要注释：
    1、IS_USER_REGISTER_LOGIN_ITEM 这个主要用于记录是否注册，注册成功则开机启动，否则开机不启动。
    loginItemSwitch是一个开关，
        打开时候先判断loginItem进程是否在，并且设置IS_USER_REGISTER_LOGIN_ITEM为YES
                             如果不在，在判断是否注册了IS_OPEN_REGISTER_LOGIN_ITEM，
                                     如果注册，则执行disAbleLoginItem，并且将IS_OPEN_REGISTER_LOGIN_ITEM设置为NO，并拉起托盘
                                     如果没有注册，直接拉起托盘即可
                              如果在，则什么事情都不干
        关闭的时候同样判断loginItem进程是否在
                              如果不在，判断IS_OPEN_REGISTER_LOGIN_ITEM是否注册
                                      如果注册，取消注册，并且设置IS_USER_REGISTER_LOGIN_ITEM和IS_OPEN_REGISTER_LOGIN_ITEM为NO
                                       如果没注册，设置IS_USER_REGISTER_LOGIN_ITEM和IS_OPEN_REGISTER_LOGIN_ITEM为NO
 
                               如果在，弹出alert窗口
                                    选择取消，则什么事情都不干
                                    选择确认，则disAbleLoginItem，并且设置IS_USER_REGISTER_LOGIN_ITEM和IS_OPEN_REGISTER_LOGIN_ITEM为NO
    2、IS_OPEN_REGISTER_LOGIN_ITEM 是否临时打开来注册Loginitem
            打开判断IS_USER_REGISTER_LOGIN_ITEM是否注册，并且设置CAN_MAS_MONITOR_START和IS_OPEN_REGISTER_LOGIN_ITEM为YES
                              如果注册，则执行disAbleLoginItem，拉起托盘
                              如果没有注册，拉起托盘
            关闭判断isUserRegister是否注册，并且设置CAN_MAS_MONITOR_START和IS_OPEN_REGISTER_LOGIN_ITEM为NO
                              如果注册，则执行notiMonitorExit通知托盘临时退出
                              如果没有注册，则执行disAbleLoginItem方法
    3、CAN_MAS_MONITOR_START 主要是与IS_USER_REGISTER_LOGIN_ITEM配合使用，在loginItem启动时候，判断这两个当中是否有一个为YES，否则就kill self不进行启动
 
 
 */

#import "PreferenceASViewController.h"
#import <QMUICommon/COSwitch.h>
#import <Masonry/Masonry.h>
#import "MasLoginItemManager.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LemonSuiteUserDefaults.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMCoreFunction/NSFont+Extension.h>

#define LOGIN_ITEM_BUNDLEID @"88L2Q4487U.com.tencent.LemonASMonitor"
#define MAS_MONITOR_EXIT @"mas_nonitor_exit"
#define MAS_MONITOR_START_SUCCESS @"mas_nonitor_start_scuess"
#define CAN_MAS_MONITOR_START @"can_mas_monitor_start"
#define IS_SET_REGISTER_OPEN  @"is_set_register_open"
#define MAS_SHOW_STATUS_BAR_GUIDE @"mas_show_status_bar_guide" //发送app store的通知

@interface PreferenceASViewController ()

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSView *seprateLineView;
@property (weak) IBOutlet NSTextField *openActionTitle;
@property (weak) IBOutlet NSTextField *openActionDesc;
@property (weak) IBOutlet NSView *seprateLIneView1;
@property (weak) IBOutlet NSTextField *statusActionTitle;
@property (weak) IBOutlet NSTextField *statusActionDesc;
@property (strong, nonatomic) COSwitch *loginItemSwitch;
@property (strong, nonatomic) COSwitch *openItemSwitch;

@end

@implementation PreferenceASViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(masMonitorExit) name:MAS_MONITOR_EXIT object:nil];
    [self initView];
}

//检测mas monitor是否退出
-(void)masMonitorExit{
    self.openItemSwitch.on = NO;
}

-(void)dealloc{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

-(void)initView{
    [self.view setWantsLayer:YES];
    [self.view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [self.seprateLineView setWantsLayer:YES];
    [self.seprateLineView.layer setBackgroundColor:[NSColor colorWithHex:0x000000 alpha:0.05].CGColor];
    [self.seprateLIneView1 setWantsLayer:YES];
    [self.seprateLIneView1.layer setBackgroundColor:[NSColor colorWithHex:0x000000 alpha:0.05].CGColor];
    
    [self.titleLabel setTextColor:[NSColor colorWithHex:0x515151]];
    [self.openActionTitle setTextColor:[NSColor colorWithHex:0x515151]];
    [self.openActionDesc setTextColor:[NSColor colorWithHex:0x94979b]];
    [self.openActionDesc setFont:[NSFontHelper getLightSystemFont:12]];
    self.openActionDesc.maximumNumberOfLines = 2;
    [self.statusActionTitle setTextColor:[NSColor colorWithHex:0x515151]];
    [self.statusActionDesc setTextColor:[NSColor colorWithHex:0x94979b]];
    [self.statusActionDesc setFont:[NSFontHelper getLightSystemFont:12]];
    self.statusActionDesc.maximumNumberOfLines = 2;
    [self.titleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_initView_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.openActionTitle setStringValue:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_initView_openActionTitle_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.openActionDesc setStringValue:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_initView_openActionDesc_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.statusActionTitle setStringValue:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_initView_statusActionTitle_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.statusActionDesc setStringValue:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_initView_statusActionDesc_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    //register 开关
    COSwitch *loginItemSwitch = [[COSwitch alloc] init];
    BOOL isOn = [LemonSuiteUserDefaults getBool:IS_USER_REGISTER_LOGIN_ITEM];
    NSLog(@"loginItemSwitch set is on = %d", isOn);
    loginItemSwitch.on = isOn;
    
    [loginItemSwitch setOnValueChanged:^(COSwitch *button) {
        BOOL btnState = button.isOn;
        BOOL isLoginItemRunning = [[MasLoginItemManager sharedManager] isMASLoginItemRunning];
        BOOL isOpenRegister = [LemonSuiteUserDefaults getBool:IS_OPEN_REGISTER_LOGIN_ITEM];
        if (btnState) {
            NSLog(@"loginItemSwitch开");
            [SharedPrefrenceManager putBool:YES withKey:MAS_SHOW_STATUS_BAR_GUIDE];
            //如果当前item不在运行  并且没有手动打开注册过
            if (!isLoginItemRunning && !isOpenRegister) {
                [LemonSuiteUserDefaults putBool:YES withKey:IS_SET_REGISTER_OPEN];
                [[MasLoginItemManager sharedManager] enableLoginItemAndXpcAtGuidePage];
                [LemonSuiteUserDefaults putBool:YES withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
            }else{
                [LemonSuiteUserDefaults putBool:NO withKey:IS_SET_REGISTER_OPEN];
            }
            
            NSLog(@"set IS_USER_REGISTER_LOGIN_ITEM to yes");
            [LemonSuiteUserDefaults putBool:YES withKey:IS_USER_REGISTER_LOGIN_ITEM];
            
            
        }else{
            NSLog(@"loginItemSwitch关");
            if (!isLoginItemRunning && isOpenRegister){
                //如果当前item不在  并且open注册过
                [[MasLoginItemManager sharedManager] disAbleLoginItem];
                [LemonSuiteUserDefaults putBool:NO withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
            }
            NSLog(@"set IS_USER_REGISTER_LOGIN_ITEM to false");
            [LemonSuiteUserDefaults putBool:NO withKey:IS_USER_REGISTER_LOGIN_ITEM];
            
        }
    }];
    [self.view addSubview:loginItemSwitch];
    self.loginItemSwitch = loginItemSwitch;
    
    //打开开关
    COSwitch *openItemSwitch = [[COSwitch alloc] init];
//    openItemSwitch.on = [LemonSuiteUserDefaults getBool:IS_USER_REGISTER_LOGIN_ITEM];
    openItemSwitch.on = [[MasLoginItemManager sharedManager] isMASLoginItemRunning];
    
    [openItemSwitch setOnValueChanged:^(COSwitch *button) {
        BOOL btnState = button.isOn;
        BOOL isUserRegister = [LemonSuiteUserDefaults getBool:IS_USER_REGISTER_LOGIN_ITEM];
        BOOL isOpenRegister = [LemonSuiteUserDefaults getBool:IS_OPEN_REGISTER_LOGIN_ITEM];
        if (btnState) {
            NSLog(@"openItemSwitch开");
            [SharedPrefrenceManager putBool:YES withKey:MAS_SHOW_STATUS_BAR_GUIDE];
            [LemonSuiteUserDefaults putBool:YES withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
            [LemonSuiteUserDefaults putBool:YES withKey:CAN_MAS_MONITOR_START];
            if (isOpenRegister) {
                [[MasLoginItemManager sharedManager] disAbleLoginItem];
            }
            
            [[MasLoginItemManager sharedManager] enableLoginItemAndXpcAtGuidePage];
            
        }else{
            NSLog(@"openItemSwitch关");
            if (isUserRegister) {
                [[MasLoginItemManager sharedManager] notiMonitorExit];
            }else{
                [[MasLoginItemManager sharedManager] disAbleLoginItem];
                [LemonSuiteUserDefaults putBool:NO withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
            }
            [LemonSuiteUserDefaults putBool:NO withKey:CAN_MAS_MONITOR_START];
            
        }
    }];
    [self.view addSubview:openItemSwitch];
    self.openItemSwitch = openItemSwitch;
    
    [self.openActionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(27);
        make.top.equalTo(self.seprateLineView.mas_bottom).offset(19);
        make.width.lessThanOrEqualTo(@234);
    }];
    
    [openItemSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.openActionTitle.mas_centerY);
        make.right.equalTo(self.view).offset(-23);
        make.width.equalTo(@(40));
        make.height.equalTo(@(20));
    }];
    
    [self.openActionDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(28);
        make.top.equalTo(self.openActionTitle.mas_bottom).offset(7);
        make.width.lessThanOrEqualTo(@300);
    }];
    
    NSInteger offset = 0;
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        offset = 83;
    }else{
        offset = 93;
    }
    [self.seprateLIneView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.seprateLineView.mas_bottom).offset(offset);
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.equalTo(@1);
    }];
    
    [self.statusActionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(27);
        make.top.equalTo(self.seprateLIneView1).offset(20);
        make.width.lessThanOrEqualTo(@234);
    }];
    
    [loginItemSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.statusActionTitle);
        make.right.equalTo(self.view).offset(-23);
        make.width.equalTo(@(40));
        make.height.equalTo(@(20));
    }];
    
    [self.statusActionDesc mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(28);
        make.top.equalTo(self.statusActionTitle.mas_bottom).offset(9);
        make.width.lessThanOrEqualTo(@298);
    }];
}

-(void)startAlertWindow{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert.accessoryView setFrameOrigin:NSMakePoint(0, 0)];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_startAlertWindow_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
    alert.informativeText = NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_startAlertWindow_alert_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_startAlertWindow_alert_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"PreferenceASViewController_startAlertWindow_alert_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    __weak PreferenceASViewController *weakSelf = self;
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [[MasLoginItemManager sharedManager] disAbleLoginItem];
            weakSelf.openItemSwitch.on = NO;
            [LemonSuiteUserDefaults putBool:NO withKey:IS_USER_REGISTER_LOGIN_ITEM];
            [LemonSuiteUserDefaults putBool:NO withKey:IS_OPEN_REGISTER_LOGIN_ITEM];
            
            
        }else{
            weakSelf.loginItemSwitch.on = YES;
        }
    }];
}

@end
