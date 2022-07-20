//
//  QMSmoonthTextField.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSmoonthTextField.h"

@implementation QMSmoonthTextField

- (void)drawRect:(NSRect)dirtyRect {
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    if (self.layer)
    {
        CGContextSetAllowsFontSmoothing(ctx, YES);
        CGContextSetShouldSmoothFonts(ctx, YES);
    }
    [super drawRect:dirtyRect];
    CGContextRestoreGState(ctx);
    
    // Drawing code here.
}

@end
