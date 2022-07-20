//
//  CGImage+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "CGImage+Extension.h"

CGImageRef CGImageCreateWithFile(NSString *path)
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    if (!data)
        return NULL;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source)
        return NULL;
    
    size_t count = CGImageSourceGetCount(source);
    if (count < 1)
    {
        CFRelease(source);
        return NULL;
    }
    
    size_t idx = 0;
    CGFloat scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    //默认为0,所以从1开始匹配
    for (size_t i=1; i<count; i++)
    {
        CFDictionaryRef property = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
        CFNumberRef DPIRef = CFDictionaryGetValue(property, CFSTR("DPIHeight"));
        double dpi = 0;
        CFNumberGetValue(DPIRef, kCFNumberDoubleType, &dpi);
        CFRelease(property);
        if ((scaleFactor == 1.0 && dpi == 72.0) ||
            (scaleFactor == 2.0 && dpi == 144.0))
        {
            idx = i;
            break;
        }
    }
    
    //创建CGImageRef
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, idx, NULL);
    CFRelease(source);
    return imageRef;
}
