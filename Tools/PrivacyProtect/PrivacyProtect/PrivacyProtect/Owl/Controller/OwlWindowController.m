//
//  OwlWindowController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlWindowController.h"
#import "OwlViewController.h"
#import "OwlConstant.h"
#import "OwlWhiteListViewController.h"
#import "OwlLogViewController.h"
#import "OwlSelectViewController.h"
#import <Masonry/Masonry.h>

@interface OwlWindowController () <NSWindowDelegate> {
    
}

@end

@implementation OwlWindowController

- (instancetype)init{
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(200, 200, 780, 482) styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:YES];
    [window setReleasedWhenClosed:YES];
    window.titlebarAppearsTransparent = YES;
    window.movableByWindowBackground = YES;
    [[window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    //[window.contentView addSubview:viewController.view];
    self = [self initWithWindow:window];
    if (self) {
        [self loadWindow];
        [self windowDidLoad];
        [window center];
    }
    return self;
}

- (instancetype)initViewController:(NSViewController*)viewController{
    NSWindow *window = [[NSWindow alloc] initWithContentRect:viewController.view.frame
                                              styleMask:NSWindowStyleMaskTitled
                   | NSWindowStyleMaskClosable
                   | NSWindowStyleMaskMiniaturizable
                   | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [window setReleasedWhenClosed:YES];
    window.contentViewController = viewController;
    [window setTitleVisibility:NSWindowTitleVisible];
    window.titlebarAppearsTransparent = YES;
    window.movableByWindowBackground = YES;
    window.backgroundColor = [NSColor whiteColor];
    [[window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self = [self initWithWindow:window];
    if (self) {
        window.windowController = self;
    }
    return self;
}

- (instancetype)initWithWindow:(nullable NSWindow *)window{
    self = [super initWithWindow:window];
    if (self) {
        window.delegate = self;
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowClose:) name:NSWindowWillCloseNotification object:self];
    }
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    NSViewController *vc = (NSViewController*)[[OwlViewController alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    NSLog(@"wol windowDidLoad%@", vc.view);
    self.window.contentViewController = vc;
}

- (void)dealloc{
    
}

- (void)windowWillClose:(NSNotification *)notification{
    NSViewController *vc = self.window.contentViewController;
    NSLog(@"windowClose: %@, vc:%@", notification, vc);
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
    if ([vc isKindOfClass:[OwlViewController class]]) {
        [((OwlViewController*)vc) removeNotifyDelegate];
        if (((OwlViewController*)vc).wlWindowController) {
            [((OwlViewController*)vc).wlWindowController close];
            ((OwlViewController*)vc).wlWindowController = nil;
        }
        if (((OwlViewController*)vc).logWindowController) {
            [((OwlViewController*)vc).logWindowController close];
            ((OwlViewController*)vc).logWindowController = nil;
        }
    }
    if ([vc isKindOfClass:[OwlWhiteListViewController class]]) {
        if (((OwlWhiteListViewController*)vc).selectWindowController) {
            [((OwlWhiteListViewController*)vc).selectWindowController close];
            ((OwlWhiteListViewController*)vc).selectWindowController = nil;
            [vc.view.window.parentWindow orderFront:nil];
        }
        ((OwlViewController*)vc.view.window.parentWindow.contentViewController).wlWindowController = nil;
        
    }
    if ([vc isKindOfClass:[OwlLogViewController class]]) {
        ((OwlViewController*)vc.view.window.parentWindow.contentViewController).logWindowController = nil;
    }
}
- (void)windowClose:(NSNotification*)notification{
    NSLog(@"windowClose: %@", notification);
}

@end
