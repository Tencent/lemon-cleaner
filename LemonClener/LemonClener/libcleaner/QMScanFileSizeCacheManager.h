//
//  QMScanFileSizeCacheManager.h
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 扫描时计算文件（夹）大小优化
@interface QMScanFileSizeCacheManager : NSObject

+ (QMScanFileSizeCacheManager *)manager;

// 本次扫描开始
- (void)start;
// 本次扫描结束。缓存设置为无效
- (void)end;

- (BOOL)hasCachedFileSizeWithPath:(NSString *)path;
- (unsigned long long)getCachedFileSizeWithPath:(NSString *)path;
- (BOOL)cacheFileAtPath:(NSString *)path withSize:(unsigned long long)size;



@end

NS_ASSUME_NONNULL_END
