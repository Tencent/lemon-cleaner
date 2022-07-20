//
//  LMSplashMenuBarViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSplashMenuBarViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>


@interface LMSplashMenuBarViewController (){
    NSImageView *_cleanAndRelaseView;
    NSImageView *_systemViewFunctionView;
    NSTimer *_timer;
    NSTimeInterval animationDuration;
    NSTimeInterval tiemrInterval;
}

@end

@implementation LMSplashMenuBarViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 432)];
    self.view = view;
}

- (void)viewDidLoad{
    animationDuration = 0.6;
    tiemrInterval = 3;
    
    [self setupMenubarView];
    [self setupCleanAndRelasePage];
    [self setupSystemFunctionPage];
    [self setupTitleView];

}

- (void)viewWillAppear{
    _timer = [NSTimer scheduledTimerWithTimeInterval:tiemrInterval target:self selector:@selector(onTimerAction) userInfo:nil repeats:YES]; //不会立刻执行一次
    float pauseTime = tiemrInterval - animationDuration * 2;
    [_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:pauseTime]];
}

- (void)viewWillDisappear{
    [_timer invalidate];
    _timer = nil;
}

-(void)setupMenubarView {
    NSImageView *menubarView = [LMViewHelper createNormalImageView];
    [self.view addSubview:menubarView];
    menubarView.image = [NSImage imageNamed:@"splash_menu_bar"];
    
    [menubarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@262);
        make.height.equalTo(@21);
        make.top.equalTo(self.view).offset(29);
        make.centerX.equalTo(self.view).offset(3);
    }];
}


- (void)setupCleanAndRelasePage{
    _cleanAndRelaseView = [LMViewHelper createNormalImageView];
    [self.view addSubview:_cleanAndRelaseView];
    _cleanAndRelaseView.image = [NSImage imageNamed:@"splash_clean_release"];
    _cleanAndRelaseView.alphaValue = 1;
    
    NSTextField *cleanTabLabel = [LMViewHelper createNormalLabel:9 fontColor:[NSColor colorWithHex:0x515151]];
    [LMAppThemeHelper setTitleColorForTextField:cleanTabLabel];
    [_cleanAndRelaseView addSubview:cleanTabLabel];
    cleanTabLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_tabbar_clean", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSTextField *systemTabLabel = [LMViewHelper createNormalLabel:9 fontColor:[NSColor colorWithHex:0x515151]];
    [LMAppThemeHelper setTitleColorForTextField:systemTabLabel];
    [_cleanAndRelaseView addSubview:systemTabLabel];
    systemTabLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_tabbar_system", nil, [NSBundle bundleForClass:[self class]], @"");

    [_cleanAndRelaseView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@262);
        make.height.equalTo(@364);
        make.top.equalTo(self.view).offset(29);
        make.centerX.equalTo(self.view);
    }];
    
    [cleanTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_cleanAndRelaseView).offset(39);
        make.top.equalTo(self->_cleanAndRelaseView).offset(39);
    }];
    [systemTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_cleanAndRelaseView).offset(103);
        make.top.equalTo(self->_cleanAndRelaseView).offset(39);
    }];
}


- (void)setupSystemFunctionPage{
    _systemViewFunctionView = [LMViewHelper createNormalImageView];
    [self.view addSubview:_systemViewFunctionView];
    _systemViewFunctionView.image = [NSImage imageNamed:@"splash_system_func"];
    _systemViewFunctionView.alphaValue = 0;
    _systemViewFunctionView.animator.alphaValue = 0;

    NSTextField *cleanTabLabel = [LMViewHelper createNormalLabel:9 fontColor:[NSColor colorWithHex:0x515151]];
     [LMAppThemeHelper setTitleColorForTextField:cleanTabLabel];
    [_systemViewFunctionView addSubview:cleanTabLabel];
    cleanTabLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_tabbar_clean", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSTextField *systemTabLabel = [LMViewHelper createNormalLabel:9 fontColor:[NSColor colorWithHex:0x515151]];
    [LMAppThemeHelper setTitleColorForTextField:systemTabLabel];
    [_systemViewFunctionView addSubview:systemTabLabel];
    systemTabLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_tabbar_system", nil, [NSBundle bundleForClass:[self class]], @"");
    
    [_systemViewFunctionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@262);
        make.height.equalTo(@364);
        make.top.equalTo(self.view).offset(29);
        make.centerX.equalTo(self.view);
    }];
    
    [cleanTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_systemViewFunctionView).offset(39);
        make.top.equalTo(self->_systemViewFunctionView).offset(39);
    }];
    [systemTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_systemViewFunctionView).offset(103);
        make.top.equalTo(self->_systemViewFunctionView).offset(39);
    }];
}

- (void)setupTitleView {
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:24 fontColor:[NSColor colorWithHex:0x515151] fonttype:LMFontTypeRegular];
    [LMAppThemeHelper setTitleColorForTextField:titleLabel];
    [self.view addSubview:titleLabel];
    titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_menu_title", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSTextField *descLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x7E7E7E] fonttype:LMFontTypeRegular];
    [self.view addSubview:descLabel];
    descLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSplashMenuBarViewController_menu_subtitle", nil, [NSBundle bundleForClass:[self class]], @"");
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(360);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(401);
    }];
}


-(void)onTimerAction{
    if(_cleanAndRelaseView.alphaValue == 0){
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = self->animationDuration;
            self->_systemViewFunctionView.animator.alphaValue = 0;
        }  completionHandler:^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = self->animationDuration;
                self->_cleanAndRelaseView.animator.alphaValue = 1;
            }  completionHandler:^{}];
        }];
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = self->animationDuration;
            self->_cleanAndRelaseView.animator.alphaValue = 0;
        }  completionHandler:^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = self->animationDuration;
                self->_systemViewFunctionView.animator.alphaValue = 1;
            }  completionHandler:^{}];
        }];
    }
    
    
//    if(_cleanAndRelaseView.alphaValue == 0){
//        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//            context.duration = self->animationDuration;
//            self->_systemViewFunctionView.animator.alphaValue = 0;
//            self->_cleanAndRelaseView.animator.alphaValue = 1;
//        }  completionHandler:^{
//        }];
//    }else{
//        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//            context.duration = self->animationDuration;
//            self->_cleanAndRelaseView.animator.alphaValue = 0;
//        }  completionHandler:^{
//            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//                context.duration = self->animationDuration;
//                self->_systemViewFunctionView.animator.alphaValue = 1;
//            }  completionHandler:^{}];
//        }];
//    }
}


@end
