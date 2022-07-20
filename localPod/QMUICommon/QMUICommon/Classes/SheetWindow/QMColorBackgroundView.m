//
//  QMColorBackgroundView.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMColorBackgroundView.h"

@implementation QMColorBackgroundView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {

    }
    return self;
}

- (void)awakeFromNib
{
    m_colorArray = [NSArray arrayWithObjects:[NSColor colorWithSRGBRed:30.0 / 255
                                                                 green:35.0 / 255
                                                                  blue:39.0 / 255
                                                                 alpha:0.9]
                    ,[NSColor colorWithSRGBRed:39.0 / 255
                                         green:43.0 / 255
                                          blue:52.0 / 255
                                         alpha:0.9], nil];
}

- (void)drawRect:(NSRect)rect
{
    if (m_colorArray)
    {
        NSGradient *gradient = [[NSGradient alloc] initWithColors:m_colorArray];
        [gradient drawInRect:self.bounds angle:90];
    }
    else
    {
        [m_backColor set];
        NSRectFill(rect);
    }
}

- (void)setBackColor:(NSColor *)backColor
{
    m_backColor = backColor;
    [self setNeedsDisplay:YES];
}

- (NSColor *)backColor
{
    return m_backColor;
}


- (void)setColorArray:(NSArray *)colorArray
{
    m_colorArray = colorArray;
    [self setNeedsDisplay:YES];
}
- (NSArray *)colorArray
{
    return m_colorArray;
}

@end
