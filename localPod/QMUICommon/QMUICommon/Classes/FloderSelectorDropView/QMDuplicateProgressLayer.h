//
//  QMDuplicateProgressLayer.h
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface QMDuplicateProgressLayer : CALayer
{
    int _lastNumber;
    CALayer * _imageLayer;
    CALayer * _loadingLayer;
    CALayer * _backLayer;
    CGFloat _value;
}
- (id)initWithFrame:(NSRect)rect;

- (void)setProgressImagePostion:(CGPoint)point;
- (CGPoint)progressImagePostion;

- (void)startLoadingAnimation;
- (void)stopLoadingAnimation;

- (void)showProgressValue:(CGFloat)value;

@end
