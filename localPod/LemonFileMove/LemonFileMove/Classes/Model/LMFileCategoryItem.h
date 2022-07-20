//
//  LMFileCategoryItem.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMBaseItem.h"

typedef NS_ENUM(NSInteger, LMFileCategoryItemType) {
    LMFileCategoryItemType_File90Before  = 0,
    LMFileCategoryItemType_File90        = 1,
    LMFileCategoryItemType_Image90Before = 2,
    LMFileCategoryItemType_Image90       = 3,
    LMFileCategoryItemType_Video90Before = 4,
    LMFileCategoryItemType_Video90       = 5
};

NS_ASSUME_NONNULL_BEGIN

@interface LMFileCategoryItem : LMBaseItem

@property (nonatomic, assign) LMFileCategoryItemType type;

@property (nonatomic, strong) NSString *iconName;

- (instancetype)initWithType:(LMFileCategoryItemType)type;

- (NSControlStateValue)updateSelectState;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
