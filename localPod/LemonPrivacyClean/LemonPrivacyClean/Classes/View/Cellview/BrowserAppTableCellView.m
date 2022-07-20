//
//  BrowserAppTableCellView.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "BrowserAppTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import "QMExtension.h"
#import <Masonry/Masonry.h>
#import "PrivacyDataManager.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>


@implementation BrowserAppTableCellView {
    BrowserApp *app;
}

- (instancetype)initWithFrame:(NSRect)frameRect {

    if (self = [super initWithFrame:frameRect]) {
        [self setupSubViews];
    }

    return self;
}

- (void)setupSubViews {

    NSImageView *imageView = [[NSImageView alloc] init];
    [self addSubview:imageView];
    self.appImageView = imageView;
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSTextField *appNameLabel = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x7E7E7E]];
    [LMAppThemeHelper setTextColorName:@"second_text_color" defaultColor:[NSColor colorWithHex:0x7E7E7E] for:appNameLabel];
    [self addSubview:appNameLabel];
    self.appNameLabel = appNameLabel;

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(30);
        make.centerY.mas_equalTo(self);
        make.left.equalTo(self);
    }];

    [appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imageView);
        make.left.equalTo(imageView.mas_right).offset(10);
    }];

}

- (void)updateViewsBy:(BrowserApp *)browserApp {
    self->app = browserApp;

    self.appImageView.image = [PrivacyDataManager getBrowserIconByType:app.appType];
    self.appNameLabel.stringValue = [NSString stringWithFormat:@"%@", app.appName];
}




@end
