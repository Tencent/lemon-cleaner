//
//  LMSpaceModel.h
//  LemonSpaceAnalyse
//
//  
//

#import <Foundation/Foundation.h>
#import "LMItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMSpaceModel : NSObject

@property(nonatomic, strong) LMItem *topItem;
@property(nonatomic, strong) LMItem *currentItem;
@property(nonatomic, strong) NSMutableArray *currentItems;
@property(nonatomic, strong) NSMutableArray *currentChildItms;
@property(nonatomic, strong) NSMutableArray *remindItems;
@end

NS_ASSUME_NONNULL_END
