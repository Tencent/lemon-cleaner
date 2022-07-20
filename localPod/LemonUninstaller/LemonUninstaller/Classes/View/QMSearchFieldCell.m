//
//  QMSearchFieldCell.m
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSearchFieldCell.h"
#import "NSColor+Extension.h"
#import <QMUICommon/LMAppThemeHelper.h>

@implementation QMSearchFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [[NSColor colorWithCalibratedRed:201/255.0 green:210/255.0 blue:214/255.0 alpha:1.0] set];
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 0.5, 0.5) xRadius:4 yRadius:4];
    [bezierPath setLineWidth:1.0];
    [bezierPath stroke];
    
    [self.searchButtonCell drawWithFrame:[self searchButtonRectForBounds:cellFrame] inView:controlView];
    if ([[self stringValue] length] > 0)
    {
        [self.cancelButtonCell drawWithFrame:[self cancelButtonRectForBounds:cellFrame] inView:controlView];
    }
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    NSText *textView = [super setUpFieldEditorAttributes:textObj];
    if ([textView respondsToSelector:@selector(setInsertionPointColor:)])
    {
        [(NSTextView*)textView setInsertionPointColor:[LMAppThemeHelper getTitleColor]];
    }
    return textView;
}

@end
