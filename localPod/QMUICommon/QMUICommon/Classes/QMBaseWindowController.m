//
//  QMBaseWindowController.m
//  QMUICommon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "QMBaseWindowController.h"

@interface QMBaseWindowController ()

@end

@implementation QMBaseWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)setWindowCenterPositon:(CGPoint) centerPoint{
    CGFloat width = self.window.frame.size.width;
    CGFloat height = self.window.frame.size.height;
    
    [self.window setFrame:NSMakeRect(centerPoint.x - width / 2, centerPoint.y - height / 2, self.window.frame.size.width, self.window.frame.size.height) display:YES];
}

@end
