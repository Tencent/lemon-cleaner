//
//  QMSheetWindow.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMTransparentWindow.h"
#import "QMColorBackgroundView.h"

@implementation QMTransparentWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:NO];
    if (self != nil) {
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:1.0];
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
    }
    return self;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
                backColor:(NSColor *)color
{
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [self initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self != nil) {
        [self initViews];
        [self setBackViewColor:color];
    }
    return self;
}

- (void)initViews
{
    NSRect contentRect = [[self contentView] frame];
    if (![[self contentView] isKindOfClass:[QMColorBackgroundView class]])
    {
        m_backgroundView = [[QMColorBackgroundView alloc] initWithFrame:contentRect];
        [self setContentView:m_backgroundView];
    }
    else
    {
        m_backgroundView = [self contentView];
    }
}

- (void)awakeFromNib
{
    [self initViews];
}


- (void)setBackViewColor:(NSColor *)color
{
    [m_backgroundView setBackColor:color];
}


- (NSColor *)backViewColor
{
    return m_backgroundView.backColor;
}

@end
