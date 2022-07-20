//
//  DuplicateRowView.m
//  LemonDuplicateFile
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "DuplicateRowView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation DuplicateRowView {

    NSColor *m_selectedColor;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        m_selectedColor = [LMAppThemeHelper getTableViewRowSelectedColor];
    }

    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}


// MARK: 可以复写这个方法 , 提供背景的绘制 ,不然cell 背景可能是黑色的
- (void)drawBackgroundInRect:(NSRect)dirtyRect {

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[LMAppThemeHelper getMainBgColor] set];
    [path fill];
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [m_selectedColor set];
    [path fill];
}

//- (void)setSelected:(BOOL)selected {
//    [super setSelected:selected];
//    if ([[self subviews] count] > 0) {
//        BigCleanParaentCellView *cellView = [self viewAtColumn:0];
//        [cellView setHightLightStyle:selected];
//    }
//}

@end
