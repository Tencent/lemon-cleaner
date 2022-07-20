//
//  RegisterWindowController.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RegisterWindowController.h"
#import "RegisterViewController.h"

@interface RegisterWindowController () <NSWindowDelegate>{
    BOOL _needTerminateSelf;
}

@end

@implementation RegisterWindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadWindow];
        [self windowDidLoad];
    }
    return self;
}

- (instancetype)initWithCallback:(RegisterSuccesCallback)callback {
    self = [self init];
    self.successCallback = callback;
    return self;
}

- (void)loadWindow {
    NSLog(@"loadWindow...");

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 348, 344)
                                              styleMask:NSWindowStyleMaskTitled
                                                      | NSWindowStyleMaskClosable
                                                      | NSWindowStyleMaskMiniaturizable
                                                      | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [self.window setTitleVisibility:NSWindowTitleVisible];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    [self.window center];

    self.window.delegate = self;
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget: self];
    [closeButton setAction: @selector(customClose)];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self showBaseViewController];
}



- (void)showBaseViewController {
    RegisterViewController *registerViewController = [[RegisterViewController alloc] init];
    self.contentViewController = registerViewController;
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

// windowWillClose 无法区分是调用的 close 方法还是点击的 close 按钮.
-(void)customClose{
    _needTerminateSelf = true;
    [self close];
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"window windowWillClose .... %@", notification);
    
    if(_needTerminateSelf){
        [[NSApplication sharedApplication]terminate:self];
    }
    
}


@end
