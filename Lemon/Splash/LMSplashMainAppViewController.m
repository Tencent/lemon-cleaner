//
//  LMSplashMainAppViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSplashMainAppViewController.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMRectangleButton.h>
#import "AppDelegate.h"
#import "LMSplashWindowController.h"
#import <QMUICommon/LMAppThemeHelper.h>


@interface LMSplashMainAppViewController ()

@end

@implementation LMSplashMainAppViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 432)];
    self.view = view;
}

- (void)viewDidLoad{
    [self setupView];
}

-(void)setupView {
    NSImageView *pageImage = [[NSImageView alloc]init];
    [self.view addSubview:pageImage];
    pageImage.image = [NSImage imageNamed:@"splash_main_page" withClass:self.class];

    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:24 fontColor:[NSColor colorWithHex:0x515151] fonttype:LMFontTypeRegular];
    [LMAppThemeHelper setTitleColorForTextField:titleLabel];
    [self.view addSubview:titleLabel];
    titleLabel.stringValue = NSLocalizedString(@"多维扫描，深度清理", nil);

    
    NSTextField *descLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x7E7E7E] fonttype:LMFontTypeRegular];
    [self.view addSubview:descLabel];
    descLabel.stringValue = NSLocalizedString(@"全方位深度分析系统，揪出占用磁盘元凶，彻底卸载软件", nil);
    
    NSButton *button = [[LMRectangleButton alloc] init];
    [self.view addSubview:button];
    button.target = self;
    button.action = @selector(onClickButton);
    button.title = NSLocalizedString(@"立即体验", nil);
    button.font = [NSFont systemFontOfSize:18];
    
    [pageImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@424);
        make.height.equalTo(@302);
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(28);
    }];
    
 
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(305);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(346);
    }];
    
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@140);
        make.height.equalTo(@40);
        make.top.equalTo(self.view).offset(383);
        make.centerX.equalTo(self.view);
    }];
}

-(void) onClickButton{
    id appDelegate = [[NSApplication sharedApplication]delegate];
    if(appDelegate && [appDelegate isKindOfClass:AppDelegate.class]){
        AppDelegate *delegate = appDelegate;
        NSWindowController *controller = self.view.window.windowController;
        if([controller isKindOfClass:LMSplashWindowController.class]){
            [(LMSplashWindowController*)controller closeWindow];
        }
        delegate.hasShowSplashPage = YES;
        [delegate showMainWCAfterRegister];
    }
}
@end
