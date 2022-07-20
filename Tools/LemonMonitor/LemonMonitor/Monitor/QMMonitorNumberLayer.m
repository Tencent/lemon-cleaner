//
//  QMMonitorNumberLayer.m
//  QQMacMgrMonitor
//
//  Created by tanhao on 14-7-8.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMMonitorNumberLayer.h"

@implementation QMMonitorNumberLayer
@synthesize progress;

- (double)progress
{
    return progress;
}

- (void)setProgress:(double)value
{
    if (progress != value)
    {
        progress = value;
        
        NSString *textString = [NSString stringWithFormat:@"%2.0f%%",value*100];
        NSString *fontName = @"Helvetica Light";
        NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:textString
                                                                                          attributes:@{NSFontAttributeName: [NSFont safeFontWithName:fontName size:26],
                                                                                                       NSForegroundColorAttributeName:[NSColor whiteColor]}];
        [attributedStr addAttribute:NSFontAttributeName value:[NSFont safeFontWithName:fontName size:12] range:NSMakeRange(textString.length-1, 1)];
        self.string = attributedStr;
        
        [self setNeedsDisplay];
    }
}

- (void)drawInContext:(CGContextRef)ctx
{
    if (!self.string)
        return;
    
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);
    
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)self.string);
    CGRect rect = CTLineGetImageBounds(line, ctx);
    CGPoint pos = CGPointMake(CGRectGetMidX(self.bounds) - CGRectGetMidX(rect), CGRectGetMidY(self.bounds)- CGRectGetMidY(rect));
    CGContextSetTextPosition(ctx, pos.x, pos.y);
    
    CGContextSetFillColorWithColor(ctx, CGColorGetConstantColor(kCGColorWhite));
    CTLineDraw(line, ctx);
    CFRelease(line);
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
    {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

@end
