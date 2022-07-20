//
//  NSFont+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFont (Extension)

+ (NSFont *)safeFontWithName:(NSString *)fontName size:(CGFloat)fontSize;

+ (NSFont *)safeMultiFontWithNames:(CGFloat)fontSize name:(NSString *)fontNames, ...;

//国际版的标准字体
+ (NSFont *)intlFontWithSize:(CGFloat)fontSize;

@end
