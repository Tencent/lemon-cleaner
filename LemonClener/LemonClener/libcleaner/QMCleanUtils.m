//
//  QMCleanUtils.m
//  QMCleanDemo
//
//

#import "QMCleanUtils.h"
#import <sys/stat.h>
#import "QMCleanManager.h"
#import <QMCoreFunction/MdlsToolsHelper.h>
#import "QMLiteCleanerManager.h"
#import <LemonFileManager/LMFileAttributesTool.h>
#import "QMScanFileSizeCacheManager.h"

#define MINBLOCK 4096

#define     p_WeChat_BundleId     @"com.tencent.xinWeChat"
/// 微信新老版本都有的路径
#define     p_WeChat_Common_Path_1    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/Preferences/com.tencent.xinWeChat.plist"
#define     p_WeChat_Common_Path_2    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/Caches/Matrix/AppReboot/AppReboot.dat"
/// 微信老版本特有的路径
#define     p_WeChat_V3_Path_1    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/Caches/com.tencent.xinWeChat/Cache.db"
#define     p_WeChat_V3_Path_2    @"~/Library/Containers/com.tencent.xinWeChat/Data/Library/HTTPStorages/com.tencent.xinWeChat/httpstorages.sqlite"
/// 微信新版本特有的路径
#define     p_WeChat_V4_Path_1    @"~/Library/Containers/com.tencent.xinWeChat/Data/Documents/app_data/lock/lock.ini"
#define     p_WeChat_V4_Path_2    @"~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/all_users/config/global_config.crc"
/// 微信4缓存路径必定包含的字符串片段
#define     p_WeChat_V4_Parts_Of_Protect_Data_Path    @"/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files"

#pragma mark - for performance

time_t getFileCreationTime(const char *path) {
    struct stat attrib;
    
    if (stat(path, &attrib) == 0) {
        // 1970 年 1 月 1 日 00:00:00 开始的秒数
        return attrib.st_birthtime;
    }
    
    return -1;
}

time_t getFileModificationTime(const char *path) {
    struct stat attrib;
    
    if (stat(path, &attrib) == 0) {
        // 1970 年 1 月 1 日 00:00:00 开始的秒数
        return attrib.st_mtime;
    }
    
    return -1;
}

off_t getFileSize(const char *path) {
    struct stat attrib;

    if (stat(path, &attrib) == 0) {
        return attrib.st_size;
    }

    return -1;
}

BOOL isPipe(const char *path) {
    struct stat fileStat;
    if (stat(path, &fileStat) == 0) {
        if (S_ISFIFO(fileStat.st_mode)) {
            // isPipe
            return YES;
        }
    }
    return NO;
}

static NSMutableDictionary * m_cachePathDict = nil;

@implementation QMCleanUtils

// get total size by path
+ (uint64)caluactionSize:(NSString *)path
{
    QMScanFileSizeCacheManager *manager = [QMScanFileSizeCacheManager manager];
    if ([manager hasCachedFileSizeWithPath:path]) {
        return [manager getCachedFileSizeWithPath:path];
    }
    LMFileAttributesCleanItem *associatedItem = [[LMFileAttributesCleanItem alloc] init];
    associatedItem.isStopped = ^BOOL(NSString * _Nonnull path) {
        BOOL isStopScan = NO;
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleId isEqualToString:@"com.tencent.Lemon"] || [bundleId isEqualToString:@"com.tencent.LemonLite"]) {
            isStopScan = [[QMCleanManager sharedManger] isStopScan];
        }else if([bundleId isEqualToString:@"com.tencent.LemonMonitor"]){
            isStopScan = [[QMLiteCleanerManager sharedManger] isStopScan];
        }
        if (isStopScan) {
            return YES;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([bundleId isEqualToString:@"com.tencent.Lemon"] || [bundleId isEqualToString:@"com.tencent.LemonLite"]) {
                [[QMCleanManager sharedManger] caculateSizeScanPath:path];
            }
        });
        return NO;
    };
    uint64 fileSize = [LMFileAttributesTool caluactionSize:path associatedItem:associatedItem diskMode:YES];
    [manager cacheFileAtPath:path withSize:fileSize];
    return fileSize;
}

+(NSTimeInterval)createTime:(NSString *)filePath
{
    return (NSTimeInterval)getFileCreationTime(filePath.UTF8String);
}

+(NSTimeInterval)lastModificateionTime:(NSString *)filePath
{
    return (NSTimeInterval)getFileModificationTime(filePath.UTF8String);
}

