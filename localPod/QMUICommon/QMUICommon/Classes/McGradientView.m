//
//  McGradientView.m
//  QQMacMgr
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "McGradientView.h"

@implementation McGradientView
@synthesize colorArray;
@synthesize angle;
@synthesize lineColor;

- (void)awakeFromNib
{
    lineColor = [NSColor colorWithSRGBRed:36.0 / 255
                                      green:40.0 / 255
                                       blue:48.0 / 255
                                      alpha:1];
    [self setColorArray:[NSArray arrayWithObjects:[NSColor colorWithSRGBRed:35.0 / 255
                                                                      green:41.0 / 255
                                                                       blue:45.0 / 255
                                                                      alpha:1],
                         [NSColor colorWithSRGBRed:46.0 / 255
                                             green:50.0 / 255
                                              blue:59.0 / 255
                                             alpha:1]
                         , nil]];
    [self setAngle:90];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect rect = self.bounds;
    rect.origin.x = dirtyRect.origin.x;
    rect.size.width = dirtyRect.size.width;
    if (lineColor)
    {
        NSBezierPath * path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, rect.size.height - 1.5)];
        [path lineToPoint:NSMakePoint(self.bounds.size.width, rect.size.height - 1.5)];
        [lineColor set];
        [path setLineWidth:1];
        [path stroke];
        rect.size.height = rect.size.height - 2;
    }
    NSGradient *gradient = [[NSGradient alloc] initWithColors:self.colorArray];
    [gradient drawInRect:rect angle:self.angle];
    //[super drawRect:dirtyRect];
    // Drawing code here.
}


@end
