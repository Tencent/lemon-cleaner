//
//  LMBaseItem.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMBaseItem : NSObject <NSCopying>

/// LMAppCategoryItem持有<LMFileCategoryItem *>，LMFileCategoryItem持有<LMResultItem *>
@property (nonatomic, strong) NSMutableArray *subItems;

/// 选中状态。Mix为半选，On未全选，Off为未选。最下层的LMResultItem只有On和Off
@property (nonatomic, assign) NSControlStateValue selecteState;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) long long fileSize;

@property (nonatomic, assign) BOOL isMoveFailed;
@property (nonatomic, assign) long long moveFailedFileSize;

- (void)setStateWithSubItemsIfHave:(NSControlStateValue)stateValue;

- (NSControlStateValue)updateSelectState;

@end

NS_ASSUME_NONNULL_END
