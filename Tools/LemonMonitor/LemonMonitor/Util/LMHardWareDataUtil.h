//
//  LMHardWareDataUtil.h
//  LemonMonitor
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMHardWareDataUtil : NSObject

/// 计算磁盘空间占用情况
/// @param mainDiskName  主磁盘（可以为nil）
/// @param volumnesArray 磁盘数组
/// @param freeBytes 保存可用空间大小
/// @param totalBytes 保存总空间大小
+(void)calculateDiskUsageInfoWithMainDiskName: (NSString *)mainDiskName volumeArray: (NSArray *) volumnesArray freeBytes: (uint64_t *)freeBytes totalBytes: (uint64_t *)totalBytes;
@end

NS_ASSUME_NONNULL_END
