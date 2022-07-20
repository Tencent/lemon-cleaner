//
//  QMBubble.m
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMBubble.h"
#import "QMBubbleView.h"
#import "QMBubbleWindow.h"
#import "QMButton.h"

#define QMBUBBLE_ANIMATION_DURATION (0.2)

@interface QMBubble ()<NSAnimationDelegate>
{
    QMBubbleView *bubbleView;
    QMBubbleWindow *bubbleWindow;
    
    NSPoint positioningPoint;
    NSWindow *positioningWindow;
    
    id localMonitor;
    id outsideMonitor;
    
    NSViewAnimation *showAnimation;
    NSViewAnimation *dismissAnimation;
    void (^_animtionCompletion)(QMBubble *);
    
}

@end

@implementation QMBubble
@synthesize contentView;
@synthesize viewController;
@synthesize animation;
@synthesize arrowOffset;
@synthesize autoCloseMask;
@synthesize bubbleWindow;
@dynamic attachedToParentWindow;

@dynamic direction, drawArrow, arrowHeight;
@dynamic arrowWidth, arrowDistance, cornerRadius;
@dynamic borderWidth, borderColor, backgroudColor;
@dynamic draggable, titleMode, distance;

- (id)init
{
    self = [super init];
    if (self)
    {
        animation = YES;
        
        bubbleView = [[QMBubbleView alloc] initWithFrame:NSZeroRect];
        bubbleWindow = [[QMBubbleWindow alloc] initWithContentRect:NSZeroRect];
        [bubbleWindow setContentView:bubbleView];
    }
    return self;
}


- (BOOL)keyWindow
{
    return [bubbleWindow canBecomeKeyWindow];
}

- (void)setKeyWindow:(BOOL)keyWindow
{
    bubbleWindow.keyWindowMode = keyWindow;
}

- (BOOL)isVisible
{
    return [bubbleWindow isVisible];
}

#pragma mark -

- (NSView *)contentView
{
    return contentView;
}

- (void)setContentView:(NSView *)view
{
    contentView = view;
    
    NSArray *subViews = [bubbleView subviews];
    for (NSView *aView in subViews)
    {
        [aView removeFromSuperview];
    }
    
    if (!contentView)
        return;
    
    [contentView removeFromSuperview];
    [bubbleView addSubview:contentView];
}

- (NSViewController *)viewController
{
    return viewController;
}

- (void)setViewController:(NSViewController *)vc
{
    viewController = vc;
    [self setContentView:viewController.view];
}

- (void)showToPoint:(NSPoint)point ofView:(NSView *)view
{
    if (!view.window)
        return;
    
    [self showToPoint:[view convertPoint:point toView:nil] ofWindow:view.window];
}

- (NSPoint)arrowPoint
{
    NSPoint point = bubbleView.arrowPoint;
    point = [bubbleView convertPoint:point toView:nil];
    point = [bubbleWindow convertRectToScreen:(NSRect){point, NSZeroSize}].origin;
    return point;
}

- (void)showToPoint:(NSPoint)point ofWindow:(NSWindow *)window
{
    [dismissAnimation stopAnimation];
    dismissAnimation = nil;
    
    //计算泡泡的实际显示坐标
    positioningWindow = window;
    if (positioningWindow) {
        NSRect rect = NSMakeRect(point.x, point.y, 0, 0);
        rect = [window convertRectToScreen:rect];
        positioningPoint = rect.origin;
    } else {
        positioningPoint = point;
    }
    [self show];
    
    BOOL needAnimation = animation && ![bubbleWindow isVisible];
    if (needAnimation) {
        bubbleWindow.alphaValue = 0.0;
    }
    
    [self attachToParentWindow];
    
    self.titleMode = QMBubbleTitleModeArrow;
    [bubbleWindow makeKeyAndOrderFront:nil];
    //[bubbleWindow orderFront:nil];
    
    if (needAnimation) {
        if (!showAnimation) {
            showAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[@{NSViewAnimationTargetKey: bubbleWindow,NSViewAnimationEffectKey: NSViewAnimationFadeInEffect}]];
            showAnimation.animationBlockingMode = NSAnimationNonblocking;
            showAnimation.delegate = self;
            showAnimation.duration = QMBUBBLE_ANIMATION_DURATION;
            [showAnimation startAnimation];
        }
    } else {
        bubbleWindow.alphaValue = 1.0;
    }
    
    //监控外部事件用于自动关闭
    if ((autoCloseMask & QMBubbleAutoCloseLocal) && !localMonitor)
    {
        localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^NSEvent *(NSEvent *event) {
            if (event.window != bubbleWindow || ![bubbleView mouseInPath])
                [self dismiss];
            return event;
        }];
    }
    if ((autoCloseMask & QMBubbleAutoCloseOutside) && !outsideMonitor)
    {
        outsideMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent *event) {
            [self dismiss];
        }];
    }
}

- (void)detatchFromParentWindow
{
    if (!self.attachedToParentWindow) return;
    self.titleMode = QMBubbleTitleModeTitleBar;
    [positioningWindow removeChildWindow:bubbleWindow];
}

- (BOOL)attachedToParentWindow
{
    return nil != bubbleWindow.parentWindow;
}

- (void)attachToParentWindow
{
    if (self.attachedToParentWindow) return;
    self.titleMode = QMBubbleTitleModeArrow;
    [positioningWindow addChildWindow:bubbleWindow ordered:NSWindowAbove];
}

