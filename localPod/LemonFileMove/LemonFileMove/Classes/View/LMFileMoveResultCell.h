//
//  LMFileMoveResultCell.h
//  LemonFileMove
//
//  
//

#import "LMFileMoveBaseCell.h"
#import "LMResultItem.h"
#import <QMUICommon/LMPathBarView.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveResultCell : LMFileMoveBaseCell

@property (weak, nonatomic) IBOutlet LMPathBarView *pathBarView;

@property (weak, nonatomic) IBOutlet NSButton *showInFinderButton;

@property (nonatomic, strong) LMResultItem *resultItem;

- (void)setCellData:(LMResultItem *)item;

@end

NS_ASSUME_NONNULL_END
