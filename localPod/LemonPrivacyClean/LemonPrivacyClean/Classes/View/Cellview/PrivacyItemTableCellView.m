//
//  ItemResultTableCellView.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyItemTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import "Masonry.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
@implementation PrivacyItemTableCellView


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
    checkButton.title = @"";
    [checkButton setButtonType:NSButtonTypeSwitch];
    checkButton.imageScaling = NSImageScaleProportionallyDown;
    checkButton.allowsMixedState = NO; // YES: 三种状态 -1, 1, 0, NO: 1 和 0; // -1 代码 mix 的状态, 显示的 - 而非 对号或者空白.
    [self addSubview:checkButton];

    NSTextField *itemLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    [LMAppThemeHelper setTextColorName:@"outlineview_subitem_text_color" defaultColor:[NSColor colorWithHex:0x94979B] for:itemLabel];
    self.itemLabel = itemLabel;
    itemLabel.font = [NSFontHelper getLightSystemFont:12];
    
    itemLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    if (@available(macOS 10.11, *)) {
        itemLabel.maximumNumberOfLines = 1;
    } else {
    }
    [self addSubview:itemLabel];

    NSTextField *totalNumLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979B]];
    totalNumLabel.font = [NSFontHelper getLightSystemFont:12];
    [LMAppThemeHelper setTextColorName:@"outlineview_subitem_text_color" defaultColor:[NSColor colorWithHex:0x94979B] for:totalNumLabel];
    self.itemNumLabel = totalNumLabel;
    [self addSubview:totalNumLabel];

    [checkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(14);
        make.centerY.equalTo(self);
        make.left.equalTo(checkButton.superview).offset(56);
    }];

    [itemLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(checkButton.mas_right).offset(10);
        make.centerY.equalTo(self);
        make.width.mas_lessThanOrEqualTo(400);
    }];

    [totalNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-66);
    }];
}

- (void)updateViewBy:(PrivacyItemData *)itemData {
    self.checkButton.state = itemData.state;
    self.itemLabel.stringValue = itemData.itemName;
    self.itemNumLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyItemTableCellView_updateViewBy_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), itemData.totalSubNum];
    [self.checkButton setState:itemData.state];
}

@end
