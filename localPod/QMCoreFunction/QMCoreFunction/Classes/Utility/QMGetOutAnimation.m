//
//  QMGetOutAnimation.m
//  QQMacMgr
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMGetOutAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import "NSTimer+Extension.h"

@implementation QMGetOutAnimation

+ (void)getOut:(NSView *)view completionBlock:(void(^)(void))block
{
    [view lockFocus];
    NSBitmapImageRep* rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [rep setSize:view.bounds.size];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
    [view unlockFocus];
    
    //创建一个用于展示动画的View来替换view
    CALayer *showLayer = [CALayer layer];
    showLayer.bounds = view.bounds;
    NSView *animationView = [[NSView alloc] initWithFrame:view.frame];
    [animationView setWantsLayer:YES];
    [animationView setLayer:showLayer];
    [[view superview] replaceSubview:view with:animationView];
    
    unsigned char *bitmapData = [rep bitmapData];        //色彩的数据
    NSInteger samplesPerPixel = [rep samplesPerPixel];   //色彩通道数,RGBA为4
    NSInteger bitsPerPixel = [rep bitsPerPixel];         //色彩位数,RGBA为32
    NSInteger bytesPerRow = [rep bytesPerRow];           //每一行的数据
    NSInteger pixelsWide = [rep pixelsWide];             //像素宽
    NSInteger pixelsHigh = [rep pixelsHigh];             //像素高
    BOOL hasAlpha = [rep hasAlpha];                      //是否有透明度
    BOOL isPlanar = [rep isPlanar];                      //是否是平面结构
    NSString *colorSpaceName = [rep colorSpaceName];     //色彩空间名称
    NSBitmapFormat bitmapFormat = [rep bitmapFormat];    //格式
    NSInteger colorPerRow = bytesPerRow/samplesPerPixel; //一行的色彩数
    
    NSInteger childStartRow = 0;
    unsigned char *childBitmap = NULL;
    
    NSMutableArray *childrenLayers = [NSMutableArray array];
    for (NSInteger row = 0; row<pixelsHigh; row++)
    {
        unsigned char *currentBitmapData = bitmapData + row*bytesPerRow;
        
        //逐个像素遍历,判定该行是否有色彩
        BOOL hasColor = NO;
        for (NSInteger pixIdx = 0; pixIdx < colorPerRow; pixIdx+=samplesPerPixel)
        {
            unsigned char *pixelR = currentBitmapData + pixIdx*samplesPerPixel;
            unsigned char *pixelG = currentBitmapData + pixIdx*samplesPerPixel + 1;
            unsigned char *pixelB = currentBitmapData + pixIdx*samplesPerPixel + 2;
            unsigned char *pixelA = currentBitmapData + pixIdx*samplesPerPixel + 3;
            if (*pixelR>0 || *pixelG>0 || *pixelB>0 || *pixelA>0)
            {
                hasColor = YES;
                break;
            }
        }
        
        if (hasColor)
        {
            //如果当前行有色彩,则记录下数据的开端
            if (childBitmap == NULL)
            {
                childStartRow = row;
                childBitmap = currentBitmapData;
            }
        }else
        {
            //如果当前行没有色彩,而之前有色彩表示子图像已经找到
            if (childBitmap)
            {
                
                NSInteger childPixelHigh = row-childStartRow;
                NSBitmapImageRep *childRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&childBitmap
                                                                                     pixelsWide:pixelsWide
                                                                                     pixelsHigh:childPixelHigh
                                                                                  bitsPerSample:8
                                                                                samplesPerPixel:samplesPerPixel
                                                                                       hasAlpha:hasAlpha
                                                                                       isPlanar:isPlanar
                                                                                 colorSpaceName:colorSpaceName
                                                                                   bitmapFormat:bitmapFormat
                                                                                    bytesPerRow:bytesPerRow
                                                                                   bitsPerPixel:bitsPerPixel];
                
                NSData *imageData = [childRep representationUsingType:NSPNGFileType properties:@{NSImageCompressionFactor: @(1.0)}];
                NSImage *childImage = [[NSImage alloc] initWithData:imageData];
                
                float scale = pixelsHigh/NSHeight(view.bounds);
                NSRect childRect = NSMakeRect(0, round((pixelsHigh-row)/scale), NSWidth(view.bounds), round(childPixelHigh/scale));
                CALayer *childLayer = [CALayer layer];
                childLayer.frame = childRect;
                childLayer.contents = [childImage copy];
                [showLayer addSublayer:childLayer];
                [childrenLayers addObject:childLayer];
                
                childStartRow = 0;
                childBitmap = NULL;
            }
        }
    }
    
    //收拾残局
    void(^animationCompletionBlock)(void) = ^{
        
        [[animationView superview] replaceSubview:animationView with:view];
        if (block)
        {
            block();
        }
    };
    
    CFTimeInterval duration = 0.5;
    CFTimeInterval interval = 0.8/childrenLayers.count;
    //动画
    for (NSInteger idx=0; idx<childrenLayers.count; idx++)
    {
        CALayer *childLayer = [childrenLayers objectAtIndex:idx];
        
        [NSTimer scheduledTimerWithTimeInterval:idx*interval repeats:NO handler:^{
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:duration];
            [CATransaction setCompletionBlock:^{
                [childrenLayers removeObject:childLayer];
                if (childrenLayers.count == 0)
                {
                    animationCompletionBlock();
                }
            }];
            NSRect frame = childLayer.frame;
            frame.origin.y += 100;
            childLayer.frame = frame;
            childLayer.opacity = 0;
            [CATransaction commit];
            
        }];
    }
    
    if (childrenLayers.count == 0)
    {
        animationCompletionBlock();
    }
}

@end
