//
//  LMFileMoveResultFailureCategoryCell.h
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureBaseCell.h"
#import "LMAppCategoryItem.h"

@interface LMFileMoveResultFailureCategoryCell : LMFileMoveResultFailureBaseCell

@property (nonatomic, strong) NSTextField* descLabel;

- (void)setCellData:(LMAppCategoryItem *)item;

@end

