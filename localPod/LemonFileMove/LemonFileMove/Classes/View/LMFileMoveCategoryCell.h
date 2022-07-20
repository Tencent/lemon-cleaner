//
//  LMFileMoveCategoryCell.h
//  LemonFileMove
//
//  
//

#import "LMFileMoveBaseCell.h"
#import "LMAppCategoryItem.h"


@interface LMFileMoveCategoryCell : LMFileMoveBaseCell

@property (nonatomic, strong) IBOutlet NSTextField* descLabel;

- (void)setCellData:(LMAppCategoryItem *)item;

@end

