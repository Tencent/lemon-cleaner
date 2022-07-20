//
//  NSView+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (ScreenShot)

- (NSImage *)screenShot;

- (instancetype)insertVibrancyViewBlendingMode:(NSVisualEffectBlendingMode)mode;

@end
