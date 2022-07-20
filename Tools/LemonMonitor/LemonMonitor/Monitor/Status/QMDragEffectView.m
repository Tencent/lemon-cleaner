//
//  QMDragFloatView.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDragEffectView.h"
#import "JLNDragEffectManager.h"
#import <QMCoreFunction/NSScreen+Extension.h>
#import <QMCoreFunction/NSView+Extension.h>

@interface QMDragEffectView () <NSDraggingSource>
{
}
@end

@implementation QMDragEffectView
@synthesize effectMode;
@synthesize dragDelegate;

- (NSRect)statusBarRect
{
    NSRect statusBarRect;
    NSRect screenRect = [[NSScreen workScreen] visibleFrame];
    statusBarRect.origin.x = NSMinX(screenRect);
    statusBarRect.origin.y = NSMaxY(screenRect);
    statusBarRect.size.width = screenRect.size.width;
    statusBarRect.size.height = [[NSStatusBar systemStatusBar] thickness];
    statusBarRect = NSInsetRect(statusBarRect, -2, -2);
    return statusBarRect;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    
    NSRect statusBarRect = [self statusBarRect];
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (NSPointInRect(mouseLocation, statusBarRect))
    {
        NSDraggingSession *session = [self beginDraggingSessionWithItems:@[] event:theEvent source:self];
        session.animatesToStartingPositionsOnCancelOrFail = NO;
        session.draggingFormation = NSDraggingFormationNone;
    }
}

#pragma mark -
#pragma mark Dragging Source
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationNone;
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    [[NSCursor arrowCursor] set];
    NSPoint startPointInScreen = [NSEvent mouseLocation];
    
    NSImage *barImage = [dragDelegate dragEffectViewReplaceImage:self];
    NSImage *currentImage = [self screenShot];
    [[JLNDragEffectManager sharedDragEffectManager] startDragShowFromSourceScreenRect:[self statusBarRect]
                                                                      startingAtPoint:startPointInScreen
                                                                               offset:NSZeroSize
                                                                          insideImage:(self.effectMode==QMEffectStatusMode)?currentImage:barImage
                                                                         outsideImage:(self.effectMode==QMEffectStatusMode)?barImage:currentImage
                                                                            slideBack:NO];
    
    [dragDelegate dragEffectViewBegin:self];
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
    [[JLNDragEffectManager sharedDragEffectManager] updatePosition];
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    
    BOOL atStatusBar = NSPointInRect(mouseLocation, [self statusBarRect]);
    [[JLNDragEffectManager sharedDragEffectManager] setSlideBack:(self.effectMode==QMEffectStatusMode)&&atStatusBar];
    [[JLNDragEffectManager sharedDragEffectManager] endDragShowWithResult:operation];
    [dragDelegate dragEffectView:self endByMode:atStatusBar?QMEffectStatusMode:QMEffectFloatMode];
    
    //因为如果window已被orderOut,mouseUP就不会被调用到,所以强行调用一次
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.window isVisible]) {
            [self mouseUp:nil];
        }
    });
}

@end
