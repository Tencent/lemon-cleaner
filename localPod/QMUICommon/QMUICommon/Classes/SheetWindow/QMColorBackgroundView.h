//
//  QMColorBackgroundView.h
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMColorBackgroundView : NSView
{
    NSColor * m_backColor;
    NSArray * m_colorArray;
}

- (void)setBackColor:(NSColor *)backColor;
- (NSColor *)backColor;

- (void)setColorArray:(NSArray *)colorArray;
- (NSArray *)colorArray;

@end
