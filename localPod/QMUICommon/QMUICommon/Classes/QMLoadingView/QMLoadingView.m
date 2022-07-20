//
//  QMHardwareWaitView.m
//  QMHardware
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMLoadingView.h"
#import <Quartz/Quartz.h>

@interface QMLoadingView()
{
    CABasicAnimation * animation;
}
@end

@implementation QMLoadingView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        [self setLayerImage];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setLayerImage];
    }
    return self;
}

- (void)setLayerImage{
    [self setLayer:[CALayer layer]];
    [self setWantsLayer:YES];
    
    backLayer = [CALayer layer];
    [backLayer setFrame:self.bounds];
    [self.layer addSublayer:backLayer];
    [backLayer setContents:[[NSBundle bundleForClass:[self class]] imageForResource:@"loading"]];
}

- (void)startAnimation
{
    [self setHidden:NO];
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = [NSNumber numberWithFloat: 2*M_PI];
    animation.toValue = [NSNumber numberWithFloat:0];
    animation.duration = 1.0f;
    animation.repeatCount = HUGE_VAL;
    animation.removedOnCompletion = NO;
    [backLayer addAnimation:animation forKey:@"loading"];
}
- (void)stopAnimation
{
    [self setHidden:YES];
    [backLayer removeAllAnimations];
}

@end
