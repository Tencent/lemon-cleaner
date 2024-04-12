//
//  LMFileAttributesTool.m
//  LemonFileManager
//

//

#import "LMFileAttributesTool.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>

@implementation LMFileAttributesTool

+ (unsigned long long)lmFastFolderSizeAtFSRef:(NSString*)path diskMode:(BOOL)diskMode
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                     includingPropertiesForKeys:nil
                                                        options:0
                                                   errorHandler:nil];
    NSUInteger totalSize = 0;
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
            
            if (diskMode)
            {
                if (fileStat.st_flags != 0)
                    totalSize += (((fileStat.st_size + 4096 - 1) / 4096) * 4096);
                else
                    totalSize += fileStat.st_blocks * 512;
            }
            else
                totalSize += fileStat.st_size;
            
            // 5.1.7 超时时间先由原来10秒改为30秒，大文件超过30秒的还是会有问题，需要后续优化
            if (CFAbsoluteTimeGetCurrent() - startTime > 30)
                break;
        }
    }
    return totalSize;
}

@end
