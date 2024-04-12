//
//  GetFullDiskPopViewController.m
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "GetFullDiskPopViewController.h"
#import "LMViewHelper.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMGradientTitleButton.h"
#import "QMUICommon/LMBorderButton.h"
#import "QMUICommon/LMRectangleButton.h"
#import "NSFontHelper.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import "LMViewHelper.h"
#import "NSFontHelper.h"
#import "MMScroller.h"
#import "AcceptsFirstMouseView.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import "LMAppThemeHelper.h"

static BOOL isSettingSuccess = NO;

@interface GetFullDiskPopViewController ()

@property (nonatomic, copy) CLoseBLock closeBlock;
@property (nonatomic, weak) NSButton *settingBtn;
@property (nonatomic, weak) NSButton *cancelBtn;

@property (weak) NSScrollView *scrollView;
@property (weak) MMScroller *scroller;

@end

@implementation GetFullDiskPopViewController

-(id)initWithCLoseSetting:(CLoseBLock) closeBlock{
    self = [super init];
    if (self) {
        self.closeBlock = closeBlock;
        if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized) {
            isSettingSuccess = YES;
        }else{
            isSettingSuccess = NO;
        }
    }
    
    return self;
}

- (void)loadView {
    NSRect rect;
    if (self.style == GetFullDiskPopVCStyleMonitor) {
        rect = NSMakeRect(0, 0, 610, 524);
    } else {
        rect = NSMakeRect(0, 0, 610, 476);
    }

    NSView *view = [[AcceptsFirstMouseView alloc] initWithFrame:rect];
    view.layer.cornerRadius = 5;
    view.layer.masksToBounds = YES;
    self.view = view;
    //    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(currentApplicationChnage:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self setupViews];
}
                          
- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}

