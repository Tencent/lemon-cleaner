//
//  NSImage+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSImage+Extension.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSImage (Extension)

- (NSImage *)imageWithBlur:(CGFloat)blurRadius
{
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[self TIFFRepresentation], NULL);
    if (!source)
        return NULL;
    size_t count = CGImageSourceGetCount(source);
    
    NSImage *resultImage = [[NSImage alloc] initWithSize:self.size];
    for (size_t idx=0; idx<count; idx++)
    {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, idx, NULL);
        NSSize size = NSMakeSize(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
        
        CIImage *inputImage = [CIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        
        CGFloat scale = size.width/self.size.width;
        [blurFilter setValue:@(blurRadius * scale) forKeyPath:@"inputRadius"];
        [blurFilter setValue:inputImage forKey: @"inputImage"];
        CIImage *outputImage = [blurFilter valueForKey:@"outputImage"];
        
        /*因为模糊之后图像会向四周扩散变大,所以此处裁剪中间原大小的部分即可*/
        CIImage *cropImage = [outputImage imageByCroppingToRect:CGRectMake(0, 0, size.width, size.height)];
        NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:cropImage];
        
        [resultImage addRepresentation:rep];
    }
    CFRelease(source);
    
    return resultImage;
}

+ (NSImage *)imageNamed:(NSString *)imgName withClass:(Class)cls{
    NSBundle *bundle = [NSBundle bundleForClass:cls];
    return [bundle imageForResource:imgName];
}

@end
