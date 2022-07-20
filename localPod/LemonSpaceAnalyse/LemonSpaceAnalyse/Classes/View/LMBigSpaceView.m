//
//  LMBigSpaceView.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMBigSpaceView.h"
#import <QMUICommon/QMBubble.h>
#import "LMItem.h"
#import "LMSpaceBubbleViewController.h"

@interface LMBigSpaceView ()

@property(nonatomic, strong) LMItem *item;
@property(nonatomic, strong) LMSpaceBubbleViewController *popoverVC;
@property(nonatomic, strong) NSPopover *popover;
@property(nonatomic, strong) NSTimer *timer;

@end

@implementation LMBigSpaceView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)updateTrackingAreas {
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *area in trackingAreas)
    {
        [self removeTrackingArea:area];
    }

    NSRect treeMapRect = CGRectMake(self.frame.origin.x + 5, self.frame.origin.y + 10, self.frame.size.width - 24, self.frame.size.height - 15);
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:treeMapRect options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (void)mouseMoved:(NSEvent *)event{
//    NSPoint point =  [self.superview.window.contentView convertPoint:event.locationInWindow toView:self];
//    [self.popover showRelativeToRect:NSMakeRect(point.x, point.y+10, 15 , 15) ofView:self preferredEdge:NSMaxXEdge];
}

- (void)mouseEntered:(NSEvent *)event {
//    NSPoint point =  [self.superview.window.contentView convertPoint:event.locationInWindow toView:self];
//    [self.popover showRelativeToRect:NSMakeRect(point.x, point.y, 15 , 15) ofView:self preferredEdge:NSMaxXEdge];
}

- (void)mouseExited:(NSEvent *)event {
    [self.popover close];
}


- (NSPopover *)popover {
    if (_popover) {
        return _popover;
    }
    self.popoverVC = [[LMSpaceBubbleViewController alloc] init];
    _popover = [[NSPopover alloc] init];
    _popover.animates = NO;
    _popover.contentViewController = self.popoverVC;
    return _popover;
}

- (BOOL)isFlipped {
    return YES;
}

#pragma mark - delegate

-(void)LMSpaceViewmouse:(LMItem *)item {
    if (self.item == item) {
        return;
    }
    self.item = item;
    [self.popoverVC setUpData:item];
}

-(void)LMSpaceViewInfoClose:(BOOL)result {
    [self.popover close];
}

-(void)LMSpaceViewInfoPoint:(NSPoint)point {
    
    [self.popover showRelativeToRect:NSMakeRect(point.x, point.y+10, 15 , 15) ofView:self preferredEdge:NSMaxXEdge];

    
}

@end
