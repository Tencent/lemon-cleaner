//
//  RatingViewController.m
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "RatingViewController.h"
#import <QMUICommon/LMGradientTitleButton.h>
#import "QMUICommon/LMBorderButton.h"
#import "QMUICommon/LMRectangleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMViewHelper.h>
#import <StoreKit/StoreKit.h>
#import "RatingUtils.h"
#import <Masonry/Masonry.h>


@implementation BaseTitleViewController

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 420, 133);
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
    [self setupViews];
}

- (void)setupViews{
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:titleLabel];

    titleLabel.maximumNumberOfLines = 2;
    self.titleLabel = titleLabel;
    

    LMBorderButton *okButton = [[LMBorderButton alloc] init];
    [self.view addSubview:okButton];
    okButton.target = self;
    okButton.action = @selector(onOkButtonClicked);
    okButton.font = [NSFont systemFontOfSize:12];
    _okButton = okButton;
    

    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    cancelButton.target = self;
    cancelButton.action = @selector(onCancelButtonClicked);
    cancelButton.font = [NSFont systemFontOfSize:12];
    _cancelButton = cancelButton;
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(44);
        make.left.equalTo(self.view).offset(44);
        make.width.lessThanOrEqualTo(@334);
    }];
    
    [okButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(24);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view).offset(-21);
    }];
    
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(24);
        make.right.equalTo(okButton.mas_left).offset(-12);
        make.centerY.equalTo(okButton);
    }];
    
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self widenButtonWidth:_okButton];
    [self widenButtonWidth:_cancelButton];

}

-(void)widenButtonWidth:(NSButton*)button{
    if(button.title && button.title.length > 0){
        CGFloat textWidth = [self widthOfString:button.title withFont:button.font];
        CGFloat buttonWidth = textWidth + 15;
        if(buttonWidth > 68){
            NSLog(@"reset button width is %f", buttonWidth);
            [button mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(buttonWidth));
            }];
        }
    }
}


- (CGFloat)widthOfString:(NSString *)string withFont:(NSFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

-(void)onOkButtonClicked{
    [NSException raise:@"UnValidMehotdCall"
                format:@"onOkButtonClicked must be implement."];
}


-(void)onCancelButtonClicked{
    [NSException raise:@"UnValidMehotdCall"
                format:@"onCancelButtonClicked must be implement."];
}

@end















@implementation RatingTitleViewController


- (void)viewDidLoad{
    [super viewDidLoad];
    self.titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"RatingViewController_title", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSString *wellToUseString = NSLocalizedStringFromTableInBundle(@"RatingViewController_wellUse", nil, [NSBundle bundleForClass:[self class]], @"");
    self.okButton.title = wellToUseString;
    
    NSString *hardToUseString = NSLocalizedStringFromTableInBundle(@"RatingViewController_hardUse", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cancelButton.title = hardToUseString;

}
-(void)onOkButtonClicked{
    [self.view.window close];
    
//    if (@available(macOS 10.14, *)) {
//        [SKStoreReviewController requestReview];
//    } else {
//        NSString *appID = @"1449962996";
//        NSString *str = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?action=write-review", appID];
//        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:str]];
//    }
    
    NSString *appID = @"1449962996";
    NSString *str = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?action=write-review", appID];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:str]];
}


-(void)onCancelButtonClicked{
    if (self.parentViewController && [self.parentViewController isKindOfClass:RatingViewController.class]){
        RatingViewController *parentController = (RatingViewController *) self.parentViewController;
        [parentController changeToTucaoViewController];
    }
}

@end












@implementation TucaoTitleViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"TucaoTitleViewController_title", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSString *wellToUseString = NSLocalizedStringFromTableInBundle(@"TucaoTitleViewController_goto", nil, [NSBundle bundleForClass:[self class]], @"");
    self.okButton.title = wellToUseString;
    
    NSString *hardToUseString = NSLocalizedStringFromTableInBundle(@"TucaoTitleViewController_later", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cancelButton.title = hardToUseString;
    
}

-(void)onOkButtonClicked{
    [self.view.window close];
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
        return;
    }
#ifndef APPSTORE_VERSION
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
#else
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/52728"]];
#endif
    
}

-(void)onCancelButtonClicked{
    [self.view.window close];
    [RatingUtils recordCancelActionAtTucaoPage];
}

@end










@interface RatingViewController()

- (void)changeToTucaoViewController;

@end


@implementation RatingViewController{
    RatingTitleViewController *titleViewController;
    TucaoTitleViewController  *tucaoViewController;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 420, 133);
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
        window.titleVisibility = NSWindowTitleVisible;
        window.titlebarAppearsTransparent = YES;
        window.styleMask |= NSWindowStyleMaskFullSizeContentView | NSClosableWindowMask |    NSWindowStyleMaskBorderless;
        window.styleMask &= ~NSWindowStyleMaskResizable;
        
        [[window standardWindowButton:NSWindowCloseButton] setHidden:FALSE];
        [[window standardWindowButton:NSWindowFullScreenButton] setHidden:YES];
        [[window standardWindowButton:NSWindowZoomButton] setHidden:YES];
        
        window.opaque = NO;
        window.showsToolbarButton = YES;
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
    
    [self setupChildViewControllers];
}


- (void)setupChildViewControllers{
    titleViewController = [[RatingTitleViewController alloc]init];
    [self addChildViewController:titleViewController];
    [self.view addSubview:titleViewController.view];
    //    [menubarViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {   //使用transitionFromViewController动画时不能使用约束,不然第一次动画效果不对.
    //        make.centerX.equalTo(self.view);
    //        make.top.equalTo(self.view);
    //        make.width.equalTo(@580);
    //        make.height.equalTo(@432);
    //    }];
    //
    titleViewController.view.frame = NSMakeRect(0,  0, 420, 133);
//    self->curSplashType = LMSplashTypeMenubar;
    
    
    tucaoViewController = [[TucaoTitleViewController alloc]init];
    [self addChildViewController:tucaoViewController];
    //    [self.view addSubview:mainAppViewController.view];   // transition动画时会自动 add,这里不需要 add这个 view.  view 的大小也同 page1 相同.
    

}


- (void)changeToTucaoViewController{
    [self transitionFromViewController:titleViewController toViewController:tucaoViewController   options:NSViewControllerTransitionSlideForward completionHandler:^{
    }];

}


@end
