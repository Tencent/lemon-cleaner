//
//  QMMonitorCircleLayer.m
//  QQMacMgrMonitor
//
//  Created by tanhao on 14-7-8.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMMonitorCircleLayer.h"

@interface QMMonitorCircleLayer ()
{
    CGImageRef image;
}
@end

@implementation QMMonitorCircleLayer
@synthesize progress;

- (id)initWithCGImage:(CGImageRef)value
{
    self = [super init];
    if (self)
    {
        image = CGImageRetain(value);
    }
    return self;
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self)
    {
        progress = [(QMMonitorCircleLayer *)layer progress];
        image = CGImageRetain(((QMMonitorCircleLayer *)layer)->image);
    }
    return self;
}

- (void)dealloc
{
    CGImageRelease(image);
}

- (double)progress
{
    return progress;
}

- (void)setProgress:(double)value
{
    if (progress != value)
    {
        progress = value;
        [self setNeedsDisplay];
    }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
    {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
    
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);
    
    //画进度条
    {
        CGRect drawRect = self.bounds;
        CGMutablePathRef pathRef = CGPathCreateMutable();
        CGPathMoveToPoint(pathRef, NULL, NSMidX(drawRect), NSMidY(drawRect));
        CGPathAddArc(pathRef, NULL, NSMidX(drawRect), NSMidY(drawRect), NSWidth(drawRect)/2, M_PI/2, M_PI/2-2*M_PI*progress, YES);
        CGContextAddPath(ctx, pathRef);
        CGPathRelease(pathRef);
        CGContextClip(ctx);
        
        size_t imageWidth = CGImageGetWidth(image)/self.contentsScale;
        size_t imageHeight = CGImageGetHeight(image)/self.contentsScale;
        CGContextDrawImage(ctx, CGRectMake(CGRectGetMidX(drawRect)-imageWidth/2,
                                           CGRectGetMidY(drawRect)-imageHeight/2,
                                           imageWidth, imageHeight), image);
    }
}

@end
