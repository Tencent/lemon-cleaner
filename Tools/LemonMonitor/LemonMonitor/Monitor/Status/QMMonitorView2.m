//
//  QMMonitorView2.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMMonitorView2.h"

@implementation QMMonitorView2
@synthesize actionBlock,mouseEnterBlock,mouseExitBlock,mouseDownBlock,mouseUpBlock;
@synthesize ramUsed,upSpeed,downSpeed;
@synthesize paused;

- (void)startLoadingAnimation
{
    
}

- (void)stopLoadingAnimation
{
    
}

- (void)setRamValue:(double)value completeHandler:(void(^)(void))handler
{
    ramUsed = value;
}

#pragma mark - Event

- (void)updateTrackingAreas
{
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *area in trackingAreas)
    {
        [self removeTrackingArea:area];
    }
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveAlways
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    if (paused)
        return;
    
    if (mouseDownBlock) mouseDownBlock();
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    
    if (paused)
        return;
    
    if (mouseUpBlock) mouseUpBlock();
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (paused)
        return;
    
    if (mouseEnterBlock) mouseEnterBlock();
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (paused)
        return;
    
    if (mouseExitBlock) mouseExitBlock();
}


@end
