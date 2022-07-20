//
//  NSEvent+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSEvent+Extension.h"

@implementation NSEvent (MouseLocation)

+ (NSPoint)mouseLocationInView:(NSView *)aView
{
    NSPoint point = [self mouseLocation];
    point = [aView.window convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
    point = [aView convertPoint:point fromView:nil];
    return point;
}

+ (BOOL)mouseInView:(NSView *)aView
{
    NSPoint point = [self mouseLocationInView:aView];
    return NSPointInRect(point, aView.bounds);
}

@end
