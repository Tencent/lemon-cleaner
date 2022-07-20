//
//  QMDataCache.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMDataCache : NSObject

+ (QMDataCache *)sharedCache;

- (NSData *)dataForKey:(NSString *)aKey;
- (void)setData:(NSData *)data forKey:(NSString *)aKey;

@end
