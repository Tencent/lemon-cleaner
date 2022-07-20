//
//  LMDataSet.m
//  TestChart
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMDataSet.h"

@implementation LMDataSet
- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color {
    return [self initWithValues:values withColor:color andFillColor:nil];
}

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andFillColor:(NSColor *)fillColor {
    return [self initWithValues:values withColor:color withColorEnd:color andFillColorStart:fillColor andFillColorEnd:fillColor andLineWidth:2];
}

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andLineWidth:(CGFloat)lineWidth {
    return [self initWithValues:values withColor:color withColorEnd:color andFillColorStart:nil andFillColorEnd:nil andLineWidth:2];
}


- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)color andFillColor:(NSColor *)fillColor andLineWidth:(CGFloat)lineWidth{
    return [self initWithValues:values withColor:color withColorEnd:color andFillColorStart:fillColor andFillColorEnd:fillColor andLineWidth:lineWidth];
}

- (instancetype)initWithValues:(NSArray *)values withColor:(NSColor *)colorStart withColorEnd:(NSColor *) colorEnd andFillColorStart:(NSColor *)fillColorStart andFillColorEnd:(NSColor *)fillColorEnd andLineWidth:(CGFloat)lineWidth
{
    if (self = [super init]){
        _values = values;
        _colorStart = colorStart;
        _colorEnd = colorEnd;
        _fillColorStart = fillColorStart;
        _fillColorEnd = fillColorEnd;
        _lineWidth = lineWidth;
    }
    return self;
}


- (void)dealloc {
    _values = nil;
    _colorStart = nil;
    _colorEnd = nil;
    _fillColorStart = nil;
    _fillColorEnd = nil;
}

@end
