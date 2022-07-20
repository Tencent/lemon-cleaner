//
//  QMStatusCircleView.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMStatusCircleView : NSView
@property (nonatomic, assign) double progress;
@property (nonatomic, copy) void(^actionBlock)(void);
@end
