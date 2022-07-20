//
//  LMFileMoveSubCategoryCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveSubCategoryCell.h"
#import <QMCoreFunction/NSImage+Extension.h>

@implementation LMFileMoveSubCategoryCell

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)setCellData:(LMFileCategoryItem *)item {
    [super setCellData:item];
    self.titleLabel.stringValue = item.title;
    if (item.iconName) {
        NSImage *icon = [NSImage imageNamed:item.iconName withClass:[self class]];
        [self.iconView setImage:icon];
    }
    self.checkButton.state = [item updateSelectState];
}


- (CGFloat)getViewHeight {
    return 42;
}

@end
