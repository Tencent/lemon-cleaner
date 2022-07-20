//
//  LMDataSet.h
//  TestChart
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface LMDataSet : NSObject

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color; // Set values and color in which the data will be display

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andFillColor:(NSColor *)fillColor; // Set values, line color, and fillColor of the line

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andLineWidth:(CGFloat)lineWidth; // Set values, line color, and lineWidth of the line

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andFillColor:(NSColor *)fillColor andLineWidth:(CGFloat)lineWidth; // Set values, line color, fillColor and lineWidth of the line

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)colorStart withColorEnd:(NSColor *) colorEnd andFillColorStart:(NSColor *)fillColorStart andFillColorEnd:(NSColor *)fillColorEnd andLineWidth:(CGFloat)lineWidth; // Set values, line color, fillColor and lineWidth of the line


@property (nonatomic, readonly, strong) NSColor *colorStart;

@property (nonatomic, readonly, strong) NSColor *colorEnd;

@property (nonatomic, readonly, strong) NSArray *values;

@property (nonatomic, readonly) CGFloat lineWidth;

@property (nonatomic, readonly, strong) NSColor *fillColorStart;

@property (nonatomic, readonly, strong) NSColor *fillColorEnd;

@end
