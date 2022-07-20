//
//  QMGetOutAnimation.h
//  QQMacMgr
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMGetOutAnimation : NSObject

+ (void)getOut:(NSView *)view completionBlock:(void(^)(void))block;

@end
