//
//  QMDuplicateCoverLayer.h
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface QMDuplicateCoverLayer : CALayer
{
    CATextLayer * _descTextLayer;
@public CALayer * _smallAddContainerLayer;
    
    CALayer * _backLayer;
    CALayer * _flagsLayer;
    CAShapeLayer * _line1ShapeLayer;
    CAShapeLayer * _line2ShapeLayer;
    
    CALayer * _contentLayer;
    
    CATextLayer *_addTextLayer;
    CALayer * _addIconLayer;

}
- (id)initWithFrame:(NSRect)rect addTips:(NSString *)tips;

- (void)showNormalState:(BOOL)animation;
- (void)showCompleteState:(BOOL)animation;

- (void)resetAnimation;
- (void)showAnimationState1;
- (void)showAnimationState2;

- (void)showRemoveFile:(NSArray *)array;

- (void)showSmallAddButtonDownState;
- (void)showSmallAddButtonNoramlState;

@end

