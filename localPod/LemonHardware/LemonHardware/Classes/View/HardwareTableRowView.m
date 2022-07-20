//
//  HardwareTableRowView.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareTableRowView.h"
#import <QuartzCore/QuartzCore.h>
#import <Masonry/Masonry.h>
#import "HardwareCellView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@implementation HardwareTableRowView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        m_selectedColor = [LMAppThemeHelper getMainBgColor];
    }
    return self;
}

- (void)addSubview:(NSView *)aView;
{
    [super addSubview:aView];
    if ([aView isKindOfClass:[HardwareCellView class]])
    {
        HardwareCellView * tableCell = (HardwareCellView *)aView;
        [tableCell setFrameSize:NSMakeSize(self.frame.size.width - tableCell.frame.origin.x, tableCell.frame.size.height)];
    }
    if ([aView isKindOfClass:[NSButton class]])
    {
        NSImage * _triangleImage = [NSImage imageNamed:@"triangleButton"  withClass:[self class]];
        NSImage * _triangleAlternateImage = [NSImage imageNamed:@"triangleButtonSelected"  withClass:[self class]];
        [(NSButton*)aView setImage:_triangleImage];
        [(NSButton*)aView setAlternateImage:_triangleAlternateImage];
        [aView setFrameOrigin:NSMakePoint(670, aView.frame.origin.y)];
        //        NSLog(@"width position = %f", self.frame.size.width - aView.frame.size.width - 62);
    }
    [self moveExpandButtonToFront];
}

// 当 outlineView reloadItem 时, 会触发 outlineView viewForTableColumn 重新调用,并重新调用 tableView 的 addSubView 方法. 这时会触发 expand button 位于 cellView 后面的问题.
// 如果不移动 expand button 没事(cell view 和 expand view 没有重合) 但移动 expand button 后就会有button 被遮挡的问题. 造成 button 无法响应事件.
// rowViw 可能会重新添加 cellView, 这时需要将 expand Button 置于最前面.

- (void)moveExpandButtonToFront {
    [self sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *)) compareViews context:nil];
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

//- (void)setSelected:(BOOL)selected
//{
//    [super setSelected:selected];
//    if ([[self subviews] count] > 0)
//    {
//        BigCleanParaentCellView * cellView =  [self viewAtColumn:0];
//        [cellView setHightLightStyle:selected];
//    }
//}

@end
