//
//  MyAnimateCellView.m
//  Lemon
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "MyAnimateCellView.h"

@implementation MyAnimateCellView
{
    NSTrackingArea * _trackingArea;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

-(void)mouseEntered:(NSEvent *)event{
    [self.delegate delegateMouseEntered];
}

-(void)mouseExited:(NSEvent *)event{
    [self.delegate delegateMouseExited];
}

@end
