//
//  NSColor+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor(HEX)

+ (NSColor *)colorWithHex:(NSInteger)hexValue;
+ (NSColor *)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alpha;

@end

@interface NSColor(color)


+ (NSColor *)mgrButtonBlueColor;

// 标题文字
+ (NSColor *)mgrTitleColor;
// 正文文字
+ (NSColor *)mgrTextColor;
// 非重点文字
+ (NSColor *)mgrNotKeyTextColor;
// txtField显示蓝色
+ (NSColor *)mgrTxtBlueColor;

/*
 国际版标准颜色
 */
//高亮蓝色
+ (NSColor *)intlBlueColor;
//高亮绿色
+ (NSColor *)intlGreenColor;
//进度条底色
+ (NSColor *)intlGrayColor;
//文字标题
+ (NSColor *)intlTitleColor;
//文字辅色
+ (NSColor *)intlTextColor;

@end

@interface NSColor(CGColor)

// 返回autoreleaseCGColor对象
- (CGColorRef)convertToCGColor;

+ (id)createCGColorWithSRGB:(float)r green:(float)g blue:(float)b alpha:(float)alpha;

@end
