//
//  QMNetworkPlotView.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef UInt64 PointType;

@interface QMNetworkPlotView : NSView
@property (assign, nonatomic) NSUInteger maxCount;
@property (assign, nonatomic) CGFloat vSpacing;
@property (strong, nonatomic) NSColor *upColor;
@property (strong, nonatomic) NSColor *downColor;
@property (assign, nonatomic) BOOL upsideDown;

@property (assign, nonatomic) CGFloat startAlpha;
@property (assign, nonatomic) CGFloat endAlpha;
@property (assign, nonatomic) CGFloat baseY;
@property (assign, readonly) PointType maxValue;    //网络真实数据的最大值
@property (assign, nonatomic) PointType displayMax;  //展示的坐标轴的最大值

- (void)replaceDataWithHistory:(NSArray *)history;
- (void)feed:(PointType)value;

@end
