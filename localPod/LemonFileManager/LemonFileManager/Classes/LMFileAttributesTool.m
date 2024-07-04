//
//  LMFileAttributesTool.m
//  LemonFileManager
//

//

#import "LMFileAttributesTool.h"
#import <sys/stat.h>
#import <sys/dirent.h>

/** https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/stat.2.html
 st_blocks      The actual number of blocks allocated for the file in
                     512-byte units.  As short symbolic links are stored in the
                     inode, this number may be zero.
 **/
#define PHYSICAL_BLOCK 512

// 模拟器文件
#define LMFCoreSimulatorHomePath @"/Library/Developer/CoreSimulator"
// 编译和构建过程中的文件
#define LMFDerivedDataHomePath @"/Library/Developer/Xcode/DerivedData/(.+)"
// 挂载的模拟器运行时文件
#define LMFLoadCoreSimulatorRuntimesPath @"/Library/Developer/CoreSimulator/Volumes/(.+)/Library/Developer/CoreSimulator/Profiles/Runtimes/(.+)"
//未挂载的模拟器运行时文件
#define LMFUnloadCoreSimulatorRuntimesPath @"/Library/Developer/CoreSimulator/Profiles/Runtimes/(.+)"

static NSTimeInterval kTimeout = 10;

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
        if (S_ISDIR(fileStat.st_mode)){
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
    // 一般来说该判断放在调用处更合适
    BOOL setTimeout = ![self isContainedInTimeoutWhitelist:path];
    
    __block BOOL timeout = NO;
    if (setTimeout) {
        static dispatch_queue_t serialQueue = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            serialQueue = dispatch_queue_create("com.lemonClean.fileSize", DISPATCH_QUEUE_SERIAL);
        });
        // 使用该方式相比直接在遍历中获取时间戳再计算，消耗时间和性能更少。
        // 使用子线程是为了避免影响dispatch_async(dispatch_get_main_queue(), ^{})
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeout * NSEC_PER_SEC)), serialQueue, ^{
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
    for (NSURL *pathURL in dirEnumerator) {
        @autoreleasepool {
            NSString * resultPath = [pathURL path];
            struct stat fileStat;
            if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)
                continue;
            if (S_ISLNK(fileStat.st_mode) || S_ISDIR(fileStat.st_mode)) { // 软连接 || 目录
                // 不占用磁盘扇形空间st_blocks，仅存在inode中
                if (!diskMode) {
                    // 获取文件大小时则需要计算。计算占用磁盘空间则不需要。
                    totalSize += fileStat.st_size;
                }
                continue;
            }
                
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
            
            if (diskMode) {
                totalSize += fileStat.st_blocks * PHYSICAL_BLOCK;
            } else {
                totalSize += fileStat.st_size;
            }
            
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
    
    static NSArray *whitelist = nil;
    static NSArray *whitelistRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *coreSimulator_path = [NSHomeDirectory() stringByAppendingString:LMFCoreSimulatorHomePath];
        if (coreSimulator_path) {
            whitelist = @[coreSimulator_path];
        }
        
        NSString *derivedData_path = [NSHomeDirectory() stringByAppendingString:LMFDerivedDataHomePath];
        if (derivedData_path) {
            whitelistRegex = @[
                LMFLoadCoreSimulatorRuntimesPath,
                LMFUnloadCoreSimulatorRuntimesPath,
                derivedData_path, // 编译和构建过程中的文件
            ];
        } else {
            whitelistRegex = @[
                LMFLoadCoreSimulatorRuntimesPath,
                LMFUnloadCoreSimulatorRuntimesPath,
            ];
        }
    });
    
    if ([whitelist containsObject:path]) {
        return YES;
    }
    
    for (NSString *regexPattern in whitelistRegex) {
        if ([self assertRegex:regexPattern matchStr:path]) {
            return YES;
        }
    }
    return NO;
}

@end
