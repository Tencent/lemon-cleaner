//
//  LMFileMoveProcessCellViewItem.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMAppCategoryItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LMFileMoveProcessCellStatus) {
    LMFileMoveProcessCellStatusPending  = 0, // 待导出
    LMFileMoveProcessCellStatusMoving   = 1, // 导出中
    LMFileMoveProcessCellStatusDone     = 2, // 已完成
    LMFileMoveProcessCellStatusError    = 3, // 部分失败
};

@interface LMFileMoveProcessCellViewItem : NSObject

@property (nonatomic, assign, readonly) LMAppCategoryItemType type;
@property (nonatomic, assign) LMFileMoveProcessCellStatus status;

@property (nonatomic, strong, readonly) NSString *imageName;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSAttributedString *attributedDetail;

@property (nonatomic, strong) NSImage *movingFileImage;
@property (nonatomic, strong) NSString *movingFileName;
@property (nonatomic, strong) NSString *movingFileSizeText;

@property (nonatomic, assign) long long moveFailedFileSize;

+ (instancetype)viewItemWithAppCategoryItem:(LMAppCategoryItem *)appCategoryItem;

@end

NS_ASSUME_NONNULL_END
