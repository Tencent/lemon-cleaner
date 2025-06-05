//
//  Owl2DeviceProtectionSwitchView.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2DeviceProtectionSwitchView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/COSwitch.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/LMReferenceDefines.h>

@interface Owl2DeviceProtectionSwitchConfig ()

@property (nonatomic, copy) void (^valueDidChangeBlock)(Owl2DeviceProtectionSwitchConfig *config);

@end

@implementation Owl2DeviceProtectionSwitchConfig @end


@interface Owl2DeviceProtectionSwitchView ()

@property (nonatomic, strong) NSImageView *imageView;

@property (nonatomic, strong) NSTextField *titleLabel;

@property (nonatomic, strong) NSTextField *descLabel;

@property (nonatomic, strong) COSwitch *switchBtn;

@end

@implementation Owl2DeviceProtectionSwitchView

- (instancetype)initWithFrame:(NSRect)frame config:(Owl2DeviceProtectionSwitchConfig *)config {
    self = [super initWithFrame:frame];
    if (self) {
        self.config = config;
        [self setupSubviews];
        [self setupSubviewsLayout];
        self.switchBtn.on = self.config.on;
        [self updateUI];
        
    }
    return self;
}

- (void)setupSubviews {
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.descLabel];
    [self addSubview:self.switchBtn];
}

- (void)setupSubviewsLayout {
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(20);
        make.centerX.mas_equalTo(0);
//        make.size.mas_equalTo(CGSizeMake(78, 78));
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.imageView.mas_bottom).offset(12);
        make.centerX.mas_equalTo(0);
    }];
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(2);
        make.centerX.mas_equalTo(0);
    }];
    [self.switchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.descLabel.mas_bottom).offset(26);
        make.centerX.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(60, 28));
//        make.bottom.mas_equalTo(self.mas_bottom).offset(-8);
    }];
}

- (void)updateUI {
    NSImage *image = self.config.on ? [[self bundle] imageForResource:self.config.imageNameOn] :  [[self bundle] imageForResource:self.config.imageNameOff];
    self.imageView.image = image;
    self.titleLabel.stringValue = self.config.title;
    self.descLabel.stringValue = self.config.desc;
    [self.switchBtn updateSwitchState:self.config.on];
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    self.switchBtn.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
}

#pragma mark - getter

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] init];
        _imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    return _imageView;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [self buildLabel:self.config.title font:[NSFont systemFontOfSize:20] color:[LMAppThemeHelper getTitleColor]];
    }
    return _titleLabel;
}

- (NSTextField *)descLabel {
    if (!_descLabel) {
        _descLabel = [self buildLabel:self.config.desc font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    }
    return _descLabel;
}

- (COSwitch *)switchBtn {
    if (!_switchBtn) {
        _switchBtn = [[COSwitch alloc] init];
        _switchBtn.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
        
        @weakify(self);
        [_switchBtn setOnDidClicked:^(COSwitch *button) {
            @strongify(self);
            if (self.delegate && [self.delegate respondsToSelector:@selector(owl2DeviceProtectionSwitchDidClicked:)]) {
                [self.delegate owl2DeviceProtectionSwitchDidClicked:self.config];
            }
        }];
        [_switchBtn setOnValueChanged:^(COSwitch *button) {
            @strongify(self);
            
            if (self.config.on != button.on) {
                self.config.on = button.on;
                [self updateUI];
                if (self.delegate && [self.delegate respondsToSelector:@selector(owl2DeviceProtectionSwitchValueDidChange:)]) {
                    [self.delegate owl2DeviceProtectionSwitchValueDidChange:self.config];
                }
            }
        }];
    }
    return _switchBtn;
}

#pragma mark -

- (NSBundle *)bundle {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return bundle;
}

- (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentCenter;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}

@end
