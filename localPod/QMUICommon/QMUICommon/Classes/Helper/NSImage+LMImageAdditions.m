//
//  NSImage+ImageAdditions.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "NSImage+LMImageAdditions.h"

@implementation NSImage (LMImageAdditions)

+(NSImage *)swatchWithColor:(NSColor *)color size:(NSSize)size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}

@end
