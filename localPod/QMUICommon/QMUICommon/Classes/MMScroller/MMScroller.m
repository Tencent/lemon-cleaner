//
//  MMScroller.m
//  MiniMail
//
//  Created by DINH Viêt Hoà on 21/02/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import "MMScroller.h"
#import "MMDrawingUtils.h"
#import "NSColor+Extension.h"
#import "LMAppThemeHelper.h"

@interface MMScroller (){
    NSTrackingArea * trackingArea;
}

- (void) _showKnob;
- (void) _updateKnob;
- (void) _updateKnobAfterDelay;

@end

@implementation MMScroller

@synthesize shouldClearBackground = _shouldClearBackground;

#define FRAME_COUNT 10
#define DISAPPERA_DELAY 0.3

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setUpData];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUpData];
    }
    return self;
}

-(void)setUpData
{
    _oldValue = 0;
    _shouldClearBackground = YES;
}

- (void) dealloc
{
    for (NSTrackingArea *area in [self trackingAreas]) {
		[self removeTrackingArea:area];
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

// 是否 overlay : 使用了这行代码,引入了一个坑爹的问题: 在 系统偏好设置->通用->修改 show scroll bars 选项的值为 always. 会引发 scrollbar 不绘制的问题.
// (触发的情况是配合下面的scrollerStyle 为 NSScrollerStyleOverlay)
//+ (BOOL)isCompatibleWithOverlayScrollers{
//    return YES;
//}


// 
+ (BOOL)isCompatibleWithResponsiveScrolling{
    return YES;
}

- (NSScrollerStyle)scrollerStyle{
    //    return NSScrollerStyleOverlay;  //坑底的bug:使用这个但不开启isCompatibleWithOverlayScrollers, 会造成滚动条无法拖动.
    return NSScrollerStyleLegacy;

}


// draw knob 的时候会 带 slot, 强制不画 slot. 但是 rectForPart
- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag{
    [self drawKnob];
}

- (void)drawKnob
{
    if (_shouldClearBackground) {
        NSEraseRect(self.bounds);

// NSRectFillUsingOperation 会将底部的颜色(superView)也清空掉,要小心这个方法
        [[NSColor clearColor] set];  // 设置背景透明
        NSRectFillUsingOperation(self.bounds, NSCompositeClear);
    }

    
	CGFloat alphaValue;
	
	alphaValue = 0.5 * (float) _animationStep / (float) FRAME_COUNT;
    if ([self bounds].size.width < [self bounds].size.height) {
        //        [[NSColor colorWithCalibratedWhite:0.2 alpha:alphaValue] setFill];  // 看注释 CalibratedWhite可能被 sRGB 或 P3色域  覆盖掉.
        // 绘制
        //MARK: 为什么要加个变化的透明度？
//        [[NSColor colorWithHex:0x000000 alpha:(0.6 * alphaValue)] setFill];
        [[LMAppThemeHelper getScrollbarColor] setFill];

        NSRect rect = [self rectForPart:NSScrollerKnob];
        rect.size.width = 6;
        rect.origin.x = 0;
        rect.origin.x += 6.0;
        MMFillRoundedRect(rect, 4, 4);
    }
    else {
        // horiz scrollbar
//        [[NSColor colorWithCalibratedWhite:0.2 alpha:alphaValue] setFill];
        [[LMAppThemeHelper getScrollbarColor] setFill];
        NSRect rect = [self rectForPart:NSScrollerKnob];
        rect.size.height = 6;
        rect.origin.y = 0;
        rect.origin.y += 6.0;
        MMFillRoundedRect(rect, 4, 4);
    }
}

- (void) drawRect:(NSRect)rect
{
	[self drawKnob];
}

- (void) setFloatValue:(float)value
{
	[super setFloatValue:value];
	if (_oldValue != value) {
		[self _showKnob];
		_oldValue = value;
	}
}

- (void) showScroller
{
    [self _showKnob];
}

//- (void)mouseMoved:(NSEvent *)theEvent
//{
//	[super mouseMoved:theEvent];
//	[self _showKnob];
//}

 // 鼠标移动到 scoller 后, 会自动显示 scroller, 而系统的scroller 并没有这个效果. fix的问题: 当scrollview 内容很少时,不应该显示scroller.

- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    if(_oldValue == 0){
        return;
    }
    
	_animationStep = FRAME_COUNT;
	_disableFade = YES;
	[self _updateKnob];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    if(_oldValue == 0){
        return;
    }
    
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
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void) _showKnob
{
	_animationStep = FRAME_COUNT;
    _disableFade = YES;
	[self _updateKnob];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_showKnobAfterDelay) object:nil];
    //    fixbug: 在模态窗口 RunLoop 的 mode为NSModalPanelRunLoopMode.普通窗口的 Runloop 为 NSDefaultRunLoopMode.  performSelector 默认加入的 mode 为NSDefaultRunLoopMode.会造成在模态窗口中的 对应的@selector无法执行的问题.
    //    [self performSelector:@selector(_showKnobAfterDelay) withObject:nil afterDelay:0.5];
    //    NSLog(@"mode is %@", [NSRunLoop currentRunLoop].currentMode);
    [self performSelector:@selector(_showKnobAfterDelay) withObject:nil afterDelay:0.5 inModes:@[NSDefaultRunLoopMode, NSModalPanelRunLoopMode]];
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
				 [self performSelector:@selector(_updateKnobAfterDelay) withObject:nil afterDelay:DISAPPERA_DELAY / FRAME_COUNT inModes:@[NSDefaultRunLoopMode, NSModalPanelRunLoopMode]];
				_animationStep --;
			}
		}
	}
}

- (void) _updateKnobAfterDelay
{
	_scheduled = NO;
	[self _updateKnob];
}

@end
