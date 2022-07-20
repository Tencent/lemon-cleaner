//
//  QMRoundButton.m
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMRoundButton.h"
#import "NSEvent+Extension.h"

@interface QMRoundButton ()<NSAnimationDelegate>
{
    //为了实现切换时展示缓动的效果
    NSImageView *bgView;
    NSImageView *showView;
    
    NSViewAnimation *animation;
}
@end

@implementation QMRoundButton
@synthesize borderWidth,borderColor,titleColor,borderColorHL,titleColorHL,borderColorDisable,titleColorDisable;

- (void)setUp
{
    borderWidth = 1.0;
    
    borderColor = [NSColor colorWithHex:0xbdc5cb];
    titleColor = [NSColor colorWithHex:0x7A8994];
    
    borderColorHL = [NSColor intlBlueColor];
    titleColorHL = [NSColor intlBlueColor];
    
    borderColorDisable = [NSColor colorWithHex:0xcfd8dd];
    titleColorDisable = [NSColor colorWithHex:0xcfd8dd];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    if (self.isHidden)
        return nil;
    
    //防止鼠标点击事件传递到了子视图
    if (NSPointInRect(aPoint, self.frame))
        return self;
    
    return nil;
}

- (void)drawBorder:(NSRect)dirtyRect
{
    NSColor *nowBorderColor = nil;
    
    QMStateType curst = [self buttonState];
    
    if (curst&QMState_disable)
        nowBorderColor = borderColorDisable;
    else if ((curst&QMState_hover) || (curst&QMState_pressed))
        nowBorderColor = borderColorHL;
    else
        nowBorderColor = borderColor;
    
    CGFloat nowBorderWidth = (curst&QMState_pressed) ? borderWidth*2.0 : borderWidth;
    
    [nowBorderColor set];
    NSRect rect = NSInsetRect(self.bounds, nowBorderWidth/2, nowBorderWidth/2);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:NSHeight(rect)/2 yRadius:NSHeight(rect)/2];
    [path setLineWidth:nowBorderWidth];
    [path stroke];
}

- (void)drawTitle:(NSRect)dirtyRect
{
    NSColor *nowTitleColor = nil;
    QMStateType curst = [self buttonState];
    
    if (curst&QMState_disable)
        nowTitleColor = titleColorDisable;
    else if ((curst&QMState_hover) || (curst&QMState_pressed))
        nowTitleColor = titleColorHL;
    else
        nowTitleColor = titleColor;
    
    if (nowTitleColor)
    {
        NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:self.title
                                                                         attributes:@{NSFontAttributeName:self.font,
                                                                                      NSForegroundColorAttributeName:nowTitleColor}];
        NSSize titleSize = [attributed size];
        //double topGap = titleSize.height - (self.font.ascender+fabs(self.font.descender));
        NSPoint drawPoint = NSMakePoint(NSMidX(self.bounds)-titleSize.width/2, NSMidY(self.bounds)-titleSize.height/2);
        
        /*
        if (self.isFlipped)
            drawPoint.y -= topGap/2;
        else
            drawPoint.y += topGap/2;
         */
        
        [attributed drawAtPoint:drawPoint];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    [super viewWillMoveToWindow:newWindow];
    
    if (!newWindow)
    {
        [animation stopAnimation];
    }
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    
    NSImage *image = [[NSImage alloc] initWithSize:self.bounds.size];
    [image lockFocus];
    [self drawBorder:self.bounds];
    [image unlockFocus];
    
    [bgView removeFromSuperview];
    bgView = showView;
    
    showView = [[NSImageView alloc] initWithFrame:self.bounds];
    [showView setImage:image];
    [showView setAlphaValue:0.0];
    [self addSubview:showView];
    
    [bgView setWantsLayer:YES];
    [showView setWantsLayer:YES];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [[bgView animator]setAlphaValue:0.0];
        [[showView animator] setAlphaValue:1.0];
    } completionHandler:^{
        [bgView setWantsLayer:NO];
        [showView setWantsLayer:NO];
    }];
}

- (void)dealloc
{
    [animation stopAnimation];
    animation.delegate = nil;
}

- (void)animationDidStop:(NSAnimation *)amn
{
    [self animationDidEnd:amn];
}

- (void)animationDidEnd:(NSAnimation *)amn
{
    [bgView setAlphaValue:0.0];
    [showView setAlphaValue:1.0];
    animation = nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    if (self.layer)
    {
        CGContextSetAllowsFontSmoothing(ctx, YES);
        CGContextSetShouldSmoothFonts(ctx, YES);
    }
    [self drawTitle:dirtyRect];
    CGContextRestoreGState(ctx);
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = YES;
    [self setNeedsDisplay];
    
    NSEvent *nextEvent = nil;
    while ((nextEvent=[self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask]) && nextEvent.type != NSLeftMouseUp)
    {
        //
    }
    
    if ([NSEvent mouseInView:self])
    {
        //强制纠正上一个事件造成的动画可能还没有结束的情况
        [bgView setAlphaValue:0.0];
        [showView setAlphaValue:1.0];
        [self sendAction:self.action to:self.target];
    }
    mouseDown = NO;
    [self setNeedsDisplay];
}


@end

#pragma mark -

@implementation QMMainRoundButton
@synthesize warning;

- (BOOL)warning
{
    return warning;
}

- (void)setWarning:(BOOL)value
{
    if (value == warning)
        return;
    
    warning = value;
    [self setUp];
    [self setNeedsDisplay];
}

- (void)setUp
{
    self.borderWidth = 2.0;
    
    if (warning)
    {
        NSColor *warnColor = [NSColor colorWithSRGBRed:255/255.0 green:146/255.0 blue:0/255.0 alpha:1.0];
        
        self.borderColor = warnColor;
        self.titleColor = warnColor;
        
        self.borderColorHL = warnColor;
        self.titleColorHL = warnColor;
        
        borderInnerColor = [NSColor colorWithSRGBRed:255/255.0 green:146/255.0 blue:0/255.0 alpha:0.7];
    }else
    {
        self.borderColor = [NSColor colorWithHex:0x51b465];
        self.titleColor = [NSColor colorWithHex:0x63b574];
        
        self.borderColorHL = [NSColor colorWithHex:0x51b465];
        self.titleColorHL = [NSColor colorWithHex:0x63b574];
        
        borderInnerColor = [NSColor colorWithHex:0xa7d9b2];
    }
    
    self.borderColorDisable = [NSColor colorWithHex:0xcfd8dd];
    self.titleColorDisable = [NSColor colorWithHex:0xcfd8dd];
}

- (void)drawBorder:(NSRect)dirtyRect
{
    [super drawBorder:dirtyRect];
    
    NSColor *innerColor = nil;
    QMStateType curst = [self buttonState];
    
    if (curst&QMState_disable)
        innerColor = self.borderColorDisable;
    else if ((curst&QMState_hover) || (curst&QMState_pressed))
        return;
    else
        innerColor = borderInnerColor;
    
    const CGFloat interDistance = 4.0;
    const CGFloat interBorderWidth = 1.0;
    
    NSRect rect = NSInsetRect(self.bounds, interDistance+interBorderWidth/2, interDistance+interBorderWidth/2);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:NSHeight(rect)/2 yRadius:NSHeight(rect)/2];
    [path setLineWidth:interBorderWidth];
    
    [innerColor set];
    [path stroke];
}

@end
