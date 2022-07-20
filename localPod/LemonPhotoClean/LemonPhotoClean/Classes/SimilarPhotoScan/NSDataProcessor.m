//
//  NSImage+Processor.m
//  FirmToolsDuplicatePhotoFinder
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//

#import "NSDataProcessor.h"

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

#define SamplingNumbersPerDimensionality 256

@implementation NSDataProcessor

+ (NSDictionary *)abstractVector:(NSData*)data {
    if (nil == data)
        return [[NSDictionary alloc] init];
    
    NSDictionary *bucket = [[NSDictionary alloc]init];

    @autoreleasepool{
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[data mutableCopy], NULL);
        CGImageRef inputCGImage =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        NSUInteger width = CGImageGetWidth(inputCGImage);
        NSUInteger height = CGImageGetHeight(inputCGImage);
        
        if(width == 0 ||height == 0){
            return bucket;
        }
        
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        
        UInt32 * pixels;
        pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        CGImageRelease(inputCGImage);
        CFRelease(source);
        
        NSMutableDictionary<NSNumber *,NSNumber *> *pixelBucket = [[NSMutableDictionary alloc]init];
        
        UInt32 * currentPixel = pixels;
        NSUInteger perStep = SamplingNumbersPerDimensionality;
        NSUInteger widthStep = width/perStep < 1?1:width/perStep;
        NSUInteger heightStep = height/perStep < 1?1:height/perStep;
        
        for (NSUInteger j = 0; j < height; j+=heightStep) {
            for (NSUInteger i = 0; i < width; i+=widthStep) {
                @autoreleasepool{
                    UInt32 color = *(currentPixel + j*width + i) ;
                    UInt32 fingerprint = [[self class] fingerprintOfColor:color]*10 + [[self class] areaOfX:i y:j width:width height:height];
                    pixelBucket[@(fingerprint)] = @(pixelBucket[@(fingerprint)].intValue + 1);
                }
            }
        }
        free(pixels);

        [pixelBucket enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            @autoreleasepool{
                pixelBucket[key] = @(obj.doubleValue/(height * width));
            }
        }];
        @autoreleasepool{
            bucket = @{KEY_ASPECT_RATIO:@((float)width/height),KEY_PIXELVECTOR:[pixelBucket mutableCopy]};
            pixelBucket = nil;
            
        }
        [pixelBucket removeAllObjects];
    }
    
    return bucket;
}

+ (UInt32)fingerprintOfColor:(UInt32)color{
    UInt32 redColor = [[self class]areaOfComponent:R(color)]*1000;
    UInt32 greenColor = [[self class] areaOfComponent:G(color)]*100;
    UInt32 blueColor = [[self class] areaOfComponent:B(color)]*10;
    UInt32 aphleColor = [[self class] areaOfComponent:A(color)];

    return redColor + greenColor + blueColor + aphleColor;
}

+ (UInt32)areaOfComponent:(UInt32)component{
    return component/8;
}

+ (UInt32)areaOfX:(NSUInteger)x y:(NSUInteger)y width:(NSUInteger)width height:(NSUInteger)height{
    UInt32 result = 0;
    
    if (x<=width/3) {
        result+=0;
    } else if (x<=2*width/3) {
        result+=3;
    } else {
        result+=6;
    }
    
    if (y<=height/3) {
        result+=1;
    } else if (y<=2*height/3) {
        result+=2;
    } else {
        result+=3;
    }
    
    return result;
}

@end
