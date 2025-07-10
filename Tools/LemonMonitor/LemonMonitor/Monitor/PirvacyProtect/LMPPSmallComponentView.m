//
//  LMPPSmallComponentView.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMPPSmallComponentView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/COSwitch.h>
#import <QMCoreFunction/LMReferenceDefines.h>
#import <PrivacyProtect/PrivacyProtect.h>

@interface LMPPSmallComponentView ()

@property (nonatomic, assign) LMPPComponentType type;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) NSImage * enableImage;
@property (nonatomic, strong) NSImage * disableImage;

@property (nonatomic, strong) NSImageView * iconView;
@property (nonatomic, strong) NSTextField * titleLabel;
@property (nonatomic, strong) NSTextField * subtitleLabel;
@property (nonatomic, strong) COSwitch * switchButton;

@end

@implementation LMPPSmallComponentView

- (instancetype)initWithType:(LMPPComponentType)type
                       title:(NSString *)title
                 enableImage:(NSImage *)enableImage
                disableImage:(NSImage *)disableImage
{
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        self.type = type;
        self.title = title ?: @"";
        self.enableImage = enableImage;
        self.disableImage = disableImage;
        
        [self setupSubviews];
        [self setupSubviewsLayout];
        
        [self updateUI];
    }
    return self;
}

- (void)setupSubviews {
    
    self.wantsLayer = YES;
    self.layer.cornerRadius = 4.0;
    self.layer.borderWidth = 1;
    [self __updateBackgroundBorderColor];
    
    [self addSubview:self.iconView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subtitleLabel];
    [self addSubview:self.switchButton];
}

- (void)setupSubviewsLayout {
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.mas_offset(10);
        make.size.mas_equalTo(NSMakeSize(16, 16));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.iconView);
        make.left.equalTo(self.iconView.mas_right).offset(10);
        make.width.mas_equalTo(120);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconView.mas_bottom).offset(10);
        make.left.equalTo(self.iconView);
        make.width.mas_equalTo(100);
    }];
    
    [self.switchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.subtitleLabel);
        make.right.mas_equalTo(-11);
        make.size.mas_equalTo(CGSizeMake(30, 14));
    }];
}


- (void)updateUI {
    switch (self.type) {
        case LMPPComponentType_Video:
            [self __updateUIWithState:[Owl2Manager.sharedManager isWatchVideo]];
            break;
        case LMPPComponentType_Audio:
            [self __updateUIWithState:[Owl2Manager.sharedManager isWatchAudio]];
            break;
        case LMPPComponentType_Screen:
            [self __updateUIWithState:[Owl2Manager.sharedManager isWatchScreen]];
            break;
        case LMPPComponentType_Automatic:
            [self __updateUIWithState:[Owl2Manager.sharedManager isWatchAutomatic]];
            break;
            
        default:
            break;
    }
}

- (void)__updateUIWithState:(BOOL)on {
    [self.switchButton updateSwitchState:on];
    self.iconView.image = on ? self.enableImage : self.disableImage;
    self.subtitleLabel.stringValue = on ? NSLocalizedString(@"监控中", nil) : NSLocalizedString(@"未开启", nil);
    self.subtitleLabel.textColor = [NSColor colorWithHex:(on ? 0x94979b : 0xFFAA00)];
}

#pragma mark - mouse up

- (void)mouseUp:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (!NSPointInRect(point, self.bounds)) {
        return;
    }
    if (self.onClickBackgroundHandler) {
        self.onClickBackgroundHandler();
    }
}

#pragma mark -

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    self.switchButton.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
    [self __updateBackgroundBorderColor];
}

- (void)__updateBackgroundBorderColor {
    self.layer.borderColor = [[NSColor colorWithHex:0xF6F6F6] CGColor];
    if (@available(macOS 10.14, *)) {
        if([LMAppThemeHelper isDarkMode]){
            self.layer.borderColor = [NSColor colorWithHex:0x9A9A9A alpha:0.2].CGColor;
        }
    }
}

#pragma mark - lazy

- (NSImageView *)iconView {
    if (!_iconView) {
        _iconView = [[NSImageView alloc] init];
        _iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    return _iconView;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
        _titleLabel.alignment = NSTextAlignmentLeft;
        _titleLabel.stringValue = self.title;
        _titleLabel.maximumNumberOfLines = 1;
    }
    return _titleLabel;
}

- (NSTextField *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
        _titleLabel.alignment = NSTextAlignmentLeft;
        _subtitleLabel.stringValue = self.title;
        _subtitleLabel.maximumNumberOfLines = 1;
    }
    return _subtitleLabel;
}

- (COSwitch *)switchButton {
    if (!_switchButton) {
        _switchButton = [[COSwitch alloc] init];
        _switchButton.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
        
        @weakify(self);
        [_switchButton setOnValueChanged:^(COSwitch *button) {
            @strongify(self);
            if (self.onClickSwitchHandler) {
                self.onClickSwitchHandler(button.on);
            }
//            [QMReport reportButtonClick:LEMON_OWL_ALLOW_AUTOMATIC_BUTTON_CLICK];
//            [[NSUserDefaults standardUserDefaults] setBool:config.on forKey:K_IS_WATCHING_AUTOMATIC];
        }];
    }
    return _switchButton;
}

@end
