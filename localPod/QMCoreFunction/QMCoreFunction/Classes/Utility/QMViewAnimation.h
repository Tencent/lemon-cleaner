//
//  QMViewAnimation.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMViewAnimation : NSViewAnimation

+ (id)animationWithInfos:(NSArray *)viewAnimations;
- (void)startAnimationWithHandler:(void(^)(BOOL finished))handler;

@end
