//
//  LMNetProcWndController.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMNetProcWndController.h"
#import "LMNetProcViewController.h"

@interface LMNetProcWndController ()
{
    LMNetProcViewController* procVC;
}

@end

@implementation LMNetProcWndController

- (instancetype)init
{
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    self.window.movableByWindowBackground = YES;
    [self.window setStyleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSFullSizeContentViewWindowMask];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    procVC = [[LMNetProcViewController alloc] init];
    self.window.contentViewController = procVC;
}
- (void)networkChange:(BOOL)isReachable{
    [procVC networkChange:isReachable];
}
@end
