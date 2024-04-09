//
//  LMFileAttributesTool.m
//  LemonFileManager
//

//

#import "LMFileAttributesTool.h"
#import <sys/stat.h>

#define MINBLOCK 4096

static NSTimeInterval kTimeout = 30;

/// 0 未隐藏，-1错误、其他值隐藏
int isFileHidden(const char *path) {
    struct stat attrib;

    if (stat(path, &attrib) == 0) {
        return attrib.st_flags & UF_HIDDEN;
    }

    return -1;
}

@implementation LMFileAttributesTool

static NSMutableDictionary * m_cachePathDict = nil;

+ (uint64)caluactionSize:(NSString *)path diskMode:(BOOL)diskMode {
    return [self caluactionSize:path associatedItem:nil diskMode:diskMode];
}

+ (uint64)caluactionSize:(NSString *)path associatedItem:(nullable __kindof LMFileAttributesBaseItem *)associatedItem diskMode:(BOOL)diskMode
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return 0;
    uint64 fileSize = 0;
    
    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) == noErr)
    {
        if (fileStat.st_mode & S_IFDIR){
            // 通过spotlight快速获取文件夹size。可以过滤一部分kMDItemContentTypeTree包含"com.apple.package"，一般来说该类型路径相结构相对复杂点
            NSMetadataItem *metadataItem = [[NSMetadataItem alloc] initWithURL:[NSURL fileURLWithPath:path]];
            fileSize = [[metadataItem valueForAttribute:@"kMDItemPhysicalSize"] unsignedLongLongValue];
            if (fileSize == 0) {
                fileSize = [self fastFolderSizeAtFSRef:path associatedItem:associatedItem diskMode:diskMode];
            }
        } else {
            if (diskMode && fileStat.st_blocks != 0) {
                fileSize += fileStat.st_blocks * 512;
            } else {
                fileSize += fileStat.st_size;
            }
        }
    }
    return fileSize;
}

+ (unsigned long long)fastFolderSizeAtFSRef:(NSString*)path associatedItem:(nullable __kindof LMFileAttributesBaseItem *)item diskMode:(BOOL)diskMode
{
    BOOL setTimeout = ![self isContainedInTimeoutWhitelist:path];
    
    __block BOOL timeout = NO;
    if (setTimeout) {
        // 使用该方式相比直接在遍历中获取时间戳再计算，消耗时间和性能更少。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            timeout = YES;
        });
    }
    
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
                if ([item isKindOfClass:LMFileAttributesCleanItem.class]) {
                    LMFileAttributesCleanItem *cleanItem = (LMFileAttributesCleanItem *)item;
                    BOOL isStopScan = NO;
                    if (cleanItem.isStopped) {
                        isStopScan = cleanItem.isStopped(resultPath);
                    }
                    if (isStopScan) {
                        break;
                    }
                }
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
            
            if (timeout) {
                break;
            }
        }
    }
    return totalSize;
}

// 判断隐藏文件
+ (BOOL)isHiddenItemForPath:(NSString *)path
{
     if ([[path lastPathComponent] hasPrefix:@"."])
         return YES;
     
     int result = isFileHidden(path.UTF8String);
     BOOL isHidden = (result != 0 && result != -1);
     
     return isHidden;
}

// 正则比较
+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str
{
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [regex evaluateWithObject:str];
}

#pragma mark - 私有方法
/// 清理配置项中配置的路径，文件可能较大，要求完全扫描结束。
+ (BOOL)isContainedInTimeoutWhitelist:(NSString *)path {
    NSArray *whitelist = @[
        @"~/Library/Developer/CoreSimulator", // 模拟器文件
    ];
    if ([whitelist containsObject:path]) {
        return YES;
    }
    
    NSArray *whitelistRegex = @[
        @"/Library/Developer/CoreSimulator/Volumes/(.+)/Library/Developer/CoreSimulator/Profiles/Runtimes/(.+)", // 挂载的模拟器运行时文件
        @"/Library/Developer/CoreSimulator/Profiles/Runtimes/(.+)", //未挂载的模拟器运行时文件
        @"~/Library/Developer/Xcode/DerivedData/(.+)", // 编译和构建过程中的文件
    ];
    for (NSString *regexPattern in whitelistRegex) {
        if ([self assertRegex:regexPattern matchStr:path]) {
            return YES;
        }
    }
    return NO;
}

@end
