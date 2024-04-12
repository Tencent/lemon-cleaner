//
//  QMCleanUtils.h
//  QMCleanDemo
//
//

#import <Foundation/Foundation.h>

typedef BOOL (^FinderResultBlock)(NSURL * pathURL);

@interface QMCleanUtils : NSObject

+ (uint64)caluactionSize:(NSString *)path;

+(NSTimeInterval)createTime:(NSString *)filePath;

+(NSTimeInterval)lastModificateionTime:(NSString *)filePath;

+(NSTimeInterval)lastAccessTime:(NSString *)filePath;

+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str;

+ (BOOL)isHiddenItemForPath:(NSString *)path;

+ (BOOL)isEmptyDirectory:(NSString *)path filterHiddenItem:(BOOL)hiddenItem;

+ (BOOL)isBinarySignCode:(NSString *)executablePath;

+ (BOOL)checkURLFileType:(NSURL *)pathURL typeKey:(NSString *)typeKey;

+ (BOOL)contentPathAtPath:(NSString *)path
                  options:(NSDirectoryEnumerationOptions)options
                    level:(int)level
            propertiesKey:(NSArray *)key
                    block:(FinderResultBlock)block;

+ (BOOL)checkQQMacMgrFile:(NSString *)path;

// 缓存扫描路径
+ (void)setScanCacheResult:(NSDictionary *)dict;
+ (NSArray *)cacheResultWithPath:(NSString *)path;
+ (void)cleanScanCacheResult;

+ (NSArray *)processDirTruncatePath:(NSString *)path;

@end
