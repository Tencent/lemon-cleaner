//
//  QMProgressView.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMProgressView.h"
#import <Quartz/Quartz.h>

@interface QMProgressView()
{
    CALayer * m_maskLayer;
    CALayer * m_fillLayer;
    CALayer * m_backLayer;
    QMProgressViewType _progressViewType;
}
@end

@implementation QMProgressView


- (void)setupView {
    _backColor = [NSColor colorWithHex:0x7f7f7f alpha:0.13];
    _fillColor = [NSColor colorWithHex:0x7bcf8c];

    /*
     _fillColor = [NSColor colorWithSRGBRed:8.0 / 255
     green:135.0 / 255
     blue:1
     alpha:1];
     */
    _minValue = 0;
    _maxValue = 1;
    _value = 0;
    _animationTime = 0.2;
    _animation = YES;
    
    [self setWantsLayer:YES];
    
    NSRect layerRect = self.bounds;
    CALayer * backLayer = [CALayer layer];
    backLayer.frame = layerRect;
    backLayer.borderColor = [_backColor convertToCGColor];
    backLayer.borderWidth = 0;
    backLayer.backgroundColor = [_backColor convertToCGColor];
    backLayer.cornerRadius = layerRect.size.height / 2;
    m_backLayer = backLayer;
    
    if (_progressViewType == QMProgressViewTypeNormal) {
        m_fillLayer = [self getFillLayer:layerRect];
    }else if (_progressViewType == QMProgressViewTypeGradiant){
        m_fillLayer = [self getGradientFillLayer:layerRect];
    }
    
    [backLayer addSublayer:m_fillLayer];
    
    m_maskLayer = [CALayer layer];
    m_maskLayer.backgroundColor = [_fillColor convertToCGColor];
    m_maskLayer.cornerRadius = layerRect.size.height / 2;
    NSRect rect = layerRect;
    rect.size.width = 0;
    m_maskLayer.frame = rect;
    [backLayer addSublayer:m_maskLayer];
    [m_fillLayer setMask:m_maskLayer];
    
    _border = layerRect.size.height / 2;
    
    self.actionEnd = YES;
    [self setLayer:backLayer];
}

-(CALayer *)getGradientFillLayer:(NSRect)layerRect{
    CAGradientLayer * fillLayer = [CAGradientLayer layer];
    fillLayer.frame = layerRect;
    [fillLayer setColors:@[(id)[NSColor colorWithHex:0x64dfa7].CGColor, (id)[NSColor colorWithHex:0x00d899].CGColor]];
    //    [fillLayer setLocations:@[@0.01, @1]];
    [fillLayer setStartPoint:CGPointMake(0, 0)];
    [fillLayer setEndPoint:CGPointMake(1, 1)];
    fillLayer.cornerRadius = layerRect.size.height / 2;
    return fillLayer;
}

-(CALayer *)getFillLayer:(NSRect) layerRect{
    CALayer * fillLayer = [CALayer layer];
    fillLayer.frame = layerRect;
    fillLayer.backgroundColor = [_fillColor convertToCGColor];
    fillLayer.cornerRadius = layerRect.size.height / 2;
    return fillLayer;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _progressViewType = QMProgressViewTypeGradiant;
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _progressViewType = QMProgressViewTypeGradiant;
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame progressViewType:(QMProgressViewType) progressViewType
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _progressViewType = progressViewType;
        [self setupView];
    }
    return self;
}

- (void)setBorder:(CGFloat)border
{
    if (_border == border)
        return;
    m_fillLayer.cornerRadius = border;
    m_backLayer.cornerRadius = border;
    m_maskLayer.cornerRadius = border;
}


// 特别注意: 如果极短时间(100ms间隔 为例)调用setValue多次,可能造成视觉上 processView 回退的问题.
// 因为 改变 frame 会默认增加上动画, 关闭动画效果就不会出现 processView 回退的问题,但进度增加的不平滑.
//  [CATransaction setDisableActions:NO] 可以关闭动画.
// fix 方法: 减少 setValue的调用次数. 比如以一变量 纪录 process, 然后定时(0.2s)取 process值后再调用setValue.
- (void)setValue:(float)value
{
    if (_value == value || fabs(_value - value) < 0.02 * (_maxValue - _minValue) || isnan(value))
        return;    
    _value = value;
    NSRect rect = self.bounds;
    rect.origin.x = rect.size.width * (_value - (_maxValue - _minValue));
    
    if (!self.actionEnd || value == 0)
        [m_maskLayer removeAllAnimations];
    
    self.actionEnd = NO;
    [CATransaction setCompletionBlock:^{
        self.actionEnd = YES;
    }];
    // setValue调用间隔大于_animationTime可以保证，进度条不出现回退
    [CATransaction setAnimationDuration:_animationTime];
    
    // value set到0的时候一般是复位进度条，复位进度条不使用动画，避免动画没做完又调用setValue造成
    // 进度条回退
    if (_value < 0.01) {
        [CATransaction setDisableActions:YES];
    } else {
        [CATransaction setDisableActions:!_animation];
    }
    
    m_maskLayer.frame = rect;
}

- (void)setBackColor:(NSColor *)backColor
{
    if (_backColor == backColor)
        return;
    m_backLayer.backgroundColor = [backColor convertToCGColor];
}
- (void)setFillColor:(NSColor *)fillColor
{
    if (_fillColor == fillColor)
        return;
    m_fillLayer.backgroundColor = [fillColor convertToCGColor];
}
- (void)setBorderColor:(NSColor *)borderColor
{
    if (_borderColor == borderColor)
        return;
    m_backLayer.borderColor = [borderColor convertToCGColor];
}


@end
