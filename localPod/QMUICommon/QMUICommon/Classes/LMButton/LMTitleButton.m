//
//  LMButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMTitleButton.h"

@implementation LMTitleButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    [self setTitleColor];
}

- (void)applyTitleColor {
    [self setTitleColor];
}

- (BOOL)mouseInView {
    if (!self.window)
        return NO;
    if (self.isHidden)
        return NO;
    
    NSPoint point = [NSEvent mouseLocation];
    point = [self.window convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
    point = [self convertPoint:point fromView:nil];
    return NSPointInRect(point, self.visibleRect);
}

- (void)setTitleColor {
    if(!self.enabled) {
        return;
    }
    if(_down) {
        if(_downTitleColor)
            [self setFontColor:_downTitleColor];
    }
    else {
        if(_hover && _hoverTitleColor)
            [self setFontColor:_hoverTitleColor];
        else if(_defaultTitleColor) {
            [self setFontColor:_defaultTitleColor];
        }
    }
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
    _hover = YES;
    [self setTitleColor];
}

- (void)mouseExited:(NSEvent *)event
{
    _hover = NO;
    [self setTitleColor];
}

- (void)mouseDown:(NSEvent *)event
{
    _down = YES;
    [self setTitleColor];
}

- (void)mouseUp:(NSEvent *)event
{
    _down = NO;
    if([self mouseInView] && self.enabled) {
        _hover = YES;
        [self.target performSelector:self.action withObject:self];
    }
    [self setTitleColor];
}

@end
