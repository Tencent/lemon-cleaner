//
//  LemonHardwareWindowController.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LemonHardwareWindowController.h"
#import "LemonHardwareViewController.h"

@interface LemonHardwareWindowController ()<NSWindowDelegate>

@property (nonatomic, strong) LemonHardwareViewController *hardViewController;

@end

@implementation LemonHardwareWindowController

- (id)init
{
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.window setStyleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSFullSizeContentViewWindowMask];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    self.window.delegate = self;
    [self.window setBackgroundColor:[NSColor whiteColor]];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.hardViewController = [[LemonHardwareViewController alloc] init];
    [self.window.contentView addSubview:self.hardViewController.view];
}

-(void)windowWillClose:(NSNotification *)notification{
    [self.hardViewController stopTimer];
    [self.delegate windowWillDismiss:[self className]];
}

@end
