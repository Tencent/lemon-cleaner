//
//  NSFont+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSFont+Extension.h"

@implementation NSFont (Extension)

+ (NSFont *)safeFontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    NSFont *font = nil;
    if (fontName)
    {
        font = [self fontWithName:fontName size:fontSize];
    }
    
    if (!font)
    {
        return [self systemFontOfSize:fontSize];
    }
    return font;
}


+ (NSFont *)safeMultiFontWithNames:(CGFloat)fontSize name:(NSString *)fontNames, ...
{
    if (!fontNames)
        return nil;
    NSFont * font = [self fontWithName:fontNames size:fontSize];
    if (font)
        return font;
    va_list arglist;
    va_start(arglist, fontNames);
    id arg;
    while((arg = va_arg(arglist, id))) {
        if (arg)
        {
            font = [self fontWithName:arg size:fontSize];
            if (font)
                break;
        }
    }
    va_end(arglist);
    if (!font) font = [self systemFontOfSize:fontSize];
    return font;
}

//国际版的标准字体
+ (NSFont *)intlFontWithSize:(CGFloat)fontSize
{
    return [NSFont safeFontWithName:@"Helvetica Neue Thin" size:fontSize];
}

@end
