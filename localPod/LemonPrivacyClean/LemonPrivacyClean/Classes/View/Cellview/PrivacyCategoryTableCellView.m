//
//  CategoryReultTableCellView.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Masonry/Masonry-umbrella.h>
#import "PrivacyCategoryTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation PrivacyCategoryTableCellView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews {
    NSButton *checkButton = [[LMCheckboxButton alloc] init];
    self.checkButton = checkButton;
    checkButton.imageScaling = NSImageScaleProportionallyDown;
    checkButton.title = @"";
    [checkButton setButtonType:NSButtonTypeSwitch];
    checkButton.allowsMixedState = YES; // YES: 三种状态 -1, 1, 0, NO: 1 和 0; // -1 代码 mix 的状态, 显示的 - 而非 对号或者空白.
    [self addSubview:checkButton];


    NSImageView *imageView = [[NSImageView alloc] init];
    self.categoryImageView = imageView;
    [self addSubview:imageView];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;


    NSTextField *categoryLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    self.categoryLabel = categoryLabel;
    [self addSubview:categoryLabel];


    NSTextField *descLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    self.descLabel = descLabel;
    descLabel.font = [NSFontHelper getLightSystemFont:12];
    [self addSubview:descLabel];

    NSTextField *selectNumLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    self.selectedNumLabel = selectNumLabel;
    [self addSubview:selectNumLabel];


    [checkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(14);
        make.centerY.equalTo(checkButton.superview);
        make.left.equalTo(checkButton.superview).offset(32);
    }];

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(32);
        make.left.equalTo(checkButton.mas_right).offset(10);
        make.centerY.equalTo(self);
    }];

    [categoryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageView.mas_right).offset(14);
        make.top.equalTo(self).offset(10);
    }];

    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(categoryLabel);
        make.bottom.equalTo(self).offset(-12);
    }];

    [selectNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(categoryLabel);
        make.right.equalTo(self).offset(-66);
    }];

}

- (void)updateViewByItem:(PrivacyCategoryData *)categoryData {

    self.checkButton.state = categoryData.state;
    self.descLabel.stringValue = categoryData.tips;
    self.categoryLabel.stringValue = categoryData.categoryName;
    
    
    NSDictionary *normalAttributes = @{ NSForegroundColorAttributeName:[self getTitleColor],
                                        NSFontAttributeName: [NSFontHelper getLightSystemFont:12]};

    NSDictionary *colorAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithHex:0xFFAA09] ,
                                      NSFontAttributeName: [NSFontHelper getLightSystemFont:12]
                                      };
    
    NSMutableAttributedString *selectedAttributeStr;
    if (categoryData.selectedSubItemNum <= 0) {
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyCategoryTableCellView_updateViewByItem_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), categoryData.totalSubNum];
        selectedAttributeStr = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];
    } else {
        NSString *prefixString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyCategoryTableCellView_updateViewByItem_NSString_2", nil, [NSBundle bundleForClass:[self class]], @"")];
        NSString *numberString = [NSString stringWithFormat:@"%li", categoryData.selectedSubItemNum];
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyCategoryTableCellView_updateViewByItem_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""), prefixString,numberString];
        selectedAttributeStr = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];
        [selectedAttributeStr addAttributes:colorAttributes range:NSMakeRange(prefixString.length, numberString.length)];
    }
    self.selectedNumLabel.attributedStringValue = selectedAttributeStr;
    [LMAppThemeHelper setTitleColorForTextField:self.selectedNumLabel];
    self.categoryImageView.image = getCategoryImageByType(categoryData.categoryType);
    
    if(_belongSafari
       && categoryData.categoryType != PRIVACY_CATEGORY_TYPE_COOKIE //safari cookie 不需要 fullDiskAccess权限就可以获取
       && !_hasFullDiskAccessAuthority){  
        [self addFullDiskAccessSetttingBtn];
        self.selectedNumLabel.hidden = YES;
    }else{
        [self removeFullDiskAccessViews];
        self.selectedNumLabel.hidden = NO;
    }
    
}

-(NSColor *)getTitleColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"title_color" bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0x94979B];
    }
    
}

-(NSString *)getNoFullDiskAccessAuthorityWording{
    return NSLocalizedStringFromTableInBundle(@"GETAccessAuthority", nil, [NSBundle bundleForClass:[self class]], @"");
}

@end
