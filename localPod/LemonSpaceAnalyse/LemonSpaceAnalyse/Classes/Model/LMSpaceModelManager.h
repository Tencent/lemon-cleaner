//
//  LMSpaceModelManager.h
//  LemonSpaceAnalyse
//
//  
//

#import <Foundation/Foundation.h>
#import "LMSpaceModel.h"

@interface LMSpaceModelManager : NSObject

@property(nonatomic, strong) LMSpaceModel *itemModel;
@property(nonatomic, strong) LMSpaceModel *itemModelOne;
@property(nonatomic, strong) LMSpaceModel *itemModelTwo;
@property(nonatomic, strong) LMSpaceModel *itemModelThree;

+ (LMSpaceModelManager *)sharedManger;
- (void)itemModelNeedInit;

@end

