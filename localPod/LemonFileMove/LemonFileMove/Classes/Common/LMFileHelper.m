//
//  LMFileHelper.m
//  LemonFileMove
//
//  
//

#import "LMFileHelper.h"
#import "QMShellExcuteHelper.h"
#import "QMFMCleanUtils.h"

@interface LMFileHelper ()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) long long targetFileSize;
@property (nonatomic, strong) NSString *targetFilePath;
@property (nonatomic, strong) LMFileHelperMoveProgressHandler moveProgressHandler;

@end

@implementation LMFileHelper

+ (instancetype)defaultHelper {
    static LMFileHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[[self class] alloc] init];
    });
    return helper;
}

- (instancetype)init {
    if (self = [super init]) {
        self.queue = dispatch_queue_create("com.tencent.lemonFileMoveHelper", 0);
    }
    return self;
}

+ (NSString *)legalFilePath:(NSString *)originFilePath {
    NSInteger i = 1;
    NSString *resultPath = originFilePath; // .../柠檬清理_文件搬家/1.mp4
    while ([self fileExistsAtPath:resultPath]) {
        // 名字后添加 "(n)"
        NSString *lastPathComponent = [originFilePath lastPathComponent]; // 1.mp4
        NSString *pathExtension = [originFilePath pathExtension];   // mp4
        NSString *fileName = nil;
        if (pathExtension.length > 0) {
            fileName = [NSString stringWithFormat:@"%@(%ld).%@", [lastPathComponent stringByDeletingPathExtension], i, pathExtension]; // 1(1).mp4
        } else {
            fileName = [NSString stringWithFormat:@"%@(%ld)", [lastPathComponent stringByDeletingPathExtension], i]; // 1(1)
        }
        
        resultPath = [originFilePath stringByDeletingLastPathComponent]; // .../柠檬清理_文件搬家
        resultPath = [resultPath stringByAppendingPathComponent:fileName]; // .../柠檬清理_文件搬家/1(1).mp4
        ++i;
    }
    return resultPath;
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(nullable BOOL *)isDirectory {
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:isDirectory];
}

+ (NSString *)directoryAtPath:(NSString *)path {
    return [path stringByDeletingLastPathComponent];
}

+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isSuccess = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
    return isSuccess;
}

+ (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (NSInteger)fileCountAtPath:(NSString *)path {
    NSString *cmd = [NSString stringWithFormat:@"find '%@' -type f | wc -l", path];
    NSString *fileCount = [QMShellExcuteHelper excuteCmd:cmd];
    return [fileCount integerValue];
}

+ (BOOL)isEmptyDirectory:(NSString *)path filterHiddenItem:(BOOL)filterHiddenItem isDirectory:(nullable BOOL *)isDirectory {
    if (![self fileExistsAtPath:path isDirectory:isDirectory]) {
        return NO;
    }
    if (!isDirectory) {
        return NO;
    }
    
    NSMutableArray *dirArray = [NSMutableArray arrayWithObject:path];
    // 遍历文件夹下的所有文件
    while (dirArray.count > 0) {
        NSString *dirPath = dirArray[0];
        [dirArray removeObjectAtIndex:0];

        NSError *error = nil;
        NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
        for (NSString *path in paths) {
            NSString *tempPath = [dirPath stringByAppendingPathComponent:path];
            BOOL isTempPathDirectory = NO;
            if ([self fileExistsAtPath:tempPath isDirectory:&isTempPathDirectory] && isTempPathDirectory) {
                // 文件夹，继续遍历
                [dirArray addObject:tempPath];
            } else {
                if (filterHiddenItem && [QMFMCleanUtils isHiddenItemForPath:tempPath]) {
                    // 无视隐藏文件
                } else {
                    // 确实有普通文件，返回NO
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

+ (long long)sizeForFilePath:(NSString *)filePath {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        return [self sizeForFilePath:filePath isDirectory:isDirectory];
    } else {
        return 0;
    }
}

+ (long long)sizeForFilePath:(NSString *)filePath isDirectory:(BOOL)isDirectory {
    if (isDirectory) {
        return [QMFMCleanUtils caluactionSize:filePath];
    } else {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        return [fileSize longLongValue];
    }
}

#pragma mark - 移动文件(夹)

- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath error:(NSError *__autoreleasing  _Nullable * _Nullable)error moveProgressHandler:(nonnull LMFileHelperMoveProgressHandler)moveProgressHandler {
    // 先要保证源文件路径存在，不然抛出异常
    BOOL isDirectory = NO;
    if (![LMFileHelper fileExistsAtPath:path isDirectory:&isDirectory]) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        return NO;
    }
    //获得目标文件的上级目录
    NSString *toDirPath = [LMFileHelper directoryAtPath:toPath];
    if (![LMFileHelper fileExistsAtPath:toDirPath]) {
        // 创建移动路径
        if (![LMFileHelper createDirectoryAtPath:toDirPath error:error]) {
            return NO;
        }
    }
    // 判断目标路径文件是否存在
    if ([LMFileHelper fileExistsAtPath:toPath]) {
        toPath = [LMFileHelper legalFilePath:toPath];
    }
    
    dispatch_async(self.queue, ^{
        self.targetFilePath = toPath;
        self.moveProgressHandler = moveProgressHandler;
        self.targetFileSize = [LMFileHelper sizeForFilePath:path isDirectory:isDirectory];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(checkFileSize)
                                       userInfo:nil
                                        repeats:YES];
        [self.timer fire];
    });

    // 移动文件，当要移动到的文件路径文件存在，会移动失败
#ifdef DEBUG
    BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:path toPath:toPath error:error];
#else
    BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:path toPath:toPath error:error];
#endif
    
    dispatch_async(self.queue, ^{
        self.targetFileSize = 0;
        self.targetFilePath = nil;
        self.moveProgressHandler = nil;
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timer invalidate];
        self.timer = nil;
    });
    
    return isSuccess;
}

- (void)checkFileSize {
    dispatch_async(self.queue, ^{
        long long targetFileSize = [LMFileHelper sizeForFilePath:self.targetFilePath];
        !self.moveProgressHandler ?: self.moveProgressHandler(targetFileSize);
    });
}

@end
