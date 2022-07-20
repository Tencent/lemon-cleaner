//
//  LMFileMoveResultFailureSubCategoryCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureSubCategoryCell.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMFileMoveCommonDefines.h"

@implementation LMFileMoveResultFailureSubCategoryCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _setupViews];
    }
    return self;
}

- (void)_setupViews {
    self.sizeLabel.frame = NSMakeRect(777, 7, 105, 18);
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconView.mas_right).offset(9);
        make.centerY.equalTo(self.iconView);
        make.width.mas_equalTo(254);
    }];
}

- (void)setCellData:(LMFileCategoryItem *)item {
    [super setCellData:item];
    self.titleLabel.stringValue = item.title;
    if (item.iconName) {
        NSImage *icon = [NSImage imageNamed:item.iconName withClass:[self class]];
        [self.iconView setImage:icon];
    }
}

@end
