//
//  ClickableView.m
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "ClickableView.h"



@implementation ClickableView
- (void)updateTrackingAreas
{
    NSArray *trackings = [self trackingAreas];
    for (NSTrackingArea *tracking in trackings)
    {
        [self removeTrackingArea:tracking];
    }
    //添加NSTrackingActiveAlways掩码可以使视图未处于激活或第一响应者时也能响应相应的方法
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveAlways owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

-(BOOL) acceptsFirstMouse:(NSEvent *)event
{
    return true;
}

- (BOOL)becomeFirstResponder{
    return YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (self.mouseUpBlock) {
        self.mouseUpBlock();
    }
}
- (void)mouseDown:(NSEvent *)event
{
    if (self.mouseDownBlock) {
        self.mouseDownBlock();
    }
}

@end
