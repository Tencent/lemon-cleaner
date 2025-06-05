//
//  OwlTableRowView.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlTableRowView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>
@implementation OwlTableRowView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _selectedColor =  [LMAppThemeHelper getTableViewRowSelectedColor];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
//- (void)drawBackgroundInRect:(NSRect)dirtyRect
//{
//    if ([self isFloating])
//    {
//        NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
//        [[NSColor colorWithCalibratedWhite:0.9 alpha:0.9] set];
//        [path fill];
//    }
//}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [_selectedColor set];
    [path fill];
}

@end
