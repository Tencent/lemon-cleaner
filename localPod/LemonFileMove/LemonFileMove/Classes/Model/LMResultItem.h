//
//  LMResultItem.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMBaseItem.h"
#import "LMAppCategoryItem.h"
#import "LMFileCategoryItem.h"
#import "LMFileMoveManger.h"

@interface LMResultItem : LMBaseItem
// 文件路径
@property (nonatomic, strong) NSString *path;
// 实质文件路径
@property (nonatomic, strong) NSString *originPath;

@property (nonatomic, assign) LMAppCategoryItemType appType;
@property (nonatomic, assign) LMFileMoveScanType fileType;

- (NSControlStateValue)updateSelectState;
// self.path 或 self.originPath 有值的一方
- (NSString *)availableFilePath;

@end

