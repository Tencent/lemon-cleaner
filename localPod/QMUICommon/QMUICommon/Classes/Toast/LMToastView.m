//
//  LMToastView.m
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMToastView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <Masonry/Masonry.h>

@interface LMToastView ()

@property (nonatomic, strong) LMToastContentView *contentView;

@end

@implementation LMToastView

+ (instancetype)toastViewWithStyle:(LMToastViewStyle)style title:(NSString *)title {
    LMToastView *toastView = [[LMToastView alloc] init];
    toastView.style = style;
    toastView.title = title;
    return toastView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认3秒后消失
        self.duration = 3;

        [self _setupSubviews];
    }
    return self;
}

- (void)_setupSubviews {
    [self addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}

#pragma mark - Public

- (void)showInView:(NSView *)view {
    NSArray *array = [NSArray arrayWithArray:view.subviews];
    for (NSView *view in array) {
        if ([view isKindOfClass:[LMToastView class]]) {
            [view removeFromSuperview];
        }
    }
    [view addSubview:self];
    
    CGSize labelSize = [self.title sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.contentView.textLabel.font, NSFontAttributeName, nil]];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(38);
        make.width.mas_equalTo(labelSize.width + 60);
        
        make.centerX.mas_equalTo(0);
        if (self.topOffset != 0) {
            make.top.mas_equalTo(self.topOffset);
        } else if (self.bottomOffset != 0) {
            make.bottom.mas_equalTo(-self.bottomOffset);
        } else {
            make.top.mas_equalTo(0);
        }
    }];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideToast) object:nil];
    [self performSelector:@selector(_hideToast) withObject:nil afterDelay:self.duration];
}

- (void)showInView:(NSView *)view duration:(NSTimeInterval)duration {
    self.duration = duration;
    
    [self showInView:view];
}

#pragma mark - Hide

- (void)_hideToast {
    [self removeFromSuperview];
}

#pragma mark - Setter

- (void)setStyle:(LMToastViewStyle)style {
    _style = style;
    [self.contentView updateImageViewWithStyle:style];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.contentView.textLabel.stringValue = title ?: @"";
}

#pragma mark - Getter

- (LMToastContentView *)contentView {
    if (!_contentView) {
        _contentView = [[LMToastContentView alloc] init];
    }
    return _contentView;
}

@end
