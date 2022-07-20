//
//  NSEvent+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (MouseLocation)

+ (NSPoint)mouseLocationInView:(NSView *)aView;
+ (BOOL)mouseInView:(NSView *)aView;

@end
