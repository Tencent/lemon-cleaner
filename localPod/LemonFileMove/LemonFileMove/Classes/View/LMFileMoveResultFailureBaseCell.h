//
//  LMFileMoveResultFailureBaseCell.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMCheckboxButton.h>
#import "LMCheckboxButton.h"
#import "LMBaseItem.h"

@interface LMFileMoveResultFailureBaseCell : NSTableCellView {
    BOOL m_hight;
}

@property (nonatomic, strong) NSImageView *iconView;

@property (nonatomic, strong) NSTextField *titleLabel;

@property (nonatomic, strong) NSTextField *sizeLabel;

- (void)setHightLightStyle:(BOOL)hight;

- (void)setCellData:(LMBaseItem *)item;

+ (NSString *)cellID;
+ (CGFloat)cellHeight;

@end
