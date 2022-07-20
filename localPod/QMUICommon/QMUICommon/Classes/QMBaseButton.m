//
//  QMBaseButton.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMBaseButton.h"
#import "NSEvent+Extension.h"

@implementation QMBaseButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
        [self setNeedsDisplay];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUp];
        [self setNeedsDisplay];
    }
    return self;
}

- (void)setUp
{
    
}

- (QMStateType)buttonState
{
    QMStateType curst = 0;
    if (self.state == NSOffState)
        curst |= QMState_off;
    else if (self.state == NSMixedState)
        curst |= QMState_mixed;
    else
        curst |= QMState_on;
    
    if (!self.isEnabled)
        curst |= QMState_disable;
    else if (mouseDown)
        curst |= QMState_pressed;
    else if (mouseEnter )
        curst |= QMState_hover;
    else
        curst |= QMState_normal;
    
    return curst;
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
}

- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    [self setNeedsDisplay];
}

- (void)setState:(NSInteger)value
{
    [super setState:value];
    [self setNeedsDisplay];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        if (area.owner == self)
            [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways|NSTrackingAssumeInside
                                                                  owner:self
                                                               userInfo:nil];
    
    if ([NSEvent mouseInView:self])
    {
        [self mouseEntered:nil];
    }else
    {
        [self mouseExited:nil];
    }
    [self addTrackingArea:trackingArea];
}

/*
 self或者superView 隐藏或显示
 */
- (void)viewDidHide
{
    [super viewDidHide];
    [self mouseExited:nil];
}

- (void)viewDidUnhide
{
    [super viewDidUnhide];
    if ([NSEvent mouseInView:self])
    {
        [self mouseEntered:nil];
    }
}

/*
 self从superView或window添加或移除
 */
- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    if (self.window)
    {
        if ([NSEvent mouseInView:self])
        {
            [self mouseEntered:nil];
        }
    }
    else
    {
        [self mouseExited:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    if (!self.isEnabled)
        return;
    
    if (mouseEnter)
        return;
    
    mouseEnter = YES;
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)event
{
    if (!mouseEnter)
        return;
    
    mouseEnter = NO;
    [self setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled)
        return;
    
    mouseDown = YES;
    [self setNeedsDisplay];
    
    [super mouseDown:theEvent];
    
    if (![NSEvent mouseInView:self])
        mouseEnter = NO;
    
    [self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event
{
    if (!self.isEnabled)
        return;
    
    mouseDown = NO;
    [self setNeedsDisplay];
    
    [super mouseUp:event];
    
    if (![NSEvent mouseInView:self]) {
        mouseEnter = NO;
    }
    else
    {
        [self sendAction:self.action to:self.target];
    }
    
    [self setNeedsDisplay];
}

@end

#pragma mark - QMStateButton

@interface QMStateButton ()
{
    NSMutableDictionary *imageInfo;
    NSMutableDictionary *titleInfo;
}
@end

@implementation QMStateButton

- (void)setUp
{
    imageInfo = [[NSMutableDictionary alloc] initWithCapacity:12];
    titleInfo = [[NSMutableDictionary alloc] initWithCapacity:12];
}

- (void)setImage:(NSImage *)image forState:(QMStateType)st
{
    if (image)
        [imageInfo setObject:image forKey:@(st)];
    else
        [imageInfo removeObjectForKey:@(st)];
    
    [self setNeedsDisplay];
}

- (NSImage *)imageForState:(QMStateType)st
{
    return [imageInfo objectForKey:@(st)];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle forState:(QMStateType)st
{
    if (attributedTitle)
        [titleInfo setObject:attributedTitle forKey:@(st)];
    else
        [titleInfo removeObjectForKey:@(st)];
    
    [self setNeedsDisplay];
}

- (NSAttributedString *)attributedTitleForState:(QMStateType)st
{
    return [titleInfo objectForKey:@(st)];
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    
    QMStateType curst = [self buttonState];
    
    NSImage *showImage = [imageInfo objectForKey:@(curst)];
    if (!showImage)
        showImage = [imageInfo objectForKey:@(curst & (QMState_on|QMState_off|QMState_mixed))];
    if (!showImage)
        showImage = [imageInfo objectForKey:@(curst & (QMState_normal|QMState_hover|QMState_pressed|QMState_disable))];
    if (!showImage)
        showImage = [imageInfo objectForKey:@(QMState_on)];
    if (!showImage)
        showImage = [imageInfo objectForKey:@(QMState_normal)];
    
    NSAttributedString *showTitle = [titleInfo objectForKey:@(curst)];
    if (!showTitle)
        showTitle = [titleInfo objectForKey:@(curst & (QMState_on|QMState_off|QMState_mixed))];
    if (!showTitle)
        showTitle = [titleInfo objectForKey:@(curst & (QMState_normal|QMState_hover|QMState_pressed|QMState_disable))];
    if (!showTitle)
        showTitle = [titleInfo objectForKey:@(QMState_on)];
    if (!showTitle)
        showTitle = [titleInfo objectForKey:@(QMState_normal)];
    
    if (showImage)
    {
        [self setAlternateImage:showImage];
        [self setImage:showImage];
    }
    
    if (showTitle)
    {
        [self setAttributedAlternateTitle:showTitle];
        [self setAttributedTitle:showTitle];
    }
}

@end
