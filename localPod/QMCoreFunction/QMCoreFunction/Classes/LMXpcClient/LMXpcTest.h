//
//  LMXpcTest.h
//  QMCoreFunction
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McCoreFunction.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMXpcTest : NSObject

-(void) testXpcSyncInSingleThread;
-(void) testXpcSyncInMultiThreads;

@end

NS_ASSUME_NONNULL_END