- (void)viewWillAppear {
    NSLog(@"GetFullDiskPopViewController viewWillAppear");
    if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized) {
        isSettingSuccess = YES;
        [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_viewWillAppear_settingBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    }else{
        isSettingSuccess = NO;
        [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_viewWillAppear_settingBtn_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)currentApplicationChnage:(NSNotification *)notification{
    NSDictionary *infoDic = [notification userInfo];
    NSRunningApplication *runningApp = infoDic[NSWorkspaceApplicationKey];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([runningApp.bundleIdentifier isEqualToString:bundleId]) {
        if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized) {
            isSettingSuccess = YES;
            [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_currentApplicationChnage_settingBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.cancelBtn setHidden:YES];
        }else{
            isSettingSuccess = NO;
            [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_currentApplicationChnage_settingBtn_2", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.cancelBtn setHidden:FALSE];

        }
    }
}

-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

- (void)setupViews {
    
    NSImageView *alertImageView = [[NSImageView alloc] init];
    [self.view addSubview:alertImageView];
    alertImageView.image = [NSImage imageNamed:@"alert1" withClass:self.class];
    alertImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];
    
    NSTextField *descLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    [self.view addSubview:descLabel];
    [descLabel setFont:[NSFontHelper getLightSystemFont:12]];
    
    NSString *title = @"";
    NSString *des = @"";
    switch (self.style) {
        case GetFullDiskPopVCStyleMonitor:
            title = @"GetFullDiskPopViewController_setupViews_titleLabel_monitor";
            des = @"GetFullDiskPopViewController_setupViews_descLabel_monitor";
            break;
        case GetFullDiskPopVCStylePreScan:
            title = @"GetFullDiskPopViewController_setupViews_preScan_titleLabel_1";
            des = @"GetFullDiskPopViewController_setupViews_preScan_descLabel_2";
            break;
        case GetFullDiskPopVCStyleDefault:
        default:
            title = @"GetFullDiskPopViewController_setupViews_titleLabel_1";
            des = @"GetFullDiskPopViewController_setupViews_descLabel_2";
            break;
    }
    [titleLabel setStringValue:NSLocalizedStringFromTableInBundle(title, nil, [NSBundle bundleForClass:[self class]], @"")];
    [descLabel setStringValue:NSLocalizedStringFromTableInBundle(des, nil, [NSBundle bundleForClass:[self class]], @"")];
    NSScrollView *container = [[NSScrollView alloc] init];
    self.scrollView = container;
    [self.view addSubview:container];
    //    container.drawsBackground = NO;
    container.backgroundColor = [LMAppThemeHelper getMainBgColor];
    container.hasVerticalScroller = YES;
    container.hasHorizontalScroller = NO;
    container.horizontalScrollElasticity = NSScrollElasticityNone;
    
    MMScroller *scroller = [[MMScroller alloc] init];
    self.scroller = scroller;
    [container  setVerticalScroller:scroller];
    
    NSImageView *setImageView = [[NSImageView alloc] init];
    NSString *imageName = [self getPermissionImageName];
    setImageView.image = [NSImage imageNamed:imageName withClass:self.class];
    //    setImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    NSClipView *clipView = [[NSClipView alloc] init];
    clipView.backgroundColor = [LMAppThemeHelper getMainBgColor];
    clipView.documentView = setImageView;
    [container setContentView:clipView];
    
    
    NSButton *setupBtn = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_setupViews_setupBtn _3", nil, [NSBundle bundleForClass:[self class]], @"")];
    if (isSettingSuccess) {
        [setupBtn setTitle:NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_setupViews_setupBtn_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    }
    [self.view addSubview:setupBtn];
    setupBtn.wantsLayer = YES;
    setupBtn.layer.cornerRadius = 2;
    setupBtn.target = [GetFullDiskPopViewController class];//按钮更改为类方法的原因是，因为用户关闭了隐私清理的窗口后，持有self的控制器释放，self也会紧接着被释放，但是窗口view是由系统持有，导致按钮点击无法响应
    setupBtn.action = @selector(startToSetup:);
    self.settingBtn = setupBtn;
    
    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    self.cancelBtn = cancelButton;
    cancelButton.title = NSLocalizedStringFromTableInBundle(@"GetFullDiskPopViewController_setupViews_cancelButton_5", nil, [NSBundle bundleForClass:[self class]], @"");
    cancelButton.target = [GetFullDiskPopViewController class];
    cancelButton.action = @selector(cancelButtonClick:);
    cancelButton.font = [NSFont systemFontOfSize:12];
    
    
    if (self.style == GetFullDiskPopVCStyleMonitor) {
        [alertImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(30);
            make.left.equalTo(self.view).offset(20);
            make.width.mas_equalTo(36);
            make.height.mas_equalTo(36);
        }];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(alertImageView.mas_trailing).offset(24);
            make.centerY.equalTo(alertImageView.mas_centerY);
            make.width.mas_equalTo(510);
            make.height.mas_equalTo(40);
        }];
        
        [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(510);
            make.height.mas_equalTo(51);
            make.centerX.equalTo(titleLabel.mas_centerX);
            make.top.equalTo(titleLabel.mas_bottom).offset(8);
        }];
        
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
            [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(80);
                make.height.mas_equalTo(24);
                make.right.equalTo(self.view).offset(-20);
                make.bottom.equalTo(self.view).offset(-20);
            }];
        } else {
            [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(100);
                make.height.mas_equalTo(24);
                make.right.equalTo(self.view).offset(-20);
                make.bottom.equalTo(self.view).offset(-20);
            }];
        }
        
        
        [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(80);
            make.height.mas_equalTo(24);
            make.right.equalTo(setupBtn.mas_left).offset(-10);
            make.centerY.equalTo(setupBtn);
        }];
        
        
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.width.equalTo(@592);
            make.top.equalTo(self.view).offset(145);
            make.bottom.equalTo(self.view).offset(-60);
        }];
        
        [clipView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@577);
            make.top.equalTo(self.view).offset(145);
            make.top.left.equalTo(container);
        }];
        
        [setImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(clipView);
            make.width.equalTo(@577);
            make.height.equalTo(@679);
        }];
    } else {
        [alertImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(31);
            make.left.equalTo(self.view).offset(23);
            make.width.mas_equalTo(40);
            make.height.mas_equalTo(40);
        }];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(alertImageView.mas_right).offset(10);
            make.top.equalTo(self.view).offset(30);
        }];
        
        [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(alertImageView.mas_right).offset(10);
            make.top.equalTo(self.view).offset(51);
        }];
        
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
            [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(60);
                make.height.mas_equalTo(24);
                make.right.equalTo(self.view).offset(-20);
                make.bottom.equalTo(self.view).offset(-10);
            }];
        } else {
            [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(100);
                make.height.mas_equalTo(24);
                make.right.equalTo(self.view).offset(-20);
                make.bottom.equalTo(self.view).offset(-10);
            }];
        }
        
        
        [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(60);
            make.height.mas_equalTo(24);
            make.right.equalTo(setupBtn.mas_left).offset(-10);
            make.centerY.equalTo(setupBtn);
        }];
        
        
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.width.equalTo(@592);
            make.height.equalTo(@345);
            make.top.equalTo(self.view).offset(83);
        }];
        
        [clipView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@577);
            make.height.equalTo(@345);
            make.top.left.equalTo(container);
        }];
        
        [setImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(clipView);
            make.width.equalTo(@577);
            make.height.equalTo(@679);
        }];
    }
    
    
    
    
    
    // 这里可以改变 container 的大小, 进一步改变 self.view 的大小
    //    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.width.mas_equalTo(container);
    //        make.height.mas_equalTo(container);
    //    }];
    
    //    if ([container hasVerticalScroller]) {
    //        container.verticalScroller.floatValue = 0;
    //    }
    //
    //    NSPoint newOrigin = NSMakePoint(0, 210);
    //    [setImageView scrollPoint:newOrigin];
}


-(NSString *)getPermissionImageName{
    NSString *imageName = @"setstep_ch";
    if ([McCoreFunction isAppStoreVersion]){
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish) {
            imageName = @"setstep_en_lite";
        } else {
            imageName = @"setstep_ch_lite";
        }
    } else {
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish) {
            if (self.style == GetFullDiskPopVCStyleMonitor) {
                imageName = @"setstep_en_monitor";
            } else {
                imageName = @"setstep_en";
            }
        } else {
            if (self.style == GetFullDiskPopVCStyleMonitor) {
                imageName = @"setstep_ch_monitor";
            } else {
                imageName = @"setstep_ch";
            }
        }
    }
    return imageName;
}

+(void)startToSetup:(NSButton *)sender{
    if (isSettingSuccess) {
        NSWindow *window = sender.window;
        [window close];
    }else{
        [QMFullDiskAccessManager openFullDiskAuthPrefreence];
    }
    
}

+(void)cancelButtonClick:(NSButton *)sender {
    NSLog(@"cancelButtonClick ...");
    NSWindow *window = sender.window;
    [window close];
}

- (void)windowWillClose:(NSNotification *)notification {
    id sender = notification.object;
    NSLog(@"windowWillClose ... sender is %@", sender);
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    NSLog(@"windowShouldClose ... sender is %@", sender);
    return YES;
}

@end
