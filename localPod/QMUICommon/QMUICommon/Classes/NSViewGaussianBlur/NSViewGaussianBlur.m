//
//  NSViewGaussianBlur.m
//  QMUICommon
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "NSViewGaussianBlur.h"
#import <CoreImage/CoreImage.h>

@implementation NSViewGaussianBlur

+ (NSImage *)blur:(NSView*)view frame:(CGRect) frame{
    NSImage *imageCopy = [[NSImage alloc]initWithData:[view dataWithPDFInsideRect:[view bounds]]];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:[[self class] nsImageToCGImageRef:imageCopy]];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:8] forKey:@"inputRadius"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:CGRectMake(0, 0, imageCopy.size.width,imageCopy.size.height)];
    NSImage *image = [[self class]imageFromCGImageRef:cgImage frame:frame];
    
    CGImageRelease(cgImage);
    return image;
}

+ (CGImageRef)nsImageToCGImageRef:(NSImage*)image{
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef = NULL;
    if(imageData){
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

+ (NSImage*) imageFromCGImageRef:(CGImageRef)image  frame:(CGRect) frame{
    NSRect imageRect = NSMakeRect(0.0, 0.0, frame.size.width, frame.size.height);
    CGContextRef imageContext = nil;
    NSImage* newImage = nil;
    
//    imageRect.size.height = CGImageGetHeight(image);
//    imageRect.size.width = CGImageGetWidth(image);
    
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    [newImage lockFocus];
    
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image);
    [newImage unlockFocus];
    
    return newImage;
}

@end
