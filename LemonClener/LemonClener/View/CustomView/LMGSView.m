//
//  LMGSView.m
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import "LMGSView.h"


@implementation LMGSView


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHex:0x21222D alpha:0.15]];

    [shadow setShadowOffset:NSMakeSize(0,0)];
    shadow.shadowBlurRadius = 3;
    [self setWantsLayer:YES];
    [self setShadow:shadow];
       

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
    [super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event
{
    [super mouseEntered:event];
    [self removeFromSuperview];
    if ([self.mouseDelegate respondsToSelector:@selector(GSViewDidMoveOut)]) {
        [self.mouseDelegate GSViewDidMoveOut];
    }
}


@end
