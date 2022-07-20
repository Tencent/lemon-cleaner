//
//  QMHardwareWaitView.h
//  QMHardware
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMLoadingView : NSView
{
    CALayer * backLayer;
}
- (void)startAnimation;
- (void)stopAnimation;

@end
