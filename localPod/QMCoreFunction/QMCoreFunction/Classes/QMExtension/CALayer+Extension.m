//
//  CALayer+Extension.m
//  QMCoreFunction
//
//
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "CALayer+Extension.h"

@implementation CALayer(ScreenShot)

- (CGImageRef)createCGImage
{
    float scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    
    size_t pixelsWidth = (size_t)self.bounds.size.width;
    size_t pixelsHeight = (size_t)self.bounds.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    if (!colorSpace)
        return nil;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 pixelsWidth*scaleFactor,
                                                 pixelsHeight*scaleFactor,
                                                 8,
                                                 pixelsWidth*4*scaleFactor,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
    CGContextScaleCTM(context, scaleFactor, scaleFactor);
    CGColorSpaceRelease(colorSpace);
    
    if (context== NULL)
        return nil;
    
    [[self presentationLayer] renderInContext:context];
    //[self renderInContext:context];
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return imgRef;
}

- (NSImage *)screenShot
{
    CGImageRef imgRef = [self createCGImage];
    NSImage *img = [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(NSWidth(self.bounds), NSHeight(self.bounds))];
    CGImageRelease(imgRef);
    return img;
}

@end
