//
//  QMOutlineView.m
//  QMCleaner
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMMoveOutlineView.h"
#import <QuartzCore/QuartzCore.h>

@implementation QMMoveOutlineView
@synthesize moveOutlineViewDelegate;

- (void)awakeFromNib
{
    _needAnimation = YES;
    m_lastRow = -1;
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes inParent:(id)parent withAnimation:(NSTableViewAnimationOptions)animationOptions
{
    [super removeItemsAtIndexes:indexes inParent:parent withAnimation:animationOptions];
    [self hiddenMoveButton];
}

- (void)updateTrackingAreas
{
    if ([moveOutlineViewDelegate outlineViewMoveButton])
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
}


- (void)resetMoveButton
{
    [self showMoveButton:m_lastRow];
}

- (void)showMoveButton:(NSInteger)row
{
    if ([moveOutlineViewDelegate respondsToSelector:@selector(canShowMoveButton:)]
        && [moveOutlineViewDelegate canShowMoveButton:row])//[item isKindOfClass:[QMResultItem class]] && [item path])
    {
        NSButton * moveButton = [moveOutlineViewDelegate outlineViewMoveButton];
        [self addSubview:moveButton];
        NSPoint point = [moveOutlineViewDelegate moveButtonPoint:row];
        [moveButton setFrameOrigin:point];
        [moveButton setHidden:NO];
        if (_needAnimation)
        {
            [moveButton setAlphaValue:0];
            [[NSAnimationContext currentContext] setDuration:0.5];
            [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [[moveButton animator] setAlphaValue:1];
        }
        [moveButton setTag:row];
    }
    else
    {
        [self hiddenMoveButton];
    }
}

- (void)hiddenMoveButton
{
    NSButton * moveButton = [moveOutlineViewDelegate outlineViewMoveButton];
    if (moveButton)
    {
        m_lastRow = -1;
        [moveButton setHidden:YES];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint eventPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:eventPoint];
    if (row == -1)
    {
        [self hiddenMoveButton];
        return;
    }
    if (row == m_lastRow)
        return;
    [self showMoveButton:row];
    m_lastRow = row;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    m_lastRow = -1;
    [self hiddenMoveButton];
}

- (void)scrollDidChange:(NSPoint)point
{
    NSInteger row = [self rowAtPoint:point];
    if (row == -1)
    {
        [self hiddenMoveButton];
        return;
    }
    if (row == m_lastRow)
        return;
    [self showMoveButton:row];
    m_lastRow = row;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint eventPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:eventPoint];
    if ([moveOutlineViewDelegate respondsToSelector:@selector(outlineViewWillShowMenu:)])
        [moveOutlineViewDelegate outlineViewWillShowMenu:row];
    [super rightMouseDown:theEvent];
}

@end


@implementation QMMoveScrollView

- (void)reflectScrolledClipView:(NSClipView *)cView
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    mouseLocation = [self.window convertRectFromScreen:(NSRect){mouseLocation, NSZeroSize}].origin;
    mouseLocation = [self convertPoint:mouseLocation fromView:nil];
    NSPoint eventPoint;
    eventPoint = mouseLocation;
    
    eventPoint.y += [[self contentView] documentVisibleRect].origin.y;
    [outlineView scrollDidChange:eventPoint];
    [super reflectScrolledClipView:cView];
}

@end
