//
//  LemonDNCServier.h
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LemonDNCServier : NSObject

+ (instancetype)sharedInstance;

- (void)addServer;

@end

NS_ASSUME_NONNULL_END
