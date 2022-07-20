//
//  LMKextManager.h
//  LemonDaemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McPipeStruct.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMKextManager : NSObject

+ (NSInteger)uninstallKextWithBundleId:(mc_pipe_cmd *)pcmd;

+ (NSInteger)uninstallKextWithPath:(mc_pipe_cmd *)pcmd;

@end

NS_ASSUME_NONNULL_END
