//
//  PreferenceWindowController.m
//  Lemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "PreferenceWindowController.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "PreferenceViewController.h"
#import "LMPreferenceTabViewController.h"
#import "LMPreferenceStatusBarViewController.h"
#ifdef APPSTORE_VERSION
#import "PreferenceASViewController.h"
#endif

@interface PreferenceWindowController () <NSWindowDelegate>

@end

@implementation PreferenceWindowController


- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadWindow];
        [self windowDidLoad];
    }
    return self;
}

- (void)loadWindow {
    CGRect frame = CGRectZero;
    if ([McCoreFunction isAppStoreVersion]) {
        frame = CGRectMake(0, 0, 342, 220);
    }else{
        frame = NSMakeRect(0, 0, 600, 482);
    }
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskTitled
                   | NSWindowStyleMaskClosable
                   | NSWindowStyleMaskMiniaturizable
                   | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [self.window setTitleVisibility:NSWindowTitleVisible];
    self.window.titlebarAppearsTransparent = YES;
    self.window.delegate = self;
    self.window.movableByWindowBackground = YES;
    [self.window center];
    
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self showBaseViewController];
}


- (void)showBaseViewController {
    NSViewController *preferenceVC = nil;
#ifdef APPSTORE_VERSION
        preferenceVC = [[PreferenceASViewController alloc] init];
#else
//        preferenceVC = [[PreferenceViewController alloc] initWithPreferenceWindowController:self];
    preferenceVC = [[LMPreferenceTabViewController alloc] init];
    
#endif
    self.window.contentViewController = preferenceVC;
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    if (self.window.occlusionState & NSWindowOcclusionStateVisible) {
//        NSLog(@"window appear ....");
        if (!self.window.contentViewController) {
            [self showBaseViewController];
        }
    } else {
//        NSLog(@"window disappear ....");
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [self clearViewController];
//    NSLog(@"window windowWillClose ....");
}

- (void)clearViewController {
    self.window.contentViewController = nil;
}

@end
