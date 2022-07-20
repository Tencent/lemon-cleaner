//
//  LMLoginItemManageWindowController.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemManageWindowController.h"
#import "LMLoginItemManageViewController.h"

@interface LMLoginItemManageWindowController ()<NSWindowDelegate>

@property (nonatomic) LMLoginItemManageViewController *viewController;

@end

@implementation LMLoginItemManageWindowController


- (instancetype) init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.window setStyleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    
}

- (void)windowDidLoad {
    [super windowDidLoad];
    LMLoginItemManageViewController *viewController = [[LMLoginItemManageViewController alloc] init];
    self.viewController = viewController;
    self.contentViewController = viewController;
}

- (void)windowWillClose:(NSNotification *)notification {
    self.window.contentViewController = nil;
    if(self.delegate){
        [self.delegate windowWillDismiss: self.className];
    }
}



@end
