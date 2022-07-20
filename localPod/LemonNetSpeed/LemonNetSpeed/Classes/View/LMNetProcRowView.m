//
//  QMTableRowView.m
//  QMCleaner
//
//  
//  Copyright (c) 2019年 Tencent. All rights reserved.
//

#import "LMNetProcRowView.h"
#import <QuartzCore/QuartzCore.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation LMNetProcRowView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        m_selectedColor =  [LMAppThemeHelper getTableViewRowSelectedColor];
    }
    return self;
}

NSComparisonResult compareViews(id firstView, id secondView, void *context) {
    
    if ([firstView isKindOfClass:NSButton.class]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedAscending;
    }
}

-(void)didAddSubview:(NSView *)subview
{
    [super didAddSubview:subview];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
    //    if ([self isFloating])
    //    {
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[LMAppThemeHelper getMainBgColor] set];
    [path fill];
    //    }
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [m_selectedColor set];
    [path fill];
}



@end

