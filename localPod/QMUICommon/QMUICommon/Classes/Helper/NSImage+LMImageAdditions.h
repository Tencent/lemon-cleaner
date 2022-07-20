//
//  NSImage+ImageAdditions.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (LMImageAdditions)

+(NSImage *)swatchWithColor:(NSColor *)color size:(NSSize)size;

@end
