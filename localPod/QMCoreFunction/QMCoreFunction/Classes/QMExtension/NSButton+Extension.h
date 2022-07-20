//
//  NSButton+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSButton(Color)

- (void)setTitle:(NSString *)aString withColor:(NSColor *)color;
- (void)setAttributedTitle:(NSString *)aString withColor:(NSColor *)color;

// 设置NSButton字体颜色
- (void)setFontColor:(NSColor *)color;

- (void)setFontColor:(NSColor *)color range:(NSRange)range;

@end
