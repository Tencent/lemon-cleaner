//
//  LMSplashWindowController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSplashWindowController.h"
#import "LMSplashViewController.h"
#import "AppDelegate.h"


#define LemonSplashWindowIdentifier  @"LemonSplashWindowIdentifier"

@interface LMSplashWindowController () <NSWindowDelegate, NSWindowRestoration, NSWindowRestoration>

@end

@implementation LMSplashWindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"%s :stacktrace: %@", __FUNCTION__, [NSThread callStackSymbols]);
        [self loadWindow];
        [self windowDidLoad];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        NSLog(@"%s :stacktrace: %@", __FUNCTION__, [NSThread callStackSymbols]);
    }
    return self;
}

- (void)dealloc{
    NSLog(@"%s", __FUNCTION__);
}

//没有自动调用...
- (void)windowDidLoad {
    [super windowDidLoad];
}


- (void)loadWindow {
    NSLog(@"%s...", __FUNCTION__);
    
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 780, 482)
                                              styleMask:NSWindowStyleMaskTitled
                   | NSWindowStyleMaskClosable
                   | NSWindowStyleMaskMiniaturizable
                   | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [self.window setTitleVisibility:NSWindowTitleVisible];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    self.window.restorable = FALSE;
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    self.window.delegate = self;
    self.window.restorationClass = self.class;
    self.window.identifier = LemonSplashWindowIdentifier;
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget: self];
    [closeButton setAction: @selector(customClose)];
    
    [self showBaseViewController];
    
}

-(void)showBaseViewController{
    NSLog(@"%s", __FUNCTION__);
    LMSplashViewController  *viewController = [[LMSplashViewController alloc]init];
    self.contentViewController = viewController;
}

- (void)windowWillClose:(NSNotification *)notification {
    [self clearViewController];
}


- (void)clearViewController {
    self.window.contentViewController = nil;
}

- (void)customClose {
    id appDelegate = [[NSApplication sharedApplication]delegate];
    if(appDelegate && [appDelegate isKindOfClass:AppDelegate.class]){
        AppDelegate *delegate = appDelegate;
        delegate.hasShowSplashPage = YES;
        [self closeWindow];
    }
   
}


- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    if (self.window.occlusionState & NSWindowOcclusionStateVisible) {
//        NSLog(@"LMSplashWindowController window appear ....");
        if (!self.window.contentViewController) {
            [self showBaseViewController];
        }
    } else {
//        NSLog(@"LMSplashWindowController window disappear ....");
    }
}




-(void)closeWindow{
    [self close];
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [appDelegate clearSplashWC];
}



// MARK: restorable
- (void)window:(NSWindow *)window willEncodeRestorableState:(NSCoder *)state{
    NSLog(@"%s willEncodeRestorableState... ", __FUNCTION__);
}

- (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)state{
    NSLog(@"%s didDecodeRestorableState... ", __FUNCTION__);
}

+ (void)restoreWindowWithIdentifier:(NSUserInterfaceItemIdentifier)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler{
    if ([identifier isEqualToString:LemonSplashWindowIdentifier]) {
        NSLog(@"%s restoreWindowWithIdentifier... ", __FUNCTION__);
        completionHandler(nil, nil);  //实例方法,无法传self.window->可以使用 appDelegate.window?
    }
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    NSLog(@"%s :stacktrace: %@", __FUNCTION__, [NSThread callStackSymbols]);
}

@end
