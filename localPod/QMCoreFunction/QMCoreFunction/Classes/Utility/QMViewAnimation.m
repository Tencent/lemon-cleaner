//
//  QMViewAnimation.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMViewAnimation.h"

@interface QMViewAnimation ()<NSAnimationDelegate>
{
    dispatch_queue_t outsideQueue;
    void(^animationHandler)(BOOL finished);
}
@end

@implementation QMViewAnimation

+ (id)animationWithInfos:(NSArray *)viewAnimations
{
    QMViewAnimation *animation = [[QMViewAnimation alloc] init];
    [animation setViewAnimations:viewAnimations];
    return animation;
}

- (void)startAnimationWithHandler:(void(^)(BOOL finished))handler
{
    outsideQueue = dispatch_get_current_queue();
    animationHandler = [handler copy];
    self.delegate = self;
    [self startAnimation];
}

- (void)animationDidStop:(NSAnimation*)animation
{
    dispatch_async(outsideQueue, ^{
        animationHandler(NO);
    });
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    dispatch_async(outsideQueue, ^{
        animationHandler(YES);
    });
}

@end
