//
//  LMPermissionGuideViewController.m
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMPermissionGuideViewController.h"
#import "LMViewHelper.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMGradientTitleButton.h"
#import "QMUICommon/LMBorderButton.h"
#import "QMUICommon/LMRectangleButton.h"
#import "NSFontHelper.h"
#import "LMViewHelper.h"
#import "NSFontHelper.h"
#import "MMScroller.h"
#import "AcceptsFirstMouseView.h"
#import <QMCoreFunction/LanguageHelper.h>
#import "LMAppThemeHelper.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import "LMCommonHelper.h"

@interface LMPermissionGuideViewController ()

@property (nonatomic, weak) NSButton *settingBtn;
@property (weak) NSScrollView *scrollView;
@property (weak) NSClipView *clipView;
@property (weak) MMScroller *scroller;
@property (weak) LMBorderButton *cancelButton;

@end

@implementation LMPermissionGuideViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.needCheckMonitorFullDiskAuthorizationStatus = NO;
    }
    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 610, 476);
    NSView *view = [[AcceptsFirstMouseView alloc] initWithFrame:rect];
    view.wantsLayer = YES;
    if ([LMCommonHelper isMacOS11]) {
        view.layer.cornerRadius = 10;
    } else {
        view.layer.cornerRadius = 5;
    }
    view.layer.masksToBounds = YES;
    self.view = view;
    //    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)viewWillAppear {
    self.view.window.titleVisibility = NSWindowTitleHidden;
    self.view.window.titlebarAppearsTransparent = YES;
    self.view.window.styleMask = NSFullSizeContentViewWindowMask;
    self.view.window.movableByWindowBackground = YES;
    [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMPermissionGuideViewController_setupViews_okBtn_get_permission", nil, [NSBundle bundleForClass:[self class]], @"")];
    if (self.settingButtonTitle) {
        self.settingBtn.title = self.settingButtonTitle;
    }
    if (self.cancelButtonTitle) {
        self.cancelButton.title = self.cancelButtonTitle;
    }
    self.settingBtn.action = @selector(onOkButtonClick:);
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scrollView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}

- (void)setupViews {
    
    NSImageView *alertImageView = [[NSImageView alloc] init];
    [self.view addSubview:alertImageView];
    alertImageView.image = [NSImage imageNamed:@"alert1" withClass:self.class];
    alertImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];
    [titleLabel setStringValue:self.tipsTitle];
    
    NSTextField *descLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    [self.view addSubview:descLabel];
    [descLabel setStringValue:self.descText];
    [descLabel setFont:[NSFontHelper getLightSystemFont:12]];
    
    NSScrollView *container = [[NSScrollView alloc] init];
    self.scrollView = container;
    [self.view addSubview:container];
    //    container.drawsBackground = NO;
//    container.backgroundColor = [NSColor whiteColor];
//    [container setWantsLayer:YES];
//    [container.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    container.hasVerticalScroller = YES;
    container.hasHorizontalScroller = NO;
    container.horizontalScrollElasticity = NSScrollElasticityNone;
    
    MMScroller *scroller = [[MMScroller alloc] init];
    self.scroller = scroller;
//    [scroller setWantsLayer:YES];
//    [scroller.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [container  setVerticalScroller:scroller];
    
    NSImageView *setImageView = [[NSImageView alloc] init];
    setImageView.image = self.image;
    setImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSClipView *clipView = [[NSClipView alloc] init];
    clipView.backgroundColor = [LMAppThemeHelper getMainBgColor];
    clipView.documentView = setImageView;
    [container setContentView:clipView];
    
    
    NSButton *setupBtn = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"LMPermissionGuideViewController_setupViews_okBtn_get_permission", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:setupBtn];
    setupBtn.wantsLayer = YES;
    setupBtn.layer.cornerRadius = 2;
    //    setupBtn.target = [GetFullDiskPopViewController class];//按钮更改为类方法的原因是，因为用户关闭了隐私清理的窗口后，持有self的控制器释放，self也会紧接着被释放，但是窗口view是由系统持有，导致按钮点击无法响应
//    setupBtn.action = @selector(startToSetup:);
    setupBtn.target = self;
    setupBtn.action = @selector(onOkButtonClick:);

    self.settingBtn = setupBtn;
    
    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    self.cancelButton = cancelButton;
    cancelButton.title = NSLocalizedStringFromTableInBundle(@"LMPermissionGuideViewController_setupViews_cancelButton", nil, [NSBundle bundleForClass:[self class]], @"");
    cancelButton.target = self;
    cancelButton.action = @selector(cancelButtonClick:);
    cancelButton.font = [NSFont systemFontOfSize:12];
    
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
    
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish) {
        [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(24);
            make.right.equalTo(self.view).offset(-20);
            make.bottom.equalTo(self.view).offset(-10);
        }];
    }else{
        [setupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(60);
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
        make.height.mas_equalTo(self.guidImageViewHeight);
    }];
}

-(void)onOkButtonClick:(NSButton *)sender{
    NSLog(@"onOkButtonClick called");
    if(self.okButtonEvent){ //(modify)
        self.okButtonEvent();
    }
    //需要根据权限状态更新button
    if(!self.needCheckMonitorFullDiskAuthorizationStatus){
        [self.cancelButton setHidden:YES];
        [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMPermissionGuideViewController_setupViews_okBtn_finish", nil, [NSBundle bundleForClass:[self class]], @"")];
        self.settingBtn.action = @selector(closeWindow:);
    }else{
        [self addObserForCheckFullDiskAccess];
    }
   
}

-(void)addObserForCheckFullDiskAccess{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:(@selector(updateButtonStatus)) name:NSWindowDidBecomeMainNotification object:nil];
}

//-(void)addOber

-(void)updateButtonStatus{
    NSLog(@"%s,called",__FUNCTION__);
    if([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized){
        [self.cancelButton setHidden:YES];
        [self.settingBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMPermissionGuideViewController_setupViews_okBtn_finish", nil, [NSBundle bundleForClass:[self class]], @"")];
        if (self.confirmTitle) {
            [self.settingBtn setTitle:self.confirmTitle];
        }
        self.settingBtn.action = @selector(closeWindow:);
    }
}

-(BOOL)isMacOS1015{
    if (@available(macOS 10.15, *)) {
        return YES;
    }
    return NO;
}

-(void)closeWindow:(NSButton *)sender{
    if(self.finishButtonEvent){
        self.finishButtonEvent();
    }
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [sender.window close];
}

-(void)cancelButtonClick:(NSButton *)sender {
    NSLog(@"cancelButtonClick ...");
    if(self.cancelButtonEvent){
        self.cancelButtonEvent();
    }
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