- (void)animationDidEnd:(NSViewAnimation *)anm
{
    if (anm == dismissAnimation)
    {
        [bubbleWindow orderOut:nil];
        [positioningWindow removeChildWindow:bubbleWindow];
        positioningWindow = nil;
        if (_animtionCompletion) {
            _animtionCompletion(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"QMMonitorDismiss" object:nil];
    }
}

- (void)dismiss
{
    [self dismissWithCompletion:nil];
}
- (void)dismissWithCompletion:(void (^)(QMBubble *))completion
{
    _animtionCompletion = [completion copy];
    
    [showAnimation stopAnimation];
    showAnimation = nil;
    
    if (animation)
    {
        if (!dismissAnimation)
        {
            dismissAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[@{NSViewAnimationTargetKey: bubbleWindow,NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect}]];
            dismissAnimation.animationBlockingMode = NSAnimationNonblocking;
            dismissAnimation.delegate = self;
            dismissAnimation.duration = QMBUBBLE_ANIMATION_DURATION;
            [dismissAnimation startAnimation];
        }
    } else {
        [bubbleWindow orderOut:nil];
        [positioningWindow removeChildWindow:bubbleWindow];
        positioningWindow = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"QMMonitorDismiss" object:nil];
    }
    
    if (localMonitor)
    {
        [NSEvent removeMonitor:localMonitor];
        localMonitor = nil;
    }
    if (outsideMonitor)
    {
        [NSEvent removeMonitor:outsideMonitor];
        outsideMonitor = nil;
    }
}

- (NSRect)windowFrameContentFrame:(NSRect *)contentFramePointer
{
    NSPoint showPoint = positioningPoint;
    QMArrowDirection direction = bubbleView.direction;
    *contentFramePointer = NSMakeRect(self.borderWidth + self.edgeInsets.left, self.borderWidth + self.edgeInsets.bottom, NSWidth(contentView.bounds), NSHeight(contentView.bounds));
    NSRect windowFrame = NSInsetRect(*contentFramePointer, -self.borderWidth, -self.borderWidth);
    windowFrame.size.width += self.edgeInsets.right;
    windowFrame.size.height += self.edgeInsets.top;
    
    BOOL topOrBottom = (direction & QMArrowSideTop) || (direction & QMArrowSideBottom);
    //设置window的size
    if (self.drawArrow || self.titleMode == QMBubbleTitleModeTitleBar)
    {
        if (topOrBottom) {
            windowFrame.size.height += self.arrowHeight;
        } else {
            windowFrame.size.width += self.arrowHeight;
        }
    }
    bubbleView.frame = NSMakeRect(0, 0, NSWidth(windowFrame), NSHeight(windowFrame));
    //设置window的origin
    CGFloat halfHeight = NSHeight(windowFrame) / 2;
    CGFloat halfWidth  = NSWidth(windowFrame)  / 2;

    if (direction & QMArrowSideTop) {
        windowFrame.origin.y = showPoint.y - NSHeight(windowFrame) - arrowOffset;
        windowFrame.origin.x = showPoint.x - halfWidth;
    } else if (direction & QMArrowSideBottom) {
        windowFrame.origin.y = showPoint.y + arrowOffset;
        windowFrame.origin.x = showPoint.x -halfWidth;
    } else if (direction & QMArrowSideLeft) {
        windowFrame.origin.x = showPoint.x + arrowOffset;
        windowFrame.origin.y = showPoint.y - halfHeight;
    } else if (direction & QMArrowSideRight) {
        windowFrame.origin.x = showPoint.x - NSWidth(windowFrame)- arrowOffset;
        windowFrame.origin.y = showPoint.y - halfHeight;
    }
    
    CGFloat offset = bubbleView.drawDistance + bubbleView.borderWidth/2;
    if (topOrBottom) {
        if (direction & QMArrowLeft) {
            windowFrame.origin.x += (halfWidth - offset);
        } else if (direction & QMArrowRight) {
            windowFrame.origin.x -= (halfWidth - offset);
        }
    } else {
        if (direction & QMArrowTop) {
            windowFrame.origin.y -= (halfHeight - offset);
        } else if (direction & QMArrowBottom) {
            windowFrame.origin.y += (halfHeight - offset);
        }
    }
    
    //设置content坐标
    if (self.drawArrow || self.titleMode == QMBubbleTitleModeTitleBar) {
        if (direction & QMArrowSideBottom)
            contentFramePointer->origin.y += self.arrowHeight;
        
        if (direction & QMArrowSideLeft)
            contentFramePointer->origin.x += self.arrowHeight;
    }

    return windowFrame;
}

- (void)show
{
    if (!contentView)
        return;
    NSRect contentFrame = NSZeroRect;
    NSRect windowFrame = [self windowFrameContentFrame:&contentFrame];

    //设置content坐标
    
    [bubbleView refreshShadow];
    if (bubbleWindow.isVisible)
    {
        [bubbleWindow setFrame:windowFrame display:YES];
        NSArray *infos = @[@{NSViewAnimationTargetKey: contentView, NSViewAnimationEndFrameKey: [NSValue valueWithRect:contentFrame]}];
        NSViewAnimation *changeAnimation = [[NSViewAnimation alloc] initWithViewAnimations:infos];
        changeAnimation.animationBlockingMode = NSAnimationNonblocking;
        changeAnimation.duration = QMBUBBLE_ANIMATION_DURATION;
        [changeAnimation startAnimation];
    } else {
        [bubbleWindow setFrame:windowFrame display:YES];
        [contentView setFrame:contentFrame];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([bubbleView respondsToSelector:aSelector]) {
        return bubbleView;
    }
    return [super forwardingTargetForSelector:aSelector];
}


@end
