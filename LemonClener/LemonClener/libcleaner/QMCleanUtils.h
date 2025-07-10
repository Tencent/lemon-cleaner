//
//  QMCleanUtils.h
//  QMCleanDemo
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LMWeChatLocalCacheType) {
    LMWeChatCacheType_None,
    LMWeChatCacheType_Old,              // 老版本微信 3.8.9及以下
    LMWeChatCacheType_V4,               // 微信4.0.3 及以上
    LMWeChatCacheType_Both,             // 微信4. 和  old 缓存都有， 用户可能是3升级到4
};

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

// 获取用户本地微信的缓存类型
+ (LMWeChatLocalCacheType)getUserLocalWeChatCachesType;
// 根据微信4特有的路径判断是否是微信4
+ (BOOL)isWeChat4FromPath:(NSString *)path;
// 判读用户当前系统上是否安装了微信4
+ (BOOL)isCurrentUserInstalledWeChat4;

@end
