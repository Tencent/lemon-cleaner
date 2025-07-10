//
//  LMLoopTriggerCallbackObject.h
//  QMCoreFunction
//
//

#import <Foundation/Foundation.h>
#import "LMLoopTrigger.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMLoopTriggerCallbackObject : NSObject

@property (nonatomic) LMLoopTriggerRunModes runModes;

@property (nonatomic, copy) dispatch_block_t callback;

@end

NS_ASSUME_NONNULL_END
