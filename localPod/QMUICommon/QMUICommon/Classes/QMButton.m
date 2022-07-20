//
//  QMStateButton.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMButton.h"

@interface QMButton ()
{
    NSInteger buttonState;
    NSMutableDictionary *imageInfo;
    BOOL mouseDown;
}
@end

@implementation QMButton
@synthesize handCursor;
@synthesize borderType;
@synthesize borderButtonColor;

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

- (void)setUp
{
    buttonState = [super state];
    imageInfo = [[NSMutableDictionary alloc] init];
    if (super.image)
    {
        [imageInfo setObject:super.image forKey:@(NSOffState)];
    }
    if (super.alternateImage)
    {
        [imageInfo setObject:super.alternateImage forKey:@(NSOnState)];
    }
    _pressState = YES;
    borderType = NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (borderType && borderButtonColor)
    {
        NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                              xRadius:2 yRadius:2];
        [path addClip];
        if (mouseDown)
            [[borderButtonColor shadowWithLevel:.5] set];
        else
            [borderButtonColor set];
        [path stroke];
        if (buttonState == QMMouseOver)
            [path fill];
        
    }
    if (self.layer)
        CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], YES);
    [super drawRect:dirtyRect];
}

- (void)setMouseExitColor:(NSColor *)mouseExitColor
{
    self.state = QMOffState;
    _mouseExitColor = mouseExitColor;
    NSMutableAttributedString * attributed = [[self attributedTitle] mutableCopy];
    [attributed addAttribute:NSForegroundColorAttributeName value:_mouseExitColor range:NSMakeRange(0, attributed.length)];
    [self setAttributedTitle:attributed];
}

#pragma mark -
#pragma mark 重写默认设置图片的方法

- (NSImage *)image
{
    return [super image];
}

- (void)setImage:(NSImage *)image
{
    [self setImage:image state:NSOffState];
    [super setImage:image];
}

- (NSImage *)alternateImage
{
    return [super alternateImage];
}

- (void)setAlternateImage:(NSImage *)image
{
    [self setImage:image state:NSOnState];
    [super setAlternateImage:image];
}

- (void)setImage:(NSImage *)image state:(QMButtonState)state
{
    if (image)
    {
        [imageInfo setObject:image forKey:@(state)];
    }
}

#pragma mark -
#pragma mark 重写状态方法

- (NSInteger)state
{
    return buttonState;
}

- (void)setState:(NSInteger)value
{
    if (value == NSMixedState ||
        value == NSOnState ||
        value == NSOffState)
    {
        [super setState:value];
    }
    buttonState = value;
    
    // 设置字体颜色
    if (value == QMMouseOver && _mouseEnterColor)
    {
        NSMutableAttributedString * attributed = [[self attributedTitle] mutableCopy];
        [attributed addAttribute:NSForegroundColorAttributeName value:_mouseEnterColor range:NSMakeRange(0, attributed.length)];
        [self setAttributedTitle:attributed];
    }
    else if (_mouseExitColor)
    {
        NSMutableAttributedString * attributed = [[self attributedTitle] mutableCopy];
        [attributed addAttribute:NSForegroundColorAttributeName value:_mouseExitColor range:NSMakeRange(0, attributed.length)];
        [self setAttributedTitle:attributed];
    }
    
    if (borderType && borderButtonColor)
    {
        [self setNeedsDisplay];
        return;
    }
    
    NSImage *buttonImage = [imageInfo objectForKey:@(buttonState)];
    
    //当无合适图片时,采用默认图片(off状态图片)
    if (!buttonImage)
    {
        buttonImage = [imageInfo objectForKey:@(NSOffState)];
    }
    if (buttonImage)
    {
        [super setImage:buttonImage];
        [super setAlternateImage:buttonImage];
    }
}

#pragma mark -
#pragma mark 手势相关

- (void)updateTrackingAreas
{
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    if (handCursor)
    {
        [[NSCursor pointingHandCursor] set];
    }
    [self setState:QMMouseOver];
}

- (void)mouseExited:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    if (handCursor)
    {
        [[NSCursor arrowCursor] set];
    }
    [self setState:[super state]];
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
    BOOL retValue = [super sendAction:theAction to:theTarget];
    if (NSEqualRects([self visibleRect], NSZeroRect))
        [self setState:QMOffState];
    else
        [self setState:[super state]];
    return retValue;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self setState:QMMouseDown];
    if (borderType && _pressState)
    {
        BOOL keepOn = YES;
        BOOL isInside = YES;
        NSPoint mouseLoc;
        
        mouseDown = YES;
        [self setNeedsDisplay];
        while (keepOn) {
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                        NSLeftMouseDraggedMask];
            mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            isInside = [self mouse:mouseLoc inRect:[self bounds]];
            
            if ([theEvent type] == NSLeftMouseUp || !isInside)
            {
                mouseDown = NO;
                keepOn = NO;
            }
            
        };
    }
    [super mouseDown:theEvent];
    [self setState:[super state]];
}


@end


@implementation QMBlueButton
@synthesize selected;

- (void)setUp
{
    [super setUp];
    [self refreshColor];
}

- (void)refreshColor
{
    if (selected)
    {
        NSColor *blueColor = [NSColor colorWithSRGBRed:16.0 / 255 green:140.0/255 blue:1 alpha:1];
        [self setBorderType:YES];
        [self setBorderButtonColor:[NSColor whiteColor]];
        [self setMouseEnterColor:blueColor];
        [self setMouseExitColor:[NSColor whiteColor]];
    }else
    {
        NSColor *blueColor = [NSColor colorWithSRGBRed:16.0 / 255 green:140.0/255 blue:1 alpha:1];
        [self setBorderType:YES];
        [self setBorderButtonColor:blueColor];
        [self setMouseEnterColor:[NSColor whiteColor]];
        [self setMouseExitColor:blueColor];
    }
}

- (BOOL)selected
{
    return selected;
}

- (void)setSelected:(BOOL)value
{
    selected = value;
    [self refreshColor];
    [self setNeedsDisplay];
}

@end
