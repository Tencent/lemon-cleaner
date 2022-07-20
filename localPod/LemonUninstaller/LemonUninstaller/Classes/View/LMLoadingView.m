//
//  LMLoadingView.m
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMLoadingView.h"
#import <QuartzCore/CAGradientLayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAShapeLayer.h>
#import "NSBezierPath+Extension.h"
#import "NSColor+Extension.h"

@interface LMLoadingView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation LMLoadingView


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self initView];
    }
    return self;
    
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.wantsLayer = YES;
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.gradientLayer.borderWidth = 1;
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
//    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self.layer addSublayer:self.gradientLayer];
    self.gradientLayer.colors = @[(__bridge id)[NSColor colorWithHex:0xf2f2f2].CGColor,
                                  (__bridge id)[NSColor colorWithHex:0xe8e8e8].CGColor,
                                  (__bridge id)[NSColor colorWithHex:0xf2f2f2].CGColor];
//    self.gradientLayer.colors = @[(__bridge id)[NSColor colorWithHex:0xf20000].CGColor,
//                                  (__bridge id)[NSColor colorWithHex:0x00e800].CGColor,
//                                  (__bridge id)[NSColor colorWithHex:0xf20000].CGColor];
    //设置颜色渐变方向 (0,0)->(1,1)则45度方向 (0,0)->(1,0)上->下
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 0);
    
    //    //设置颜色分割点
    self.gradientLayer.locations = @[@(0),@(0.2),@(0.3)];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
    
    animation.fromValue =@[@(0),@(0),@(0.25)];
    animation.toValue =@[@(0.75),@(1),@(1)];
    animation.duration= 1;
    animation.repeatCount = HUGE;
    [self.gradientLayer addAnimation:animation forKey:nil];
    
    NSInteger marginTop = 20;
    NSInteger rowHeight = 24;
    NSInteger y = self.frame.size.height - marginTop  - rowHeight / 2;
    NSInteger rowCount = 7;
    NSInteger rowMargin = 62;
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    for (int i = 0; i < rowCount; i++) {
        //draw a circle
        CGPathAddEllipseInRect(pathRef, nil, CGRectMake(44, y - 24/2, 24, 24));
        
        NSInteger rectHeight = 6;
        NSInteger rect1Width = 54;
        //rect 1
        CGPathAddRect(pathRef, nil, CGRectMake(78, y - rectHeight / 2, rect1Width, rectHeight));
        
        //rect 2
        NSInteger rect2Width = 73;
        CGPathAddRect(pathRef, nil, CGRectMake(328, y - rectHeight / 2, rect2Width, rectHeight));
        
        //rect 3
        NSInteger rect3Width = 159;
        CGPathAddRect(pathRef, nil, CGRectMake(496, y - rectHeight / 2, rect3Width, rectHeight));
        
        //rect 4
        NSInteger rect4Width = 27;
        CGPathAddRect(pathRef, nil, CGRectMake(714, y - rectHeight / 2, rect4Width, rectHeight));
        y -= rowMargin;
    }
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = pathRef;
    CGPathRelease(pathRef);
    
    self.gradientLayer.mask = maskLayer;
    
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)dealloc
{
    NSLog(@"LMLoadingView dealloc");
    [self.gradientLayer removeAllAnimations];
}



@end
