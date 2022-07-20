//
//  LMFileMoveProcessCellViewItem.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveProcessCellViewItem.h"
#import "LMFileMoveCommonDefines.h"
#import "LMFileMoveManger.h"
#import "LMFileHelper.h"
#import "LMFileCategoryItem.h"
#import "LMResultItem.h"

@interface LMFileMoveProcessCellViewItem ()

@property (nonatomic, assign) LMAppCategoryItemType type;
//@property (nonatomic, assign) NSInteger fileCount;
@property (nonatomic, assign) long long totalFileSize;

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSAttributedString *attributedDetail;

@end

@implementation LMFileMoveProcessCellViewItem

+ (instancetype)viewItemWithAppCategoryItem:(LMAppCategoryItem *)appCategoryItem {
//    NSInteger fileCount = 0;
//    for (LMFileCategoryItem *fileCategoryItem in appCategoryItem.subItems) {
//        for (LMResultItem *resultItem in fileCategoryItem.subItems) {
//            if (resultItem.isSelected == NSControlStateValueOn) {
//                if (resultItem.originPath) {
//                    ++fileCount;
//                } else if (resultItem.path) {
//                    fileCount += [LMFileHelper fileCountAtPath:resultItem.path];
//                }
//            }
//        }
//    }
    
    long long totalFileSize = 0;
    for (LMFileCategoryItem *fileCategoryItem in appCategoryItem.subItems) {
        for (LMResultItem *resultItem in fileCategoryItem.subItems) {
            if (resultItem.selecteState == NSControlStateValueOn) {
                totalFileSize += resultItem.fileSize;
            }
        }
    }
    return [self viewItemWithType:appCategoryItem.type
//                        fileCount:fileCount
                    totalFileSize:totalFileSize];
}

+ (instancetype)viewItemWithType:(LMAppCategoryItemType)type
//                       fileCount:(NSInteger)fileCount
                   totalFileSize:(long long)totalFileSize {
    LMFileMoveProcessCellViewItem *viewItem = [[LMFileMoveProcessCellViewItem alloc] init];
    viewItem.type = type;
//    viewItem.fileCount = fileCount;
    viewItem.totalFileSize = totalFileSize;
    
    switch (type) {
        case LMAppCategoryItemType_WeChat: {
            viewItem.imageName = @"wx_big_icon";
            viewItem.title = LM_LOCALIZED_STRING(@"WeChat");
        }
            break;
        case LMAppCategoryItemType_QQ: {
            viewItem.imageName = @"qq_big_icon";
            viewItem.title = @"QQ";
        }
            break;
        case LMAppCategoryItemType_WeCom: {
            viewItem.imageName = @"wecom_big_icon";
            viewItem.title = LM_LOCALIZED_STRING(@"WeCom");
        }
            break;
    }
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
//    NSString *fileCountString = [NSString stringWithFormat:@"%ld", fileCount];
//    LM_APPEND_ATTRIBUTED_STRING(text, fileCountString, LM_COLOR_YELLOW, 16);
    LM_APPEND_ATTRIBUTED_STRING(text, LM_LOCALIZED_STRING(@"Total "), LM_COLOR_GRAY, 14);
    NSString *fileSizeString = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:totalFileSize];
    LM_APPEND_ATTRIBUTED_STRING(text, fileSizeString, LM_COLOR_YELLOW, 16);
    viewItem.attributedDetail = text;
    
    viewItem.status = LMFileMoveProcessCellStatusPending;
    
    return viewItem;
}

@end
