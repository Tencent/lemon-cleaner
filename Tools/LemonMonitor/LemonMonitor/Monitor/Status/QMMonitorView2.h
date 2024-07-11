//
//  QMMonitorView.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMMonitorView2:NSView

@property (nonatomic, copy) void(^actionBlock)(void);
@property (nonatomic, copy) void(^mouseDownBlock)(void);
@property (nonatomic, copy) void(^mouseUpBlock)(void);
@property (nonatomic, copy) void(^mouseEnterBlock)(void);
@property (nonatomic, copy) void(^mouseExitBlock)(void);

@property (nonatomic, assign) double ramUsed;
@property (nonatomic, assign) double diskUsed;
@property (nonatomic, assign) float upSpeed;
@property (nonatomic, assign) float downSpeed;
@property (nonatomic, assign) double temperatureValue;
@property (nonatomic, assign) float fanSpeedValue;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) double cpuUsed;
@property (nonatomic, assign) double gpuUsed;

- (void)startLoadingAnimation;
- (void)stopLoadingAnimation;
- (void)setRamValue:(double)value completeHandler:(void(^)(void))handler;

@end
