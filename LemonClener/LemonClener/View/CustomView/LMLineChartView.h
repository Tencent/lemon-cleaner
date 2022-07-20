//
//  LMLineChartView.h
//  TestChart
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMLineChartView.h"
#import "LMDataSet.h"

#define kBufferValue 20

@protocol LineCharViewMouseOnLineEvent<NSObject>
- (void) mouseMoveOutSamplePoint:(NSPoint)point atIndex:(NSInteger)i;
- (void) mouseMoveOutSamplePoint;
@end


@interface LMLineChartView : NSView

@property (nonatomic, assign) BOOL doesDrawGrid;

@property (nonatomic, assign) BOOL doesDrawXAxisLines;

@property (nonatomic, assign) BOOL doesDrawYAxisLines;

@property (nonatomic, assign) BOOL doesDrawXAxisTicks;

@property (nonatomic, assign) BOOL doesDrawYAxisTicks;

@property (nonatomic, strong) NSColor * axisLineColor;

@property (nonatomic, strong) NSColor * gridLineColor;

@property (nonatomic, assign) float gridLineWidth;

@property (nonatomic, strong) NSDictionary * axisLabelAttributes;

@property (nonatomic, strong) NSArray * xAxisLabels;

@property (nonatomic, assign) float selectedPointRadius;

@property (nonatomic, assign) float selectedPointLineWidth;

@property (nonatomic, strong) NSColor * selectedPointColor;

@property (nonatomic, strong) NSColor * indicationBarColor;


@property (nonatomic) id<LineCharViewMouseOnLineEvent> mouseOnLineEventDelegate;

- (void)addDataSet:(LMDataSet *)dataSet;

- (void)removeDataSet:(LMDataSet *)dataSet;

- (void)clear;

- (void)addDataSetWithYValues:(NSArray *)values;

- (void)setAxisLineStyle:(NSArray<NSNumber *> *)axisLineStyle;
- (void)setGridLineStyle:(NSArray<NSNumber *> *)dashLineStyle;

@end
