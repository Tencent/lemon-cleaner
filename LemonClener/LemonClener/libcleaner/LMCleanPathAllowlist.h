//
//  LMCleanPathAllowlist.h
//  LemonClener
//
//  清理扫描路径白名单：从当前内存内置规则导出前缀，
//  再加上当前用户 home 与当前用户的 SystemTempDir 根。
//

#import <Foundation/Foundation.h>

@class QMResultItem;

@interface LMCleanPathAllowlist : NSObject

+ (void)rebuildFromCategoryDict:(NSDictionary *)categoryDict;

/// 最近一次 rebuild 写入的当前用户 home（规范化后）。未 rebuild 时为 nil。
+ (NSString *)homePrefix;

/// 最近一次 rebuild 写入的 SystemTempDir 根（`NSTemporaryDirectory()` 上一级再拼 `C`，规范化后）。未 rebuild 时为 nil。
+ (NSString *)systemTempDirRootPrefix;

/// 非绝对路径一律放行（如损坏登录项的 displayName）。
/// 绝对路径须落在 home ∪ SystemTempDir 根 ∪ 内置导出前缀。
+ (BOOL)isAbsolutePathAllowed:(NSString *)path;

/// 扫描丢弃路径的限流日志：同一父目录只打一次，避免 27 系统上逐文件 NSLog 打满 CPU。
+ (void)logRejectedScanPath:(NSString *)path;

/// 扫描结果里不在名单内的绝对路径（规范化后）。
/// outSize 可选，累加含名单外路径的 item 大小（每个 item 只计一次）。
+ (NSArray<NSString *> *)disallowedAbsolutePathsInResultDict:(NSDictionary *)resultDict
                                                     totalSize:(NSUInteger *)outSize;

+ (BOOL)resultItemHasDisallowedAbsolutePath:(QMResultItem *)item;

@end
