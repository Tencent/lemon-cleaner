//
//  NSTextField+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSTextField+Extension.h"
#import "NSColor+Extension.h"

@implementation NSTextField(Color)


- (void)setBlueAttributedWithRange:(NSString *)str blueRange:(NSRange)range
{
    [self setStringValue:str];
    NSMutableAttributedString * retAttributed = [[self attributedStringValue] mutableCopy];
    [retAttributed addAttribute:NSForegroundColorAttributeName value:[NSColor mgrTxtBlueColor] range:range];
    [self setAttributedStringValue:retAttributed];
}

- (void)setAttributedWithColorRange:(NSString *)str colorRange:(NSRange)range color:(NSColor *)color
{
    [self setStringValue:str];
    NSMutableAttributedString * retAttributed = [[self attributedStringValue] mutableCopy];
    [retAttributed addAttribute:NSForegroundColorAttributeName value:color range:range];
    [self setAttributedStringValue:retAttributed];
}


+ (instancetype)labelWithStringCompat:(NSString *)stringValue { 
    NSTextField* me = [[NSTextField alloc] init];
    [me setEditable:NO];
    me.drawsBackground = NO;
    me.bordered = NO;
    me.stringValue = stringValue;
    return me;
}

@end
