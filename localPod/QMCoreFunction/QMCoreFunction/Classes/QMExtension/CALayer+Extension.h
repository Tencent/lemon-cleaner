//
//  CALayer+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (ScreenShot)
- (NSImage *)screenShot;
- (CGImageRef)createCGImage __attribute__((cf_returns_retained));
@end
