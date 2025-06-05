//
//  OwlLogWindowController.m
//  Lemon
//
//  Created by  Torsysmeng on 2018/8/28.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlLogWindowController.h"
#import "OwlLogViewController.h"
#import <Masonry/Masonry.h>

@interface OwlLogWindowController () {
    OwlLogViewController *viewController;
}

@end

@implementation OwlLogWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (instancetype)init{
    int width = 500, height = 360;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(200, 200, width, height) styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:YES];
    //[window setReleasedWhenClosed:YES];
    viewController = [[OwlLogViewController alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    NSLog(@"%@", viewController.view);
    //window.contentViewController = viewController;
    [window.contentView addSubview:viewController.view];
    self = [self initWithWindow:window];
    return self;
}

- (instancetype)initWithWindow:(nullable NSWindow *)window{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}

@end
