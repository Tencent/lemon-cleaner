//
//  QMCircleLoadingButton.m
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMCircleLoadingButton.h"
#import <QuartzCore/QuartzCore.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface QMCircleLoadingButton ()
{
    CALayer *circleLayer;
    NSImage *normalImg;
    NSImage *hoverImg;
    NSImage *downImg;
}
@end

@implementation QMCircleLoadingButton

- (void)setUp
{
    normalImg = [NSImage imageNamed:@"btn_refresh" withClass:self.class];
    hoverImg = [NSImage imageNamed:@"btn_refresh_hl" withClass:self.class];
    downImg = [NSImage imageNamed:@"btn_refresh_d" withClass:self.class];
    
    circleLayer = [CALayer layer];
    circleLayer.bounds = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    circleLayer.position = CGPointMake(NSMidX(circleLayer.bounds), NSMidY(circleLayer.bounds));
    
    CALayer *showLayer = [CALayer layer];
    showLayer.bounds = circleLayer.bounds;
    [showLayer addSublayer:circleLayer];
    
    NSView *aView = [[NSView alloc] initWithFrame:showLayer.bounds];
    [aView setWantsLayer:YES];
    [aView setLayer:showLayer];
    
    aView.frame = NSMakeRect(NSMidX(self.bounds)-NSWidth(aView.frame)/2, NSMidY(self.bounds)-NSHeight(aView.frame)/2,
                             NSWidth(aView.frame), NSHeight(aView.frame));
    [self addSubview:aView];
}

- (void)setNeedsDisplay
{
    QMStateType cust = [self buttonState];
    if (cust & QMState_pressed) {
        [circleLayer setContents:downImg];
    } else if (cust & QMState_hover) {
        [circleLayer setContents:hoverImg];
    } else {
        [circleLayer setContents:normalImg];
    }
}

- (void)stopAnimation:(id)sender
{
    double rotation = [[(CALayer*)circleLayer.presentationLayer valueForKeyPath:@"transform.rotation"] doubleValue];
    [circleLayer setValue:@(rotation) forKeyPath:@"transform.rotation"];
    [circleLayer removeAllAnimations];
}

- (void)startAnimation:(id)sender
{
    if ([circleLayer animationForKey:@"transform.rotation"])
        return;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.byValue = @(-M_PI*2);
    animation.duration = 1.0;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [circleLayer addAnimation:animation forKey:@"transform.rotation"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    
}

@end
