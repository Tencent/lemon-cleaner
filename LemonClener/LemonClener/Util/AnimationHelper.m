//
//  AnimationHelper.m
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "AnimationHelper.h"

@implementation AnimationHelper

+ (void)TransOpacityAnimate:(NSView*)view reverse:(BOOL)isReverse offsetTyep:(BOOL)isY offsetValue:(CGFloat)offsetValue opacity:(CGFloat)opacity durationT:(CFTimeInterval) durationT durationO:(CFTimeInterval) durationO delay:(CGFloat)delay type:(NSString*)type delegate:(id<CAAnimationDelegate>)delegate {
    NSString* atype;
    if(isY) {
        atype = @"transform.translation.y";
    } else {
        atype = @"transform.translation.x";
    }
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:atype];
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    if(!isReverse) {
        animation1.fromValue = [NSNumber numberWithFloat:0];
        animation1.toValue = [NSNumber numberWithFloat:offsetValue];
        animation1.duration = durationT;
        animation2.fromValue = [NSNumber numberWithFloat:1];
        animation2.toValue = [NSNumber numberWithFloat:opacity];
        animation2.duration = durationO;
    } else {
        animation1.toValue = [NSNumber numberWithFloat:0];
        animation1.fromValue = [NSNumber numberWithFloat:offsetValue];
        animation1.duration = durationT;
        animation2.toValue = [NSNumber numberWithFloat:1];
        animation2.fromValue = [NSNumber numberWithFloat:opacity];
        animation2.duration = durationO;
    }
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.beginTime = CACurrentMediaTime() + delay;
    group.duration = MAX(durationT, durationO);
    group.repeatCount = 1;
    group.delegate = delegate;
    group.animations = [NSArray arrayWithObjects:animation1, animation2, nil];
    group.timingFunction = [CAMediaTimingFunction functionWithName:type];
    
    if(!isReverse) {
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
        
        animation1.removedOnCompletion = NO;
        animation1.fillMode = kCAFillModeForwards;
        animation2.removedOnCompletion = NO;
        animation2.fillMode = kCAFillModeForwards;
    } else {
        group.fillMode = kCAFillModeBackwards;
        
        animation1.fillMode = kCAFillModeBackwards;
        animation2.fillMode = kCAFillModeBackwards;
    }
    
    [view.layer addAnimation:group forKey:@"trans-opacity-layer"];
}

@end
