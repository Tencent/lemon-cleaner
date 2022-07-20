//
//  QMSheetWindow.h
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QMColorBackgroundView;
@interface QMTransparentWindow : NSWindow
{
    QMColorBackgroundView * m_backgroundView;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
                backColor:(NSColor *)color;

- (void)setBackViewColor:(NSColor *)color;
- (NSColor *)backViewColor;

@end
