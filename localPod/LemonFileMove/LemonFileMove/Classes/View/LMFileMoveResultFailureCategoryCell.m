//
//  LMFileMoveResultFailureCategoryCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureCategoryCell.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface LMFileMoveResultFailureCategoryCell ()

@end

@implementation LMFileMoveResultFailureCategoryCell

+ (CGFloat)cellHeight {
    return 42;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _setupViews];
    }
    return self;
}

- (void)_setupViews {
    self.titleLabel.font = [NSFont systemFontOfSize:14];
    self.sizeLabel.frame = NSMakeRect(790, 12, 105, 18);

//    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.height.mas_equalTo(18);
//        make.left.equalTo(self.titleLabel.mas_right).offset(10);
//        make.centerY.equalTo(self.titleLabel);
//    }];
}

- (void)setCellData:(LMAppCategoryItem *)item {
    [super setCellData:item];
    self.titleLabel.stringValue = item.title;
    if (item.iconName) {
        NSImage *icon = [NSImage imageNamed:item.iconName withClass:[self class]];
        [self.iconView setImage:icon];
    }
//    if (item.des) {
//        self.descLabel.stringValue = item.des;
//    }
}

- (CGFloat)getViewHeight {
    return 42;
}

@end
