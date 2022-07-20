//
//  AnimationHelper.h
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimationHelper : NSObject

+ (void)TransOpacityAnimate:(NSView*)view reverse:(BOOL)isReverse offsetTyep:(BOOL)isY offsetValue:(CGFloat)offsetValue opacity:(CGFloat)opacity durationT:(CFTimeInterval) durationT durationO:(CFTimeInterval) durationO delay:(CGFloat)delay type:(NSString*)type delegate:(id<CAAnimationDelegate>)delegate;

@end
