//
//  LMFileMoveResultFailureFileCell.h
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureBaseCell.h"
#import "LMResultItem.h"
#import <QMUICommon/LMPathBarView.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveResultFailureFileCell : LMFileMoveResultFailureBaseCell

@property (nonatomic, strong) LMPathBarView *pathBarView;

@property (nonatomic, strong) NSButton *showInFinderButton;

@property (nonatomic, strong) LMResultItem *resultItem;

- (void)setCellData:(LMResultItem *)item;

@end

NS_ASSUME_NONNULL_END
