//
//  NSImage+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Extension)

- (NSImage *)imageWithBlur:(CGFloat)blurRadius;

+ (NSImage *)imageNamed:(NSString *)imgName withClass:(Class)cls;

@end
