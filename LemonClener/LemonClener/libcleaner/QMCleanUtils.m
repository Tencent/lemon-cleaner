//
//  QMCleanUtils.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMCleanUtils.h"
#import <sys/stat.h>
#import "QMCleanManager.h"
#import <QMCoreFunction/MdlsToolsHelper.h>
#import "QMLiteCleanerManager.h"

#define MINBLOCK 4096

static NSMutableDictionary * m_cachePathDict = nil;

@implementation QMCleanUtils

// get total size by path
+ (uint64)caluactionSize:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return 0;
    uint64 fileSize = 0;
    BOOL diskMode = YES;
    
    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) == noErr)
    {
        if (fileStat.st_mode & S_IFDIR){
            //判断是否是app类型
            NSString *fileName = [path lastPathComponent];
            if ([[fileName pathExtension] isEqualToString:@"app"]) {
//                NSLog(@"path = %@", path);
                //使用mdls 来获取App类型的数据大小
                NSInteger size = [MdlsToolsHelper getAppSizeByPath:path andFileType:@"app"];
                if (size == 0) {
                    fileSize = [self fastFolderSizeAtFSRef:path diskMode:diskMode];
                }else{
                    fileSize = size;
                }
            }else if ([[fileName pathExtension] isEqualToString:@"xcarchive"]){
//                NSLog(@"path = %@", path);
                //使用mdls 来获取App类型的数据大小
                NSInteger size = [MdlsToolsHelper getAppSizeByPath:path andFileType:@"xcarchive"];
                if (size == 0) {
                    fileSize = [self fastFolderSizeAtFSRef:path diskMode:diskMode];
                }else{
                    fileSize = size;
                }
            }else{
                fileSize = [self fastFolderSizeAtFSRef:path diskMode:diskMode];
            }
        }
        else
        {
            if (diskMode && fileStat.st_blocks != 0)
                fileSize += fileStat.st_blocks * 512;
            else
                fileSize += fileStat.st_size;
        }
    }
    return fileSize;
}

+(NSTimeInterval)createTime:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return 0;
    
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
}

+(NSTimeInterval)lastModificateionTime:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return 0;
    
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [[attr objectForKey:NSFileModificationDate] timeIntervalSince1970];
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

+ (unsigned long long) fastFolderSizeAtFSRef:(NSString*)path diskMode:(BOOL)diskMode
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                     includingPropertiesForKeys:nil
                                                        options:0
                                                   errorHandler:nil];
    NSUInteger totalSize = 0;
    NSInteger scanCount = 0;
    for (NSURL * pathURL in dirEnumerator)
    {
        @autoreleasepool
        {
            NSString * resultPath = [pathURL path];
            struct stat fileStat;
            if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)
                continue;
            if (fileStat.st_mode & S_IFDIR)
                continue;
            scanCount++;
            if (scanCount > 100) {
                BOOL isStopScan = NO;
                NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
                if ([bundleId isEqualToString:@"com.tencent.Lemon"] || [bundleId isEqualToString:@"com.tencent.LemonLite"]) {
                    isStopScan = [[QMCleanManager sharedManger] isStopScan];
                }else if([bundleId isEqualToString:@"com.tencent.LemonMonitor"]){
                    isStopScan = [[QMLiteCleanerManager sharedManger] isStopScan];
                }
                if (isStopScan) {
                    break;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([bundleId isEqualToString:@"com.tencent.Lemon"] || [bundleId isEqualToString:@"com.tencent.LemonLite"]) {
                        [[QMCleanManager sharedManger] caculateSizeScanPath:resultPath];
                    }
                });
                scanCount = 0;
            }
            
            if (diskMode)
            {
                if (fileStat.st_flags != 0)
                    totalSize += (((fileStat.st_size +
                                    MINBLOCK - 1) / MINBLOCK) * MINBLOCK);
                else
                    totalSize += fileStat.st_blocks * 512;
                
            }
            else
                totalSize += fileStat.st_size;
            
            if (CFAbsoluteTimeGetCurrent() - startTime > 10)
                break;
        }
    }
    return totalSize;
}


// 正则比较
+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str
{
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [regex evaluateWithObject:str];
}


// 判断隐藏文件
+ (BOOL)isHiddenItemForPath:(NSString *)path
{
    if ([[path lastPathComponent] hasPrefix:@"."])
        return YES;
    
    LSItemInfoRecord itemInfo;
    LSCopyItemInfoForURL((__bridge CFURLRef)([NSURL fileURLWithPath:path]), kLSRequestAllFlags, &itemInfo);
    BOOL isInvisible = itemInfo.flags & kLSItemInfoIsInvisible;
    return isInvisible;
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
                NSDictionary * dict = [fm attributesOfItemAtPath:path error:nil];
                if ([[dict objectForKey:NSFileSize] unsignedIntegerValue] > 0)
                    return NO;
            }
        }
        else
        {
            NSDictionary * dict = [fm attributesOfItemAtPath:path error:nil];
            if ([[dict objectForKey:NSFileSize] unsignedIntegerValue] > 0)
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
    NSError *error;
    NSString *type;
    // 测试文件是否存在，easyconnect 里有一个文件是pipe类型，但属性又是可执行的，open的时候会卡死，这里通过NSURLTypeIdentifierKey测试文件
    // 类型是否为pipe，如果是pipe文件类型，会返回一个NSFileReadNoSuchFileError的error
    [pathURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error];
    if (error && error.code == NSFileReadNoSuchFileError) {
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

@end
