//
//  McBigFileWndController.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "McBigFileWndController.h"
#import "LMBigMainViewController.h"
#import "LMResultViewController.h"
#import "LMRemoveViewController.h"
#import "QMLargeOldManager.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>

@interface McBigFileWndController ()<NSWindowDelegate>
@property(nonatomic, strong) LMBigMainViewController* mainVC;
@property(nonatomic, strong) LMResultViewController* resultVC;
@property(nonatomic, strong) LMRemoveViewController* removeVC;
@end

@implementation McBigFileWndController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"McBigFileWndController"];
    if (self) {

    }
    return self;
}



- (void)awakeFromNib {
    self.window.titlebarAppearsTransparent = YES;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
}

- (void)windowDidLoad {
    [super windowDidLoad];
     [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    self.mainVC = [[LMBigMainViewController alloc] init];
    self.resultVC = [[LMResultViewController alloc] init];
    self.removeVC = [[LMRemoveViewController alloc] init];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    self.window.movableByWindowBackground = YES;
    
    //不用contentViewController，主要是fix rdq上面的crash：60002005、60002206
    [self.window.contentView addSubview:self.mainVC.view];
    
    [self.window.contentView addSubview:self.resultVC.view];
    
    [self.window.contentView addSubview:self.removeVC.view];
    self.mainVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
    self.removeVC.view.hidden = YES;
    //self.window.contentViewController = mainVC;
}

- (void)showMainView {
    //self.window.contentViewController = mainVC;
    self.mainVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
    self.removeVC.view.hidden = YES;
    [self.mainVC showStartView];
}

- (void)showResultView {
    //self.window.contentViewController = resultVC;
    self.mainVC.view.hidden = YES;
    self.resultVC.view.hidden = NO;
    self.removeVC.view.hidden = YES;
    [self.resultVC reloadDataView];
}

- (void)showCleanView {
    //self.window.contentViewController = removeVC;
    self.mainVC.view.hidden = YES;
    self.resultVC.view.hidden = YES;
    self.removeVC.view.hidden = NO;
    [self.removeVC showCleaningView];
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"windowWillClose: %@, className:%@", notification, [self className]);
    LMBaseViewController* vc = nil;//(LMBaseViewController*)self.window.contentViewController;
    if (self.mainVC.view.isHidden == NO) {
        vc = self.mainVC;
    }
    if (self.resultVC.view.isHidden == NO) {
        vc = self.resultVC;
    }
    if (self.removeVC.view.isHidden == NO) {
        vc = self. removeVC;
    }
    [vc windowWillClose:notification];

    [QMLargeOldManager destroyManager];
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

@end
