//
//  LMVisibleViewController.m
//  LemonMonitor
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMVisibleViewController.h"
#import "LMUpdatePopoverRootView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMRectangleButton.h>
#import <QMUICommon/LMViewHelper.h>
#import "LemonDaemonConst.h"
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/LanguageHelper.h>

@interface LMVisibleViewController ()

@property(nonatomic, strong) NSTextField *tipTextFiled;
@property(nonatomic, strong) LMRectangleButton *prefenceBtn;
@property(nonatomic, strong) LMBorderButton *cancelBtn;
@end

@implementation LMVisibleViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {

    
    self.tipTextFiled = [[NSTextField alloc] init];
    self.tipTextFiled.stringValue = NSLocalizedStringFromTableInBundle(@"beObscured", nil, [NSBundle bundleForClass:[self class]], @"");
    self.tipTextFiled.font = [NSFont systemFontOfSize:14.0f];
    self.tipTextFiled.bordered = NO;
    self.tipTextFiled.editable = NO;
    self.tipTextFiled.maximumNumberOfLines = 5;
    self.tipTextFiled.backgroundColor = [NSColor clearColor];
//    self.tipTextFiled.lineBreakMode = NSLineBreakByCharWrapping;
    [self.view addSubview:self.tipTextFiled];
    
    [self.tipTextFiled mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(20);
        make.width.mas_equalTo(240);
        make.centerX.equalTo(self.view);
    }];

    NSString *cancelString = NSLocalizedStringFromTableInBundle(@"Cancel_Tip", nil, [NSBundle mainBundle], @"");
    LMBorderButton *cancelBtn = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelBtn];
    cancelBtn.title = cancelString;
    cancelBtn.alignment = NSTextAlignmentLeft;
    cancelBtn.target = self;
    cancelBtn.action = @selector(onKnowBtn);
    cancelBtn.font = [NSFont systemFontOfSize:12.0];
    cancelBtn.borderWidth = 0;
    self.cancelBtn = cancelBtn;
    
}
- (void)setNeedPrefence:(BOOL)needPrefence {
    _needPrefence = needPrefence;
    if (self.needPrefence == YES) {
        //
        self.prefenceBtn = [[LMRectangleButton alloc] init];
        self.prefenceBtn.target = self;
        self.prefenceBtn.action = @selector(btnSelectAction);
        self.prefenceBtn.bordered = NO;
        NSDictionary * dict = @{
                                NSFontAttributeName:[NSFont systemFontOfSize:12.0],
                                NSForegroundColorAttributeName:[NSColor whiteColor]
                                };
        NSAttributedString *updateButtonStr = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"OK_Tip", nil, [NSBundle bundleForClass:[self class]], @"") attributes:dict];
        self.prefenceBtn.attributedTitle =  updateButtonStr;
        self.prefenceBtn.wantsLayer = YES;
        self.prefenceBtn.layer.backgroundColor = [NSColor colorWithHex:0x64DFA7].CGColor;
        self.prefenceBtn.layer.cornerRadius = 2;
        [self.view addSubview:self.prefenceBtn];
        
        [self.prefenceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@28);
            make.width.equalTo(@80);
            make.trailing.equalTo(self.view.mas_trailing).offset(-16);
            make.bottom.equalTo(self.view.mas_bottom).offset(-16);
        }];
        //

        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.prefenceBtn);
            make.height.mas_equalTo(28);
            make.width.mas_equalTo(50);
            make.trailing.equalTo(self.prefenceBtn.mas_leading).offset(-10);
        }];
    } else {
        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@28);
            make.width.equalTo(@80);
            make.trailing.equalTo(self.view.mas_trailing).offset(-16);
            make.bottom.equalTo(self.view.mas_bottom).offset(-16);
        }];
    }
}
- (void)onKnowBtn {
    if ([self.delegate respondsToSelector:@selector(LMVisibleViewControllerDidClose)]) {
        [self.delegate LMVisibleViewControllerDidClose];
    }
}

- (void)btnSelectAction {
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
    if ([self.delegate respondsToSelector:@selector(LMVisibleViewControllerDidClose)]) {
        [self.delegate LMVisibleViewControllerDidClose];
    }
}

- (void)loadView {
    NSRect rect;
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        rect = NSMakeRect(0, 0, 280, 150);
    } else {
        rect = NSMakeRect(0, 0, 280, 120);
    }
    LMUpdatePopoverRootView *view = [[LMUpdatePopoverRootView alloc] initWithFrame:rect];
    self.view = view;
    [self viewDidLoad];
}

@end
