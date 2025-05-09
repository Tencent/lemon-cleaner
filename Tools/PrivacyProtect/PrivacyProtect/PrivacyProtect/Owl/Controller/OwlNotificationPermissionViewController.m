//
//  OwlNotificationPermissionViewController.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlNotificationPermissionViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import "OwlViewController.h"
#import <QMCoreFunction/LanguageHelper.h>

@interface OwlNotificationPermissionViewController ()

@property (nonatomic) NSRect frame;

@property (nonatomic, strong) NSImageView *warnImageView;

@property (nonatomic, strong) NSTextField *titleTF;
@property (nonatomic, strong) NSTextField *descTF;
@property (nonatomic, strong) NSTextField *stepTF;

@property (nonatomic, strong) NSImageView *stepImageView;

@property (nonatomic, strong) NSButton *cancelBtn;

@property (nonatomic, strong) NSButton *goSettingBtn;

@end

@implementation OwlNotificationPermissionViewController

- (void)dealloc {
    
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super init];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:self.frame];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubviews];
    [self setupSubviewsLayout];
}

- (void)viewWillAppear {
    [super viewWillAppear];
}

- (void)setupSubviews {
    [self.view addSubview:self.warnImageView];
    [self.view addSubview:self.titleTF];
    [self.view addSubview:self.descTF];
    [self.view addSubview:self.stepTF];
    [self.view addSubview:self.stepImageView];
    [self.view addSubview:self.cancelBtn];
    [self.view addSubview:self.goSettingBtn];
}

- (void)setupSubviewsLayout {
    // top --> bottom
    [self.warnImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.top.mas_equalTo(44);
        make.size.mas_equalTo(NSMakeSize(40, 40));
    }];
    
    [self.titleTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.warnImageView.mas_right).offset(16);
        make.right.mas_equalTo(-20);
        make.top.mas_equalTo(44);
    }];
    
    [self.descTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titleTF.mas_left);
        make.top.mas_equalTo(self.titleTF.mas_bottom).offset(8);
        make.right.mas_equalTo(-20);
    }];
    
    [self.stepTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.descTF.mas_left);
        make.top.mas_equalTo(self.descTF.mas_bottom).offset(8);
        make.right.mas_equalTo(-20);
    }];
    
    [self.stepImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(76);
        make.top.mas_equalTo(self.stepTF.mas_bottom).offset(8);
        make.size.mas_equalTo(NSMakeSize(480, 280));
    }];
    
    //bottom --> top
    [self.goSettingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-36);
        make.bottom.mas_equalTo(-16);
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            make.size.mas_equalTo(NSMakeSize(100, 24));
        } else {
            make.size.mas_equalTo(NSMakeSize(68, 24));
        }
    }];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.goSettingBtn.mas_left).offset(-8);
        make.bottom.mas_equalTo(self.goSettingBtn.mas_bottom);
        make.size.mas_equalTo(NSMakeSize(48, 24));
    }];
}

#pragma mark - action

- (void)cancelBtnClicked:(NSButton *)btn {
    NSLog(@"cancelBtnClicked");
    [self.view.window close];
    ((OwlViewController*)self.view.window.parentWindow.contentViewController).npWindowController = nil;
}

- (void)goSettingBtnClicked:(NSButton *)btn {
    NSLog(@"goSettingBtnClicked");
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.notifications"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark - getter

- (NSImageView *)warnImageView {
    if (!_warnImageView) {
        _warnImageView = [[NSImageView alloc] init];
        _warnImageView.image = [[NSBundle bundleForClass:[self class]] imageForResource:@"owl_warn_icon"];
        _warnImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    return _warnImageView;
}

- (NSTextField *)titleTF {
    if (!_titleTF) {
        _titleTF = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
        _titleTF.stringValue = NSLocalizedStringFromTableInBundle(@"请开启通知提醒权限", nil, [NSBundle bundleForClass:[self class]], nil);
    }
    return _titleTF;
}


- (NSTextField *)descTF {
    if (!_descTF) {
        _descTF = [[NSTextField alloc] initWithFrame:NSZeroRect];
        _descTF.bordered = NO;
        _descTF.editable = NO;
        _descTF.drawsBackground = NO;
        _descTF.font = [NSFontHelper getLightSystemFont:14];
        _descTF.textColor = [LMAppThemeHelper getTitleColor];
        _descTF.stringValue = NSLocalizedStringFromTableInBundle(@"若存在摄像头、麦克风或扬声器等隐私设备被调用情况，将发送通知告知隐私保护的情况", nil, [NSBundle bundleForClass:[self class]], nil);
    }
    return _descTF;
}

- (NSTextField *)stepTF {
    if (!_stepTF) {
        _stepTF = [[NSTextField alloc] initWithFrame:NSZeroRect];
        _stepTF.bordered = NO;
        _stepTF.editable = NO;
        _stepTF.drawsBackground = NO;
        _stepTF.font = [NSFontHelper getLightSystemFont:14];
        _stepTF.textColor = [NSColor colorWithHex:0x94979B];
        _stepTF.stringValue = NSLocalizedStringFromTableInBundle(@"步骤：\n【系统设置】——【通知】——【应用程序通知】——开启【LemonMonitor】", nil, [NSBundle bundleForClass:[self class]], nil);
    }
    return _stepTF;
}

- (NSImageView *)stepImageView {
    if (!_stepImageView) {
        _stepImageView = [[NSImageView alloc] init];
        _stepImageView.image = [[NSBundle bundleForClass:[self class]] imageForResource:@"owl_notification_step"];
        _stepImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    return _stepImageView;
}


- (NSButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[LMBorderButton alloc] init];
        _cancelBtn.title = NSLocalizedStringFromTableInBundle(@"取消", nil, [NSBundle bundleForClass:[self class]], @"");
        _cancelBtn.target = self;
        _cancelBtn.action = @selector(cancelBtnClicked:);
        _cancelBtn.font = [NSFontHelper getRegularSystemFont:12];
    }
    return _cancelBtn;
}

- (NSButton *)goSettingBtn {
    if (!_goSettingBtn) {
        _goSettingBtn = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"前往设置", nil, [NSBundle bundleForClass:[self class]], nil)];
        _goSettingBtn.wantsLayer = YES;
        _goSettingBtn.layer.cornerRadius = 2;
        _goSettingBtn.target = self;
        _goSettingBtn.action = @selector(goSettingBtnClicked:);
    }
    return _goSettingBtn;
}

@end
