//
//  NSButton+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSButton+Extension.h"

@implementation NSButton(Color)

- (void)setTitle:(NSString *)aString withColor:(NSColor *)color
{
    [self setTitle:aString];
    [self setFontColor:color];
}
- (void)setAttributedTitle:(NSAttributedString *)aString withColor:(NSColor *)color
{
    [self setAttributedTitle:aString];
    [self setFontColor:color];
}

- (void)setFontColor:(NSColor *)color
{
    NSMutableAttributedString * attributed = [[self attributedTitle] mutableCopy];
    [attributed addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributed.length)];
    [self setAttributedTitle:attributed];
}

- (void)setFontColor:(NSColor *)color range:(NSRange)range
{
    NSMutableAttributedString * attributed = [[self attributedTitle] mutableCopy];
    [attributed addAttribute:NSForegroundColorAttributeName value:color range:range];
    [self setAttributedTitle:attributed];
}

@end
