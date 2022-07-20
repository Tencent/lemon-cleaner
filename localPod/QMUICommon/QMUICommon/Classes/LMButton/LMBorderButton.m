//
//  LMBorderButton.m
//  QMUICommon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMBorderButton.h"
#import "NSFontHelper.h"
#import "LMAppThemeHelper.h"

@implementation LMBorderButton
{
    NSTrackingArea *trackingArea;
    BOOL mouseEnter;
    BOOL mouseDown;
}
// 非 xib 方式
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDefault];
    }
    return self;
}
// xib 方式.
- (void)awakeFromNib
{
    [self setDefault];
}

- (void)setDefault{

    [self setFocusRingType:NSFocusRingTypeNone];
    
    [self setBezelStyle:NSTexturedSquareBezelStyle];
    [self setButtonType:NSButtonTypeMomentaryPushIn];
    self.bordered = NO;
    
    _radius = 2;
    _borderWidth = 1;
    _fontSize = 12;
    _isFontLight = YES;
    
    _titleNormalColor = [NSColor colorWithHex:0x94979b];
    _titleHoverColor = [NSColor colorWithHex:0xafafaf];
    _titleDownColor = [NSColor colorWithHex:0x7e7e7e];
    _titleDisableColor = [NSColor colorWithHex:0x94979b];
    
//    _borderNormalColor = [NSColor colorWithHex:0xe5e5e5];
//    _borderHoverColor = [NSColor colorWithHex:0xf3f3f3];
//    _borderDownColor = [NSColor colorWithHex:0xd4d4d4];
//    _borderDisableColor = [NSColor colorWithHex:0xe5e5e5];
    _borderNormalColor = [LMAppThemeHelper getSmallBtnBorderColor];
    _borderHoverColor = [LMAppThemeHelper getSmallBtnBorderColor];
    _borderDownColor = [LMAppThemeHelper getSmallBtnBorderColor];
    _borderDisableColor = [LMAppThemeHelper getSmallBtnBorderColor];
}

- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
    
    NSColor *strokeColor = self.borderNormalColor;
    NSColor *textColor = self.titleNormalColor;
    if (self.enabled) {
        if(mouseDown) {
            if(self.borderDownColor)
                strokeColor = self.borderDownColor;
            if(self.titleDownColor)
                textColor = self.titleDownColor;
        }
        else if (mouseEnter) {
            if(self.borderHoverColor)
                strokeColor = self.borderHoverColor;
            if(self.titleHoverColor)
                textColor = self.titleHoverColor;
        }
    } else {
        if(self.borderDisableColor)
            strokeColor = self.borderDisableColor;
        if(self.titleDisableColor)
            textColor = self.titleDisableColor;
    }
    
    [self.layer setBorderColor:strokeColor.CGColor];
    [self.layer setBorderWidth:self.borderWidth];
    [self.layer setCornerRadius:self.radius];
    self.layer.masksToBounds = YES;
    
    if(self.isFontLight) {
        [self setFont:[NSFontHelper getLightSystemFont:self.fontSize]];
    } else {
        [self setFont:[NSFontHelper getRegularSystemFont:self.fontSize]];
    }
    NSDictionary *tdic = @{NSFontAttributeName:self.font,
                           NSForegroundColorAttributeName: textColor};
    NSRect tr = [self.title boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin attributes:tdic];
    [self.title drawAtPoint:NSMakePoint((self.bounds.size.width-tr.size.width)/2.0, (self.bounds.size.height-tr.size.height)/2.0) withAttributes:tdic];
}

- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    [self setNeedsDisplay];
}

- (BOOL)isMouseEnter
{
    return mouseEnter && [NSEvent mouseInView:self];
}

- (void)updateTrackingAreas
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

- (void)mouseEntered:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = YES;
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = NO;
    [self setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = YES;
    [self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event {
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = NO;
    [self setNeedsDisplay];
    
    if ([NSEvent mouseInView:self])
    {
        [self sendAction:self.action to:self.target];
    }
}

//修复view controller切换时没有mouseExited事件
- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if ([NSEvent mouseInView:self])
    {
        [self mouseEntered:nil];
    } else {
        [self mouseExited:nil];
    }
}

//修复view hide时没有mouseExited事件
- (void)viewDidUnhide
{
    [super viewDidUnhide];
    if ([NSEvent mouseInView:self])
    {
        [self mouseEntered:nil];
    } else {
        [self mouseExited:nil];
    }
}

@end
