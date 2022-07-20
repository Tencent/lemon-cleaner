//
//  CalculatePictureFingerprint.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//
#import "CalculatePictureFingerprint.h"
#import <CoreImage/CoreImage.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>

#define ImgSize 50


typedef enum {
    PhotoType = 0,
    PhotoShopType = 1,
    ScreenCutType = 2,
    UnkownType = 3,
}ImageType;

@interface CalculatePictureFingerprint()

@end

@implementation CalculatePictureFingerprint

+ (NSMutableArray *)getdataArray:(NSString *)imgStr{
    NSMutableArray *resultArray = [[NSMutableArray alloc] initWithCapacity:ImgSize*ImgSize + 1];
    @autoreleasepool{
        int cursize =  ImgSize;
        int ArrSize = cursize * cursize,a[ArrSize+1],i,j,grey = 0;
        
        a[ArrSize] = 0;
        
        int avoidNumA = 0;
        NSData *dataPassA = [NSData dataWithContentsOfFile:imgStr];
        if (nil == dataPassA)
            return nil;
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[dataPassA mutableCopy], NULL);
        int type = [[self class ]getImageType:source];
        UInt32 *pixelsA = [[self class]getPixels:source];
        //if pixelsA is NULL, will make crash
        if (NULL == pixelsA)
            return nil;
        
        UInt32 * currentPixelA = pixelsA;
        
        int maxGrey = 0;
        int minGrey = 0;
        
        for (i = 0 ; i < cursize; i++) {
            for (j = 0; j < cursize; j++) {
                UInt32 currentColorValue = *(currentPixelA+ i*cursize + j) ;
                grey = ToGrey(currentColorValue);
                
                if(grey < minGrey){
                    minGrey = grey;
                } else if (grey > maxGrey){
                    maxGrey = grey;
                }
                
                a[cursize * i + j] = grey;
                a[ArrSize] += grey;
                if (grey > 0) {
                    avoidNumA ++;
                }
            }
        }
        if(avoidNumA <= 1){
            free(currentPixelA);
            return nil;
        }
        a[ArrSize] /= (avoidNumA - 1);
        
        for (i = 0 ; i < ArrSize ; i++){
            int lowPecent = (a[ArrSize] + minGrey)/2;
            int hightPecent = (a[ArrSize] + maxGrey)/2;
            int compareValue = 0;
            if (a[i] < lowPecent){
                compareValue = 1;
            } else if (a[i] < a[ArrSize] && a[i] > lowPecent) {
                compareValue = 2;
            } else if (a[i] > a[ArrSize] && a[i] < hightPecent){
                compareValue = 3;
            } else if (a[i] > hightPecent){
                compareValue = 4;
            }
            resultArray[i] = @(compareValue);
        }
        
        resultArray[ImgSize*ImgSize] = @(type);
        free(currentPixelA);
    }

    return resultArray;
}

+ (float) compareDataA:(NSMutableArray*)dataA andDataB:(NSMutableArray*)dataB{
    float sum = 0;
    int plusNum = 0;
    for (NSInteger i = 0 ; i < ImgSize*ImgSize ; i++)
    {
        if (dataA[i] == dataB[i]){
            if (i > 0 && (dataA[i] == dataA[i - 1])) {
                plusNum ++;
                sum += 1000.0/(1000.0 + plusNum);
            } else {
                plusNum = 0;
                sum += 1.0;
            }
        }
    }
    
    float ratio = sum * 1.0 / (ImgSize*ImgSize);
    if(dataA[ImgSize*ImgSize] == dataB[ImgSize*ImgSize]){
        if ([dataA[ImgSize*ImgSize] intValue] == 0){
            ratio += 0.13;
        }
    }
    return ratio;
}

unsigned int ToGrey(unsigned int rgb)
{
    unsigned int blue   = (rgb & 0x000000FF) >> 0;
    unsigned int green  = (rgb & 0x0000FF00) >> 8;
    unsigned int red    = (rgb & 0x00FF0000) >> 16;
    return ( red*38 +  green * 75 +  blue * 15 )>>7;
}

+ (UInt32 *)getPixels:(CGImageSourceRef)source {
    UInt32 * pixels = NULL;

    @autoreleasepool{
        CGImageRef inputCGImage =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        
        if(source == nil ||inputCGImage == nil){
            return 0;
        }
        
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * ImgSize;
        NSUInteger bitsPerComponent = 8;
        
        pixels = (UInt32 *) calloc(ImgSize * ImgSize, sizeof(UInt32));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef context = CGBitmapContextCreate(pixels, ImgSize, ImgSize, bitsPerComponent, bytesPerRow, colorSpace,kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, ImgSize, ImgSize), inputCGImage);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        CGImageRelease(inputCGImage);
        CFRelease(source);
        
    }
    return pixels;
}

+ (ImageType)getImageType:(CGImageSourceRef)source{
    int imagetype = 3;
    CFDictionaryRef imageInfo = CGImageSourceCopyPropertiesAtIndex(source, 0,NULL);
    if (!imageInfo) {
        return imagetype;
    }
    NSDictionary *exifDic = (__bridge NSDictionary *)CFDictionaryGetValue(imageInfo, kCGImagePropertyTIFFDictionary) ;
    CFRelease(imageInfo);
    if (exifDic == nil){
        return imagetype;
    }
    
//    NSLog(@"exifDic.allKeys:%@",exifDic.allKeys);

    if ([exifDic.allKeys containsObject:@"Make"]) {
        imagetype = 0;
    } else if ([exifDic.allKeys containsObject:@"Software"]&&[[exifDic objectForKey:@"Software"] containsString:@"Adobe"]){
        imagetype = 1;
    }
    
    return imagetype;
}

@end
