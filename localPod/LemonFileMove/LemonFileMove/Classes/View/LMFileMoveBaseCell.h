//
//  LMFileMoveBaseCell.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMCheckboxButton.h>
#import "LMCheckboxButton.h"

@interface LMFileMoveBaseCell : NSTableCellView {
    BOOL m_hight;
}

@property (nonatomic, strong) IBOutlet LMCheckboxButton *checkButton;

@property (nonatomic, strong) IBOutlet NSImageView *iconView;

@property (nonatomic, strong) IBOutlet NSTextField *titleLabel;

@property (nonatomic, strong) IBOutlet NSTextField *sizeLabel;

- (void)setHightLightStyle:(BOOL)hight;

- (void)setCellData:(id)item;

@end
