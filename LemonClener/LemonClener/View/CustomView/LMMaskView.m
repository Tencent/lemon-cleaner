//
//  LMMaskView.m
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import "LMMaskView.h"

@implementation LMMaskView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)updateTrackingAreas
{
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
    if (self.handCursor)
    {
        [[NSCursor pointingHandCursor] set];
    }
    if ([self.mouseDelegate respondsToSelector:@selector(maskViewDidMoveIn)]) {
        [self.mouseDelegate maskViewDidMoveIn];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if (self.handCursor)
    {
        [[NSCursor arrowCursor] set];
    }
    if ([self.mouseDelegate respondsToSelector:@selector(maskViewDidMoveOut)]) {
        [self.mouseDelegate maskViewDidMoveOut];
    }
}

@end
