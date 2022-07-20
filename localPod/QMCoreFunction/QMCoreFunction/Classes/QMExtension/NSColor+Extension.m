//
//  NSColor+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSColor+Extension.h"

@implementation NSColor(HEX)

+ (NSColor *)colorWithHex:(NSInteger)hexValue
{
    return [self colorWithHex:hexValue alpha:1.0];
}

+ (NSColor *)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alpha
{
    return [NSColor colorWithSRGBRed:((hexValue&0xFF0000)>>16)/255.0 green:((hexValue&0xFF00)>>8)/255.0 blue:(hexValue&0xFF)/255.0 alpha:alpha];
}

@end

@implementation NSColor(color)



+ (NSColor *)mgrButtonBlueColor
{
    return [NSColor colorWithSRGBRed:0 green:103.0/255 blue:192.0/255 alpha:1];
}


// 标题文字
+ (NSColor *)mgrTitleColor
{
    return [NSColor whiteColor];
}
// 正文文字
+ (NSColor *)mgrTextColor
{
    return [NSColor colorWithHex:0x9ba0a9];
}
// 非重点文字
+ (NSColor *)mgrNotKeyTextColor
{
    return [NSColor colorWithHex:0x686a6d];
}
// txtField显示蓝色
+ (NSColor *)mgrTxtBlueColor
{
    return [NSColor colorWithHex:0x0787ff];
}

+ (NSColor *)intlBlueColor
{
    return [NSColor colorWithHex:0x0091ff];
}

+ (NSColor *)intlGreenColor
{
    return [NSColor colorWithHex:0x7bcf8c];
}

+ (NSColor *)intlGrayColor
{
    return [NSColor colorWithHex:0xe6ecf1];
}

+ (NSColor *)intlTitleColor
{
    return [NSColor colorWithHex:0x616c72];
}

+ (NSColor *)intlTextColor
{
    return [NSColor colorWithHex:0xa5b0b5];
}

@end

@implementation NSColor(CGColor)

- (CGColorRef)convertToCGColor
{
    if ([self respondsToSelector:@selector(CGColor)])
        return [self CGColor];
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    
    [self getComponents:(CGFloat *)&components];
    CGColorSpaceRef colorSpace = [self.colorSpace CGColorSpace];
    CGColorRef colorRef = CGColorCreate (colorSpace, components);
    return (__bridge CGColorRef)([(__bridge id)colorRef performSelector:NSSelectorFromString(@"autorelease")]);
}

+ (id)createCGColorWithSRGB:(float)r green:(float)g blue:(float)b alpha:(float)alpha
{
    CGColorSpaceRef spaceRef = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGColorRef colorRef = CGColorCreate(spaceRef,  (CGFloat[]){r/255.0, g/255.0, b/255.0, alpha});
    CGColorSpaceRelease(spaceRef);
    return (__bridge_transfer id)colorRef;
}

@end
