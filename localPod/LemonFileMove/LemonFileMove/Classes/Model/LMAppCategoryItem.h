//
//  LMAppCategoryItem.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMFileCategoryItem.h"
#import "LMBaseItem.h"

typedef NS_ENUM(NSInteger, LMAppCategoryItemType) {
    LMAppCategoryItemType_WeChat = 0,
    LMAppCategoryItemType_WeCom,
    LMAppCategoryItemType_QQ,
};

NS_ASSUME_NONNULL_BEGIN

@interface LMAppCategoryItem : LMBaseItem

@property (nonatomic, assign) LMAppCategoryItemType type;

@property (nonatomic, strong) NSString *des;

@property (nonatomic, strong) NSString *iconName;

- (instancetype)initWithType:(LMAppCategoryItemType)type;

- (NSControlStateValue)updateSelectState;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
