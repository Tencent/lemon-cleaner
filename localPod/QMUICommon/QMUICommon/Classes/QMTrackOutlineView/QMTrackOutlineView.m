//
//  QMTrackOutlineView.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMTrackOutlineView.h"

NSString *QMTrackRowDidChangedNotification = @"QMTrackRowDidChangedNotification";

@interface QMTrackOutlineView()
{
    NSInteger lastOverRow;
}
@end

@implementation QMTrackOutlineView
@synthesize overView;
@synthesize showLevel;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUp
{
    [self hideOverView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSOutlineViewSelectionDidChangeNotification
                                               object:self];
}

- (NSView *)overView
{
    return overView;
}

- (void)setOverView:(NSView *)aView
{
    if (overView != aView)
    {
        [overView removeFromSuperview];
        [self addSubview:aView];
        [aView setHidden:YES];
        overView = aView;
    }
}

- (NSInteger)trackRow
{
    return lastOverRow;
}

- (void)selectionDidChange:(NSNotification *)notify
{
    [self mouseMoved:nil];
}

- (void)updateTrackingAreas
{
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint eventPoint = NSZeroPoint;
    if (theEvent)
    {
        eventPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    }else
    {
        eventPoint = [NSEvent mouseLocation];
        NSRect eventRect = NSMakeRect(eventPoint.x, eventPoint.y, 0, 0);
        eventRect = [self.window convertRectFromScreen:eventRect];
        eventRect = [self convertRect:eventRect fromView:nil];
        eventPoint = eventRect.origin;
    }
    NSInteger row = [self rowAtPoint:eventPoint];
    if (row == -1)
        [self hideOverView];
    else
        [self showOverView:row];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self mouseMoved:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self hideOverView];
}

- (void)showOverView:(NSInteger)row
{
    //当不存在视图
    if (!overView)
    {
        return;
    }
    //当指定了特定的层
    if (showLevel && ![showLevel containsIndex:[self levelForRow:row]])
    {
        [self hideOverView];
        return;
    }
    //当与上次显示相同
    if (row == lastOverRow)
    {
        return;
    }
    
    //先移出再添加,防止被其它子View覆盖
    NSRect rect = [self rectOfRow:row];
    NSRect overRect = overView.frame;
    [overView removeFromSuperview];
    overRect.origin.y = NSMidY(rect)-NSHeight(overRect)/2;
    overView.frame = overRect;
    
    [overView setAlphaValue:0];
    [overView setHidden:NO];
    [self addSubview:overView];
    [[overView animator] setAlphaValue:1.0];
    
    lastOverRow = row;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QMTrackRowDidChangedNotification
                                                        object:self
                                                      userInfo:@{@"offset":@(overView.frame.origin.x),
                                                                 @"width": @(rect.size.width)}];
}

- (void)hideOverView
{
    lastOverRow = -1;
    if (![overView isHidden])
    {
        [overView setHidden:YES];
        NSRect rect = [self rectOfRow:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:QMTrackRowDidChangedNotification
                                                            object:self
                                                          userInfo:@{@"offset": @0,
                                                                     @"width": @(rect.size.width)}];
    }
}

- (void)addSubview:(NSView *)aView
{
    [super addSubview:aView];
    
    if (overView && aView != overView)
    {
        [self addSubview:overView positioned:NSWindowAbove relativeTo:nil];
    }
}

- (void)reloadData
{
    [super reloadData];
    [self mouseMoved:nil];
}

- (void)scrollDidChange:(NSPoint)point
{
    NSInteger row = [self rowAtPoint:point];
    if (row == -1)
        [self hideOverView];
    else
        [self showOverView:row];
}

@end