+(NSTimeInterval)lastAccessTime:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return 0;
    
    struct stat output;
    int ret = lstat([filePath UTF8String], &output);
    if (ret)
        return 0;
    struct timespec accessTime = output.st_atimespec;
    return accessTime.tv_sec;
}

// 正则比较
+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str
{
    return [LMFileAttributesTool assertRegex:regexString matchStr:str];
}


// 判断隐藏文件
+ (BOOL)isHiddenItemForPath:(NSString *)path
{
    return [LMFileAttributesTool isHiddenItemForPath:path];
}

// 检查是否是空目录/文件
+ (BOOL)isEmptyDirectory:(NSString *)path filterHiddenItem:(BOOL)hiddenItem
{
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:path isDirectory:&isDir])
    {
        if (isDir)
        {
            NSDirectoryEnumerator * _pathEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                               includingPropertiesForKeys:nil
                                                                  options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                             errorHandler:nil];
            while (YES)
            {
                NSURL * curObject = [_pathEnumerator nextObject];
                if (curObject == nil)
                    break;
                if (!hiddenItem && [QMCleanUtils isHiddenItemForPath:path])
                    continue;
                if (getFileSize(path.UTF8String) > 0) 
                {
                    return NO;
                }
            }
        }
        else if (getFileSize(path.UTF8String) > 0)
        {
            return NO;
        }
    }
    return YES;
}

// 检查二进制是否签名
+ (BOOL)isBinarySignCode:(NSString *)executablePath
{
    SecStaticCodeRef ref = nil;
    NSURL * url = [NSURL fileURLWithPath:executablePath];
    
    OSStatus status;
    status = SecStaticCodeCreateWithPath((__bridge CFURLRef)url, kSecCSDefaultFlags, &ref);
    
    if (ref == nil) return NO;
    if (status != noErr)
    {
        CFRelease(ref);
        return NO;
    }
    
    SecRequirementRef req = nil;
    status = SecCodeCopyDesignatedRequirement(ref, kSecCSDefaultFlags, &req);
    
    if (req == nil)
    {
        CFRelease(ref);
        return NO;
    }
    if (status != noErr)
    {
        CFRelease(req);
        CFRelease(ref);
        return NO;
    }
    CFRelease(req);
    CFRelease(ref);
    return YES;
}

// 过滤自身产生的日志和缓存
+ (BOOL)checkQQMacMgrFile:(NSString *)path
{
    NSString * fileName = [path lastPathComponent];
    if ([path containsString:@"/.Trash"]) {
        return NO;
    }
    if ([fileName isEqualToString:@"com.tencent.Lemon"]
        || [fileName isEqualToString:@"com.tencent.LemonMonitor"] || [fileName isEqualToString:@"com.tencent.LemonLite"])
        return YES;
    if ([fileName hasPrefix:@"Tencent Lemon"]){
        return YES;
    }
    if ([fileName hasPrefix:@"LemonMonitor"])
        return YES;
    if ([fileName hasPrefix:@"LemonDaemon"])
        return YES;
    if ([fileName hasPrefix:@"LemonLite"])
        return YES;
    return NO;
}

// 判断是否替身文件
+ (BOOL)checkURLFileType:(NSURL *)pathURL typeKey:(NSString *)typeKey
{
    
//    NSError *error;
//    NSString *type;
//    // 测试文件是否存在，easyconnect 里有一个文件是pipe类型，但属性又是可执行的，open的时候会卡死，这里通过NSURLTypeIdentifierKey测试文件
//    // 类型是否为pipe，如果是pipe文件类型，会返回一个NSFileReadNoSuchFileError的error
//    [pathURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error];
//    if (error && error.code == NSFileReadNoSuchFileError) {
//        return NO;
//    }
    
    // 代替旧方案的原因是在macos 14.3上，旧方案耗时增加了，影响到扫描。
    // 新方案耗时回归到原有的水平
    // 旧： 0.000x
    // 新： 0.00000x
    if (isPipe(pathURL.absoluteString.UTF8String)) {
        return NO;
    }
    
    
    NSNumber * result = nil;
    [pathURL getResourceValue:&result forKey:typeKey error:NULL];
    if (result && [result boolValue])
        return YES;
    else
        return NO;
}


