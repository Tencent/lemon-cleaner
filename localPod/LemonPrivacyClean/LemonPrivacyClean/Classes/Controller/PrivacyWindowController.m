//
//  PrivacyWindowController.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyWindowController.h"
#import "PrivacyResultViewController.h"
#import "PrivacyScanViewController.h"
#import "PrivacyCleanResultViewController.h"
#import "PrivacyStartViewController.h"
#import "PrivacyData.h"

@interface PrivacyWindowController () <NSWindowDelegate>

@end

@implementation PrivacyWindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadWindow];
        self.window.delegate = self;
    }
    return self;
}

- (void)loadWindow {
    NSRect frame = NSMakeRect(0, 0, 780, 482);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:NSWindowStyleMaskClosable
                                                           | NSWindowStyleMaskTitled
//                                                    | NSWindowStyleMaskFullScreen
//                                                           | NSWindowStyleMaskResizable
                                                           | NSWindowStyleMaskMiniaturizable
                                                           | NSWindowStyleMaskFullSizeContentView
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window setBackgroundColor:[NSColor whiteColor]];
    self.window = window;
    self.window.delegate = self;
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
//    self.window.
    // window 的 delegate 和 windowController 没啥关系.
    // 一个是 window 的 移动/缩放 的 回调, 一个是 window 的 生命周期.

    [self windowDidLoad];
}


- (void)showStartViewController {
    PrivacyStartViewController *viewController = [[PrivacyStartViewController alloc] init];
    self.contentViewController = viewController;
}

- (void)showScanViewController {
    PrivacyScanViewController *viewController = [[PrivacyScanViewController alloc] init:ScanTypeGet];
    self.contentViewController = viewController;
    [viewController startToScan];
}

- (void)showDataResultViewController:(PrivacyData *)data {
    PrivacyResultViewController *viewController = [[PrivacyResultViewController alloc] init];
    self.contentViewController = viewController;
    [viewController updateViewsBy:data];

}

- (void)showCleanProcessViewController:(PrivacyData *)data runningApps:(NSArray *)apps needKill:(BOOL)killFlag{
    PrivacyScanViewController *viewController = [[PrivacyScanViewController alloc] init:ScanTypeClean];
    self.contentViewController = viewController;
    [viewController startToCleanWithData:data runningApps:apps needKill:killFlag];
}

- (void)showCleanResultViewController:(PrivacyData *)data {
    PrivacyCleanResultViewController *viewController = [[PrivacyCleanResultViewController alloc] init];
    if(data){
        viewController.cleanNum = data.selectedSubItemNum;
    }
    self.contentViewController = viewController;
}


- (void)clearViewController {
    self.contentViewController = nil;
}

// MARK: 通过非 nib 方式 创建, 并不会调用 windowDidLoad 方法, 一般通过 awakeFromNib 方法触发.
- (void)windowDidLoad {
    [super windowDidLoad];
    NSLog(@"windowDidLoad ....");
    [self showStartViewController];

}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self.window center];
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    if (self.window.occlusionState & NSWindowOcclusionStateVisible) {
//        NSLog(@"window appear ....");
        if (!self.window.contentViewController) {
            [self showStartViewController];
        }
    } else {
//        NSLog(@"window disappear ....");
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"window windowWillClose ....");
    if(self.contentViewController && [self.contentViewController isKindOfClass:PrivacyResultViewController.class]){
        PrivacyResultViewController *resultController = (PrivacyResultViewController *) self.contentViewController;
        [resultController hostWindowWillClose];
    }
    
    [self clearViewController];

    if(self.delegate){
        [self.delegate windowWillDismiss: self.className];
    }
}

@end
