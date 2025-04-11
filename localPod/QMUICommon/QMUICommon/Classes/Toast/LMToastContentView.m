//
//  LMToastContentView.m
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMToastContentView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <Masonry/Masonry.h>

@interface LMToastContentView ()

@property (nonatomic, strong) NSView *backgroundView;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSTextField *textLabel;

@end

@implementation LMToastContentView

- (instancetype)init {
    if (self = [super init]) {
        self.isDarkModeSupported = YES;
        
        [self _setupLayer];
        [self _setupSubviews];
        [self _updateSubviews];
    }
    return self;
}

- (void)_setupLayer {
    self.wantsLayer = YES;
    self.layer.shadowOpacity = 0.25;
    self.layer.shadowOffset = NSMakeSize(0, -4);
    self.layer.shadowRadius = 10;
    self.layer.shadowColor = [[NSColor blackColor] CGColor];
    self.layer.masksToBounds = NO; // 14.0以下系统需要
}

- (void)_setupSubviews {
    [self addSubview:self.backgroundView];
    [self addSubview:self.imageView];
    [self addSubview:self.textLabel];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(16, 16));
    }];
    
    [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.imageView.mas_right).offset(5);
        make.centerY.mas_equalTo(0);
    }];
}

- (void)_updateSubviews {
    if (self.isDarkModeSupported) {
        self.backgroundView.layer.backgroundColor = [LMAppThemeHelper getCGColorRef:LMColor_DefaultBackground];
        self.textLabel.textColor = [LMAppThemeHelper getColor:LMColor_MainText_Black];
    } else {
        self.backgroundView.layer.backgroundColor = [LMAppThemeHelper getColor:LMColor_DefaultBackground lightModeOnly:YES].CGColor;
        self.textLabel.textColor = [LMAppThemeHelper getColor:LMColor_MainText_Black lightModeOnly:YES];
    }
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
            
    [self _updateSubviews];
}

- (void)updateImageViewWithStyle:(LMToastViewStyle)style {
    switch (style) {
        case LMToastViewStyleSuccess:
            self.imageView.image = [NSImage imageNamed:@"lm_toast_success_icon" withClass:self.class];
            break;
        case LMToastViewStyleInfo:
            self.imageView.image = [NSImage imageNamed:@"lm_toast_info_icon" withClass:self.class];
            break;
        case LMToastViewStyleWarning:
            self.imageView.image = [NSImage imageNamed:@"lm_toast_warning_icon" withClass:self.class];
            break;
        case LMToastViewStyleError:
            self.imageView.image = [NSImage imageNamed:@"lm_toast_error_icon" withClass:self.class];
            break;
    }
}

#pragma mark - Setter

- (void)setIsDarkModeSupported:(BOOL)isDarkModeSupported {
    _isDarkModeSupported = isDarkModeSupported;
    [self _updateSubviews];
}

#pragma mark - Getter

- (NSView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[NSView alloc] init];
        _backgroundView.wantsLayer = YES;
        _backgroundView.layer.cornerRadius = 5;
        _backgroundView.layer.masksToBounds = YES;
    }
    return _backgroundView;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] init];
        _imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        _imageView.accessibilityLabel = NSLocalizedString(@"提示", nil);
    }
    return _imageView;
}

- (NSTextField *)textLabel {
    if (!_textLabel) {
        _textLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
        _textLabel.editable = NO;
        _textLabel.bordered = NO;
        _textLabel.backgroundColor = [NSColor clearColor];
        _textLabel.font = [NSFont systemFontOfSize:12];
        _textLabel.refusesFirstResponder = YES;
    }
    return _textLabel;
}

@end
