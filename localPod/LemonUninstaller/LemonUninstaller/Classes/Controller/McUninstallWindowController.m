//
//  McUninstallWindowController.m
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "McUninstallWindowController.h"
#import "McUninstallViewController.h"
#import "McUninstallDetailViewController.h"
#import "LMLocalAppListManager.h"
#import "LMLocalApp.h"

@interface McUninstallWindowController () {
    McUninstallViewController *uninstallViewController;
    McUninstallDetailViewController *uninstallDetailViewController;
}

@end

@implementation McUninstallWindowController
- (instancetype) init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self) {
        self.window.backgroundColor = [NSColor whiteColor];
        self.window.movableByWindowBackground = YES;
        self.window.styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskFullSizeContentView;
        self.window.titleVisibility = NSWindowTitleHidden;
        self.window.titlebarAppearsTransparent = YES;
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSLog(@"McUninstallWindowController windowDidLoad");

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    uninstallViewController = [[McUninstallViewController alloc] init];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.window.contentViewController = uninstallViewController;
    [self.window center];
    
}

- (void)windowWillClose:(NSNotification *)notification {
    
    [[LMLocalAppListManager defaultManager] setStopScaning:YES];
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

#pragma mark - UninstallWindowProtocol
- (void)showUninstallListView {
    if (!uninstallViewController){
        uninstallViewController = [[McUninstallViewController alloc] init];
    }
    self.window.contentViewController = uninstallViewController;
    
}

- (void)showUninstallDetailViewWithSoft:(LMLocalApp *)soft{
    NSLog(@"%s", __FUNCTION__);
    if (!uninstallDetailViewController) {
        uninstallDetailViewController = [[McUninstallDetailViewController alloc] init];
    }
    self.window.contentViewController = uninstallDetailViewController;
    uninstallDetailViewController.soft = soft;
}


- (void)uninstallSoft:(LMLocalApp *)soft{
    NSLog(@"uninstall soft %@", soft);
    [self showUninstallListView];
    [uninstallViewController uninstallSoft:soft];
}

@end
