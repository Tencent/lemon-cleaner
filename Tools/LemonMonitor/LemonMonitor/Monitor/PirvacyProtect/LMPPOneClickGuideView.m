//
//  LMPPOneClickGuideView.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LMPPOneClickGuideView.h"
#import "LMPPOneClickGuideBgView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMTitleButton.h>
#import <QMUICommon/LMImageButton.h>
#import <PrivacyProtect/PrivacyProtect.h>
#import <QMCoreFunction/LanguageHelper.h>

@interface LMPPOneClickGuideView ()

@property (nonatomic, strong) LMPPOneClickGuideBgView *bgView;

@property (nonatomic, strong) NSImageView *tipImageView;

@property (nonatomic, strong) NSTextField *tipTF;

@property (nonatomic, strong) LMTitleButton *oneClickButton;

@property (nonatomic, strong) LMImageButton *closeButton;

@end

@implementation LMPPOneClickGuideView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        [self setupSubviewsLayout];
    }
    return self;
}

- (void)setupSubviews {
    [self addSubview:self.bgView];
    [self addSubview:self.tipImageView];
    [self addSubview:self.tipTF];
    [self addSubview:self.oneClickButton];
    [self addSubview:self.closeButton];
}

- (void)setupSubviewsLayout {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    // 自左布局
    [self.tipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.tipTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.tipImageView.mas_right).offset(8);
        make.centerY.mas_equalTo(0);
        make.width.mas_equalTo(180);
    }];
    
    // 自右布局
    // 10 --image(7) -- 10
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(24, 16));
    }];
    
    [self.oneClickButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.closeButton.mas_left).offset(-2);
        make.centerY.mas_equalTo(0);
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            make.size.mas_equalTo(NSMakeSize(52, 16));
        } else {
            make.size.mas_equalTo(NSMakeSize(50, 16));
        }
    }];
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
}

#pragma mark - action

- (void)oneClickButtonClicked:(LMTitleButton *)btn {
    NSLog(@"oneClickButton is clicked");
    [Owl2Manager sharedManager].oneClickGuideViewClicked = YES;
    self.hidden = YES;
    if (self.oneClickBlock) self.oneClickBlock();
}

- (void)closeButtonClicked:(LMImageButton *)btn {
    NSLog(@"closeButton is clicked");
    [Owl2Manager sharedManager].oneClickGuideViewClosed = YES;
    self.hidden = YES;
}

#pragma mark - getter

- (LMPPOneClickGuideBgView *)bgView {
    if (!_bgView) {
        _bgView = [[LMPPOneClickGuideBgView alloc] init];
        _bgView.wantsLayer = YES;
        _bgView.layer.opacity = 0.2;
        _bgView.layer.cornerRadius = 8;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (NSImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[NSImageView alloc] init];
        _tipImageView.image = [NSImage imageNamed:@"LM_warn_icon"];
        _tipImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    return _tipImageView;
}

- (NSTextField *)tipTF {
    if (!_tipTF) {
        _tipTF = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
        _tipTF.stringValue = NSLocalizedString(@"开启保护，防止隐私设备异常使用", nil);
        _tipTF.maximumNumberOfLines = 1;
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            _tipTF.maximumNumberOfLines = 2;
        }
    }
    return _tipTF;
}

- (LMTitleButton *)oneClickButton {
    if (!_oneClickButton) {
        _oneClickButton = [[LMTitleButton alloc] initWithFrame:NSMakeRect(0, 0, 48, 16)];
        [_oneClickButton setBezelStyle:NSBezelStylePush];
        _oneClickButton.bordered = NO;
        
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithHex:0x1A83F7]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"一键开启", nil) attributes:attributes];
        [_oneClickButton setAttributedTitle:attributedTitle];

        // 添加按钮点击事件
        [_oneClickButton setTarget:self];
        [_oneClickButton setAction:@selector(oneClickButtonClicked:)];
    }
    return _oneClickButton;
}

- (LMImageButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[LMImageButton alloc] initWithFrame:NSMakeRect(0, 0, 27, 16)];
        _closeButton.bordered = NO;
        _closeButton.bezelStyle = NSBezelStylePush;
        [_closeButton setImage:[NSImage imageNamed:@"LM_close_icon"]];
        [_closeButton setImageScaling:NSImageScaleNone];
        // 添加按钮点击事件
        [_closeButton setTarget:self];
        [_closeButton setAction:@selector(closeButtonClicked:)];
    }
    return _closeButton;
}

@end
