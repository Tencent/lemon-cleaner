//
//  LMFileMoveProcessCell.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import "LMFileMoveProcessCellViewItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveProcessRowView : NSTableRowView

@end

@interface LMFileMoveProcessCell : NSTableCellView

@property (nonatomic, strong) LMFileMoveProcessCellViewItem *viewItem;

+ (NSString *)cellID;
+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
