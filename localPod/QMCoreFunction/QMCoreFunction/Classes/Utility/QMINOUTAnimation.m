//
//  QMGetOutAnimation.m
//  Lemon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMINOUTAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import "NSTimer+Extension.h"

@implementation QMINOUTAnimation

enum
{
    QMINOUTDirectionUP,
    QMINOUTDirectionDown,
    QMINOUTDirectionRight,
    QMINOUTDirectionLeft,
};
typedef NSInteger QMINOUTDirection;

enum
{
    QMINOUTModeIn,
    QMINOUTModeOut
};
typedef NSInteger QMINOUTMode;

#define QMINOUT_MOVE_DISTANCE 100.0

+ (void)animation:(NSView *)view direction:(QMINOUTDirection)direction mode:(QMINOUTMode)mode completionBlock:(void(^)(void))block
{
    //[view lockFocus];
    NSBitmapImageRep* rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [rep setSize:view.bounds.size];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
    //[view unlockFocus];
    
    //创建一个用于展示动画的View来替换view
    CALayer *showLayer = [CALayer layer];
    showLayer.bounds = view.bounds;
    NSView *animationView = [[NSView alloc] initWithFrame:view.frame];
    [animationView setWantsLayer:YES];
    [animationView setLayer:showLayer];
    [[view superview] replaceSubview:view with:animationView];
    
    unsigned char *bitmapPlan = NULL;
    
    unsigned char *bitmapData = [rep bitmapData];        //色彩的数据
    [rep getBitmapDataPlanes:&bitmapPlan];
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
    
    NSInteger noColorLines = 0;
    
    NSInteger childStartRow = 0;
    unsigned char *childBitmap = NULL;
    
    NSMutableArray *childrenLayers = [NSMutableArray array];
    for (NSInteger row = 0; row<pixelsHigh; row++)
    {
        BOOL hasColor = NO;
        unsigned char *rowBitmapData = bitmapData + row*bytesPerRow;
        
        //逐个像素遍历,判定该行是否有色彩
        for (NSInteger pixIdx = 0; pixIdx < colorPerRow; pixIdx+=samplesPerPixel)
        {
            unsigned char *pixelR = rowBitmapData + pixIdx*samplesPerPixel;
            unsigned char *pixelG = rowBitmapData + pixIdx*samplesPerPixel + 1;
            unsigned char *pixelB = rowBitmapData + pixIdx*samplesPerPixel + 2;
            unsigned char *pixelA = rowBitmapData + pixIdx*samplesPerPixel + 3;
            if (*pixelR>0 || *pixelG>0 || *pixelB>0 || *pixelA>0)
            {
                hasColor = YES;
                break;
            }
        }
        
        if (hasColor)
        {
            noColorLines = 0;
            
            //如果当前行有色彩,则记录下数据的开端
            if (childBitmap == NULL)
            {
                childStartRow = row;
                childBitmap = rowBitmapData;
            }
        }else
        {
            noColorLines++;
        }
        
        //如果连续两行没有颜色或已经遍历到最后一行,则构造子图像
        if (childBitmap && (noColorLines>=2 || row+1==pixelsHigh))
        {
            if (row+1==pixelsHigh)
            {
                row++;
            }

            //创建子图像
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
            
            //创建子Layer
            float scale = pixelsHigh/NSHeight(view.bounds);
            NSRect childRect = NSMakeRect(0, round((pixelsHigh-row)/scale), NSWidth(view.bounds), round(childPixelHigh/scale));
            CALayer *childLayer = [CALayer layer];
            childLayer.contents = childImage;
            if (mode == QMINOUTModeIn)
            {
                childRect.origin.y -= QMINOUT_MOVE_DISTANCE;
                childLayer.opacity = 0.0;
            }
            childLayer.frame = childRect;
            [showLayer addSublayer:childLayer];
            [childrenLayers addObject:childLayer];
            
            childStartRow = 0;
            childBitmap = NULL;
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
    
    CFTimeInterval duration = 0.4;
    CFTimeInterval interval = 0.5/childrenLayers.count;
    //动画
    for (NSInteger idx=0; idx<childrenLayers.count; idx++)
    {
        CALayer *childLayer = [childrenLayers objectAtIndex:idx];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:idx*interval+0.01 repeats:NO handler:^{
            
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
            frame.origin.y += QMINOUT_MOVE_DISTANCE;
            childLayer.frame = frame;
            
            if (mode == QMINOUTModeIn)
            {
                childLayer.opacity = 1.0;
            }else
            {
                childLayer.opacity = 0.0;
            }
            [CATransaction commit];
            
        }];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    
    if (childrenLayers.count == 0)
    {
        animationCompletionBlock();
    }
}

+ (void)getOut:(NSView *)view completionBlock:(void(^)(void))block
{
    [self animation:view direction:QMINOUTDirectionUP mode:QMINOUTModeOut completionBlock:block];
}

+ (void)getIn:(NSView *)view completionBlock:(void(^)(void))block
{
    [self animation:view direction:QMINOUTDirectionUP mode:QMINOUTModeIn completionBlock:block];
}

@end
