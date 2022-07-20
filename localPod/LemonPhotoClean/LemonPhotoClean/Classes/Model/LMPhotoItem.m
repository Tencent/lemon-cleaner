//
//  LMPhotoItem.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoItem.h"
#import <QMCoreFunction/NSImage+Extension.h>

@implementation LMPhotoItem
static NSOperationQueue* loadingOperationQueue = nil;

+ (NSOperationQueue *)previewLoadingOperationQueue {
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        loadingOperationQueue = [[NSOperationQueue alloc] init];
        loadingOperationQueue.maxConcurrentOperationCount = 1;
        loadingOperationQueue.name = @"Preview Loading Queue";
    }) ;
    
   
    return loadingOperationQueue;
}

+ (void)cancelAllPreviewLoadingOperationQueue{
    if(loadingOperationQueue != nil){
        [loadingOperationQueue cancelAllOperations];
    }
}

- (NSURL *)createUrl {
    if (url == NULL) {
        NSString *filePath = [@"file://" stringByAppendingString:self.path];
        filePath = [filePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        url = [NSURL URLWithString:filePath];
    }
    return url;
}

- (CGImageSourceRef)createImageSource {
    
    CGImageSourceRef imageSource = NULL;
    if (imageSource == NULL) {
        NSURL *sourceURL = [url absoluteURL];
        if (sourceURL == nil) {
            return NULL;
        }
        
        imageSource = CGImageSourceCreateWithURL((CFURLRef)sourceURL, NULL);
        if (imageSource == NULL) {
            return NULL;
        }
        
        CFStringRef imageSourceType = CGImageSourceGetType(imageSource);
        if (imageSourceType == NULL) {
            CFRelease(imageSource);
            return NULL;
        }
        CFRelease(imageSourceType);
    }
    return imageSource;
}

- (void)requestPreviewImage {
    __weak typeof(self) weakSelf = self;
    @autoreleasepool {
        if (self.previewImage == nil) {
            [[[self class] previewLoadingOperationQueue] addOperationWithBlock:^{
                
                [weakSelf createUrl];
                CGImageSourceRef imageSource = [weakSelf createImageSource];
                if (imageSource != NULL) {
                    @autoreleasepool {
                        NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                 [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailWithTransform,
                                                 [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailFromImageAlways,
                                                 [NSNumber numberWithInt:160], (NSString *)kCGImageSourceThumbnailMaxPixelSize,
                                                 nil];
                        
                        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
                        
                        if (thumbnail) {
                            NSSize size = NSMakeSize(160, 160);
                            
                            @autoreleasepool {

                                NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail size:size];
                                if (image) {
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        weakSelf.previewImage = image;
                                    }];
                                }
                            
                            }
                            CGImageRelease(thumbnail);
                        }
                    }
                    
                } else {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        weakSelf.previewImage = [NSImage imageNamed:@"smallDeletedTag" withClass:[self class]];
                    }];
                }
            }];
        }
    }
    
}

- (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size{
    
//    return sourceImage;
    
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSImage*  targetImage = [[NSImage alloc] initWithSize:size];
    NSSize sourceSize = [sourceImage size];

    float ratioH = size.height/ sourceSize.height;
    float ratioW = size.width / sourceSize.width;

    NSRect cropRect = NSZeroRect;
    if (ratioH >= ratioW) {
        cropRect.size.width = floor (size.width / ratioH);
        cropRect.size.height = sourceSize.height;
    } else {
        cropRect.size.width = sourceSize.width;
        cropRect.size.height = floor(size.height / ratioW);
    }

    cropRect.origin.x = floor( (sourceSize.width - cropRect.size.width)/2 );
    cropRect.origin.y = floor( (sourceSize.height - cropRect.size.height)/2 );

    [targetImage lockFocus];
    [sourceImage drawInRect:targetFrame
                   fromRect:cropRect
                  operation:NSCompositeCopy
                   fraction:1.0
             respectFlipped:YES
                      hints:@{NSImageHintInterpolation:
                                  [NSNumber numberWithInt:NSImageInterpolationLow]}];
    [targetImage unlockFocus];

    return targetImage;
}
- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    LMPhotoItem *item = [[[self class] allocWithZone:zone] init];
    
    item.path = self.path;
    item.isSelected = self.isSelected;
    item.isDeleted = self.isDeleted;
    item.isPrefer = self.isPrefer;
    item.previewImage = self.previewImage;
    item.imageSize = self.imageSize;

    return item;
}

@end
