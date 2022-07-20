//
//  LMFileMoveCategoryCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveCategoryCell.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface LMFileMoveCategoryCell ()


@end

@implementation LMFileMoveCategoryCell

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.left.equalTo(self.iconView.mas_right).offset(8);
        make.centerY.equalTo(self.iconView);
    }];
    
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.left.equalTo(self.titleLabel.mas_right).offset(10);
        make.centerY.equalTo(self.titleLabel);
    }];
}

- (void)setCellData:(LMAppCategoryItem *)item {
    [super setCellData:item];
    self.titleLabel.stringValue = item.title;
    if (item.iconName) {
        NSImage *icon = [NSImage imageNamed:item.iconName withClass:[self class]];
        [self.iconView setImage:icon];
    }
    if (item.des) {
        self.descLabel.stringValue = item.des;
    }
    
    self.checkButton.state = [item updateSelectState];
}

- (CGFloat)getViewHeight {
    return 42;
}


@end
