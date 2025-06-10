//
//  OwlListPlaceHolderView.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlListPlaceHolderView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>

@interface OwlListPlaceHolderView ()

@property (nonatomic, strong) NSTextField * titleField;
@property (nonatomic, strong) NSImageView * imageView;

@end

@implementation OwlListPlaceHolderView

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        self.titleField.stringValue = title ?: @"";
        
        self.wantsLayer = YES;
        [self addSubview:self.titleField];
        [self addSubview:self.imageView];
        
        [self __layoutSubviews];
    }
    return self;
}

- (void)__layoutSubviews {
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.size.mas_equalTo(NSMakeSize(180, 180));
        make.centerY.equalTo(self).mas_offset(-20);
    }];
    
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.imageView.mas_bottom);
    }];
}


- (NSTextField *)titleField {
    if (!_titleField) {
        _titleField = [[NSTextField alloc] init];
        _titleField.alignment = NSTextAlignmentCenter;
        _titleField.backgroundColor = [NSColor clearColor];
        _titleField.bordered = NO;
        _titleField.editable = NO;
        _titleField.font = [NSFontHelper getLightSystemFont:12];
        _titleField.textColor = [NSColor colorWithHex:0x989A9E];
    }
    return _titleField;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] init];
        _imageView.image = [NSImage imageNamed:@"lemon_privacy_blank_placeholder"];
    }
    return _imageView;
}

@end
