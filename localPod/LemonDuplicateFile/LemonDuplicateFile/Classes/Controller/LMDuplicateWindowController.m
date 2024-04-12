//
//  LMDuplicateWindowController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/16.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateWindowController.h"
#import "LMDuplicateSelectFoldersViewController.h"
#import "LMDuplicateScanViewController.h"
#import "QMDuplicateItemManager.h"

@interface LMDuplicateWindowController () <NSWindowDelegate> {

}
@end

@implementation LMDuplicateWindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.itemManager = [[QMDuplicateItemManager alloc] init];
        [self loadWindow];
        [self windowDidLoad];
    }
    return self;
}

//没有自动调用...
- (void)windowDidLoad {
    [super windowDidLoad];
}


- (void)loadWindow {
    NSLog(@"loadWindow...");

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 780, 482)
                                              styleMask:NSWindowStyleMaskTitled
                                                      | NSWindowStyleMaskClosable
                                                      | NSWindowStyleMaskMiniaturizable
                                                      | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    [self.window setTitleVisibility:NSWindowTitleVisible];
    self.window.titlebarAppearsTransparent = YES;
    self.window.delegate = self;
    self.window.movableByWindowBackground = YES;
    [self.window setMovableByWindowBackground:false];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    [self showBaseViewController];

}

- (void)windowWillClose:(NSNotification *)notification {
    
    NSViewController *contentViewController = self.contentViewController;

    if(contentViewController != nil && [contentViewController isKindOfClass:LMDuplicateScanViewController.class]){
        LMDuplicateScanViewController *scanViewController = (LMDuplicateScanViewController *) contentViewController;
        [scanViewController stopScan];
    }
    [self clearViewController];
    if(self.delegate){
        [self.delegate windowWillDismiss: self.className];
    }
    
    
}


- (void)showBaseViewController {
    [self resetData];
    LMDuplicateSelectFoldersViewController *controller = [[LMDuplicateSelectFoldersViewController alloc] init];
    self.window.contentViewController = controller;

    
}

- (void)clearViewController {
    self.window.contentViewController = nil;
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

- (void)resetData{
    self.itemManager = [[QMDuplicateItemManager alloc] init];
}

#pragma mark - window should close

- (BOOL)windowShouldClose:(NSWindow *)sender {
    if (self.itemManager.isCleaning) {
        [self showAlertDuplicateWindowShouldClose];
        return NO;
    }
    return YES;
}

- (void)showAlertDuplicateWindowShouldClose {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanViewController_cancelAlert_button_continue", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanViewController_cancelAlert_button_stop", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanViewController_cancelAlert_messageText", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setInformativeText:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanViewController_cancelAlert_informativeText", nil, [NSBundle bundleForClass:[self class]], @"")];

    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self.itemManager cancelCleaning];
            [[self window] close];
        }
    }];
}


@end
