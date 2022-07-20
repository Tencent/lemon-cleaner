//
//  NSTextField+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextField(Color)

// 带有蓝色的
- (void)setBlueAttributedWithRange:(NSString *)str blueRange:(NSRange)range;

- (void)setAttributedWithColorRange:(NSString *)str colorRange:(NSRange)range color:(NSColor *)color;

+ (instancetype)labelWithStringCompat:(NSString *)stringValue;

@end
