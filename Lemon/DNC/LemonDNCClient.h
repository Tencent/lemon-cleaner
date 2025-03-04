//
//  LemonDNCClient.h
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LemonDNCDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LemonDNCClient : NSObject

+ (instancetype)sharedInstance;

- (void)restart:(LemonDNCRestartType)type reason:(LemonDNCRestartReason)reason;

@end

NS_ASSUME_NONNULL_END