+ (BOOL)contentPathAtPath:(NSString *)path
                       options:(NSDirectoryEnumerationOptions)options
                         level:(int)level
                 propertiesKey:(NSArray *)key
                         block:(FinderResultBlock)block
{
    if (!block) return NO;
    NSDirectoryEnumerator * dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:path]
                                                                 includingPropertiesForKeys:key
                                                                                    options:options
                                                                               errorHandler:nil];
    for (NSURL * pathURL in dirEnumerator)
    {
        // 过滤快捷方式
        if ([QMCleanUtils checkURLFileType:pathURL typeKey:NSURLIsAliasFileKey])
            continue;
        
        if (level != -1 && [dirEnumerator level] == level)
            [dirEnumerator skipDescendants];
        if (block(pathURL))
            return NO;
    }
    return YES;
}

+ (void)setScanCacheResult:(NSDictionary *)dict
{
    if (!m_cachePathDict) m_cachePathDict = [NSMutableDictionary dictionary];
    [m_cachePathDict addEntriesFromDictionary:dict];
}

+ (NSArray *)cacheResultWithPath:(NSString *)path
{
    return [m_cachePathDict objectForKey:path];
}

+ (void)cleanScanCacheResult
{
    [m_cachePathDict removeAllObjects];
    m_cachePathDict = nil;
}

+ (NSArray *)processDirTruncatePath:(NSString *)path
{
    // 如果置空
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
    {
        NSMutableArray * resultPathArray = [NSMutableArray array];
        NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                         includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, nil]
                                                            options:0
                                                       errorHandler:nil];
        for (NSURL * pathURL in dirEnumerator)
        {
            // 处理目录
            NSNumber *isDir = nil;
            [pathURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];
            if ((isDir != nil) && [isDir boolValue])
                continue;
            
            // 添加结果
            NSString * resultPath = [pathURL path];
            [resultPathArray addObject:resultPath];
        }
        return resultPathArray;
    }
    else
    {
        return nil;
    }
}

#pragma mark - 判断区分用户电脑上是否安装过老版本（3）、或者只有新版本（4），或者3和4的 缓存都有

+ (LMWeChatLocalCacheType)getUserLocalWeChatCachesType {
    BOOL hasWeChatCaches = NO;
    NSString * commonPath1 = [p_WeChat_Common_Path_1 stringByExpandingTildeInPath];
    NSString * commonPath2 = [p_WeChat_Common_Path_2 stringByExpandingTildeInPath];
    if ([NSFileManager.defaultManager fileExistsAtPath:commonPath1] ||
        [NSFileManager.defaultManager fileExistsAtPath:commonPath2]) {
        hasWeChatCaches = YES;
    }

    // 老版本特有
    NSString *v3Path1 = [p_WeChat_V3_Path_1 stringByExpandingTildeInPath];
    NSString *v3Path2 = [p_WeChat_V3_Path_2 stringByExpandingTildeInPath];
    
    BOOL hasV3Caches = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:v3Path1] ||
        [NSFileManager.defaultManager fileExistsAtPath:v3Path2]) {
        hasV3Caches = YES;
    }

    // 4以上版本特有
    NSString *v4Path1 = [p_WeChat_V4_Path_1 stringByExpandingTildeInPath];
    NSString *v4Path2 = [p_WeChat_V4_Path_2 stringByExpandingTildeInPath];
    
    BOOL hasV4Caches = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:v4Path1] ||
        [NSFileManager.defaultManager fileExistsAtPath:v4Path2]) {
        hasV4Caches = YES;
    }
    
    if (!hasWeChatCaches) {
        return LMWeChatCacheType_None;
    }
    if (hasV3Caches && hasV4Caches) {
        return LMWeChatCacheType_Both;
    }
    return hasV4Caches ? LMWeChatCacheType_V4 : LMWeChatCacheType_Old;
}

+ (BOOL)isWeChat4FromPath:(NSString *)path {
    path = [path stringByExpandingTildeInPath];
    if ([path containsString:p_WeChat_V4_Parts_Of_Protect_Data_Path]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCurrentUserInstalledWeChat4 {
    // 获取微信Bundle ID
    NSString *weChatBundleID = p_WeChat_BundleId;

    // 获取微信版本号
    NSBundle *weChatBundle = [NSBundle bundleWithIdentifier:weChatBundleID];
    
    // 没有安装
    if (!weChatBundle) {
        return NO;
    }
    
    NSString *versionString = [weChatBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSLog(@"wechat version : %@", versionString);
    
    // 解析版本号
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    if (versionComponents.count < 3) {
        NSLog(@"version format invalide : %@", versionString);
        return NO;
    }
    
    // 转换为数值比较
    NSInteger major = [versionComponents[0] integerValue];
    
    return (major >= 4);
}

@end
