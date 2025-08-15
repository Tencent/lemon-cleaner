//
//  NSFileManager+iCloudHelper.h
//  QMCoreFunction
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * NSFileManager的iCloud文件处理扩展
 * 提供安全的iCloud文件检测和目录遍历方法，避免意外触发iCloud文件下载
 */
@interface NSFileManager (iCloudHelper)

/**
 * 检查指定路径是否为iCloud文件或目录
 * @param path 要检查的文件路径
 * @return YES表示是iCloud文件，NO表示是本地文件
 */
- (BOOL)qm_isICloudFileAtPath:(NSString *)path;

/**
 * 检查iCloud文件是否已下载到本地
 * @param path iCloud文件路径
 * @return YES表示已下载，NO表示未下载或不是iCloud文件
 */
- (BOOL)qm_isICloudFileDownloadedAtPath:(NSString *)path;

/**
 * 安全地获取目录内容，避免触发iCloud文件下载
 * 对于iCloud目录，使用URL方式获取内容而不触发下载
 * 对于本地目录，使用标准方式获取内容
 * @param path 目录路径
 * @return 目录中的文件名数组，失败时返回nil
 */
- (nullable NSArray<NSString *> *)qm_safeContentsOfDirectoryAtPath:(NSString *)path;

/**
 * 安全地获取文件属性，避免触发iCloud文件下载
 * @param path 文件路径
 * @return 文件属性字典，失败时返回nil
 */
- (nullable NSDictionary<NSFileAttributeKey, id> *)qm_safeAttributesOfItemAtPath:(NSString *)path;

/**
 * 安全地获取文件大小，避免触发iCloud文件下载
 * @param path 文件路径
 * @return 文件大小（字节），失败时返回0
 */
- (uint64_t)qm_safeFileSizeAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
