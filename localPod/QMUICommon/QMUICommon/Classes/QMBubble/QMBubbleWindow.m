//
//  QMBubbleWindow.m
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMBubbleWindow.h"

@implementation QMBubbleWindow

- (id)initWithContentRect:(NSRect)contentRect
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    if (self)
    {
        [self setOpaque:NO];
        [self setHasShadow:YES];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setAllowsToolTipsWhenApplicationIsInactive:YES];
        [self setLevel:NSPopUpMenuWindowLevel];
    }
    return self;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    return [self initWithContentRect:contentRect];
}

//- (void)sendEvent:(NSEvent *)theEvent
//{
//    if ([theEvent buttonNumber] == 0 && self.canBecomeKeyWindow) {
//        [self becomeKeyWindow];
//    }
//    [super sendEvent:theEvent];
//}

- (BOOL)canBecomeKeyWindow
{
    return self.keyWindowMode;
}

@end
