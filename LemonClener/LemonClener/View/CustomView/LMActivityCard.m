//
//  LMActivityCard.m
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import "LMActivityCard.h"

@implementation LMActivityCard

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
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
   
}

- (void)mouseExited:(NSEvent *)event
{
    
    [self removeFromSuperview];
}

@end
