//
//  LMPortStatWndController.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMPortStatWndController.h"
#import "LMPortStatViewController.h"
#import "LMProcessPortViewController.h"

@interface LMPortStatWndController ()<NSWindowDelegate>
@property (nonatomic, strong) LMPortStatViewController *portViewController;
@property (nonatomic, strong) LMProcessPortViewController *processPortController;
@end

@implementation LMPortStatWndController


- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadWindow];
        [self windowDidLoad];
    }
    return self;
}

- (void)loadWindow {
    NSLog(@"%s", __FUNCTION__);
    
    //self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 348, 344)
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 372, 600)
                                              styleMask:NSWindowStyleMaskTitled
                   | NSWindowStyleMaskClosable
                   | NSWindowStyleMaskMiniaturizable
                   | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [self.window setTitleVisibility:NSWindowTitleVisible];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.window.delegate = self;
    [self.window center];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self showBaseViewController];
}

- (void)dealloc{
    if (self.portViewController) {
        [self.portViewController stopPortTimer];
        self.portViewController = nil;
    }
    if (self.processPortController) {
        [self.processPortController stopPortTimer];
        self.processPortController = nil;
    }
}

- (void)showBaseViewController {
    //self.portViewController = [[LMPortStatViewController alloc] init];
    //self.contentViewController = self.portViewController;
    
    self.processPortController = [[LMProcessPortViewController alloc] init];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.window.contentViewController = self.processPortController;
    [self.window center];
    [self.window setFrame:self.window.frame display:NO];
}



-(void)windowWillClose:(NSNotification *)notification{
    [self.delegate windowWillDismiss:[LMPortStatWndController className]];
    if (self.portViewController) {
        [self.portViewController stopPortTimer];
//        self.portViewController = nil;
    }
    if (self.processPortController) {
        [self.processPortController stopPortTimer];
//        self.processPortController = nil;
    }
}

@end
