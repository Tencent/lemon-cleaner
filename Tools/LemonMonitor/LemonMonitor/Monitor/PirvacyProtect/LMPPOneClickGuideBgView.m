//
//  LMPPOneClickGuideBgView.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMPPOneClickGuideBgView.h"

@interface LMPPOneClickGuideBgView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation LMPPOneClickGuideBgView

- (void)layout {
    [super layout];
    self.gradientLayer.frame = self.bounds;
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    [self.layer addSublayer:self.gradientLayer];
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        // 创建渐变层
        _gradientLayer = [CAGradientLayer layer];
         // 设置渐变颜色
        _gradientLayer.colors = @[(id)[NSColor colorWithHex:0xFF9900 alpha:0.8].CGColor,
                                  (id)[NSColor colorWithHex:0xFF9900 alpha:0.4].CGColor];
         
         // 设置渐变方向（水平）
        _gradientLayer.startPoint = CGPointMake(0.0, 0.5); // 左侧
        _gradientLayer.endPoint = CGPointMake(1.0, 0.5);   // 右侧
    }
    return _gradientLayer;
}

@end
