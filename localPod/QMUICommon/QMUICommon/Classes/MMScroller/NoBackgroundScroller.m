//
//  NoBackgroundScroller.m
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#define SCROLLER_WIDTH 12
#define FRAME_COUNT 10
#define DISAPPERA_DELAY 0.3
#import "NoBackgroundScroller.h"

@implementation NoBackgroundScroller{
    int _animationStep;
    BOOL _scheduled;
    BOOL _disableFade;
    BOOL _shouldClearBackground;
    float _oldValue;
    NSTrackingArea *trackingArea;
    
}




//  frameDidChangeNotification using NSNotificationCenter (if using Swift 3, it's NSNotification.Name.NSViewFrameDidChange
//- (BOOL)postsFrameChangedNotifications{
//
//}

// 修改滚动条的宽度 (设置过细的话,knob不像是.9图)
+ (CGFloat)scrollerWidthForControlSize:(NSControlSize)controlSize scrollerStyle:(NSScrollerStyle)scrollerStyle{
    return SCROLLER_WIDTH;
}
//+ (CGFloat)scrollerWidth {
//    return SCROLLER_WIDTH;
//}
//
//+ (CGFloat)scrollerWidthForControlSize: (NSControlSize)controlSize {
//    return SCROLLER_WIDTH;
//}

- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
    
    // 这样的滚动条默认不会auto hide, 所以使用透明度进行更改.
    // 出现的问题: 进度条的颜色在 hover
    CGFloat alphaValue =  1 * (CGFloat) _animationStep / (CGFloat) FRAME_COUNT;
    [self setAlphaValue:alphaValue];
    
    [self drawKnob];
}

// 这个方法可以 custom knob, .9图
- (void)drawKnob{
    
    
//    NSPoint p = NSMakePoint(0.0, 0.0);
//    [knobImage drawAtPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [super drawKnob];
}



- (void) setFloatValue:(float)value
{
    [super setFloatValue:value];
    [self _showKnob];
    
    //    if (_oldValue != value) {
    //        [self _showKnob];
    //        _oldValue = value;
    //    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    _animationStep = FRAME_COUNT;
    _disableFade = YES;
    [self _updateKnob];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    [self _showKnob];
}

- (void) updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
    
    [self addTrackingArea:trackingArea];
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
    }
}

- (void) _showKnob
{
    _animationStep = FRAME_COUNT;
    _disableFade = YES;
    [self _updateKnob];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_showKnobAfterDelay) object:nil];
    [self performSelector:@selector(_showKnobAfterDelay) withObject:nil afterDelay:0.5];
}

- (void) _showKnobAfterDelay
{
    _disableFade = NO;
    _animationStep = FRAME_COUNT;
    if (!_scheduled) {
        [self _updateKnob];
    }
}

- (void) _updateKnob
{
    [self setNeedsDisplay:YES];
    
    if (_animationStep > 0) {
        if (!_disableFade) {
            if (!_scheduled) {
                _scheduled = YES;
                [self performSelector:@selector(_updateKnobAfterDelay) withObject:nil afterDelay:DISAPPERA_DELAY / FRAME_COUNT];
                _animationStep --;
            }
        }
    }else{
        //        _animationStep = FRAME_COUNT;
    }
}

- (void) _updateKnobAfterDelay
{
    _scheduled = NO;
    [self _updateKnob];
}

@end
