//
//  QMTrackScrollView.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMTrackScrollView.h"
#import "QMTrackOutlineView.h"

@interface QMTrackOutlineView (Scroll)
- (void)scrollDidChange:(NSPoint)point;
@end

@implementation QMTrackScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
    [super scrollWheel:theEvent];
    QMTrackOutlineView *outlineView = [self documentView];
    if ([outlineView isKindOfClass:[QMTrackOutlineView class]])
    {
        NSRect bound = [[self contentView] bounds];
        NSPoint eventPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        eventPoint.y += NSMinY(bound);
        
        if ((NSMinY(bound) < 0 || NSMaxY(bound) > NSHeight(outlineView.bounds)) && [theEvent phase] == NSEventPhaseEnded)
        {
            NSPoint mouseLocation = [NSEvent mouseLocation];
            NSRect mouseRect = NSMakeRect(mouseLocation.x, mouseLocation.y, 0, 0);
            mouseRect = [self.window convertRectFromScreen:mouseRect];
            mouseRect = [self convertRect:mouseRect fromView:nil];
            eventPoint = mouseRect.origin;
        }
        [outlineView scrollDidChange:eventPoint];
    }
}

@end
