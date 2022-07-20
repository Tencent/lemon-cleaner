//
//  NSFileManager+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSFileManager+Extension.h"
#import <sys/stat.h>

@implementation NSFileManager(FileSize)


- (uint64_t)fileSizeAtPath:(NSString *)filePath
{
    return [self sizeAtPath:filePath diskMode:NO];
}

- (uint64_t)diskSizeAtPath:(NSString *)filePath
{
    return [self sizeAtPath:filePath diskMode:YES];
}

/*
 改进版,优化内存,提升速度
 */
- (uint64_t)sizeAtPath:(NSString *)filePath diskMode:(BOOL)diskMode
{
    uint64_t totalSize = 0;
    uint64_t limitCount = 0;
    
    NSMutableArray *searchPaths = [NSMutableArray arrayWithObject:filePath];
    while ([searchPaths count] > 0)
    {
        @autoreleasepool
        {
            //此处的fileName可能已经是一个子路径了
            NSString *fullPath = [searchPaths objectAtIndex:0];
            [searchPaths removeObjectAtIndex:0];
            
            struct stat fileStat;
            if (lstat([fullPath fileSystemRepresentation], &fileStat) == 0)
            {
                if (fileStat.st_mode & S_IFDIR)
                {
                    NSArray *childSubPaths = [self contentsOfDirectoryAtPath:fullPath error:nil];
                    for (NSString *childItem in childSubPaths)
                    {
                        NSString *childPath = [fullPath stringByAppendingPathComponent:childItem];
                        [searchPaths insertObject:childPath atIndex:0];
                    }
                }else
                {
                    if (diskMode)
                        totalSize += fileStat.st_blocks*512;
                    else
                        totalSize += fileStat.st_size;
                }
            }
        }
    }
    
    return totalSize;
}

/*
- (uint64_t)sizeAtPath:(NSString *)filePath diskMode:(BOOL)diskMode
{
    uint64_t totalSize = 0;
    
    NSMutableArray *searchPaths = [NSMutableArray arrayWithObject:@""];
    for (int i=0; i<[searchPaths count]; i++)
    {
        //此处的fileName可能已经是一个子路径了
        NSString *fileName = [searchPaths objectAtIndex:i];
        NSString *fullPath = [filePath stringByAppendingPathComponent:fileName];
        
        struct stat fileStat;
        if (lstat([fullPath fileSystemRepresentation], &fileStat) != 0)
        {
            continue;
        }
        
        if (fileStat.st_mode & S_IFDIR)
        {
            NSArray *childSubPaths = [self contentsOfDirectoryAtPath:fullPath error:nil];
            for (NSString *childItem in childSubPaths)
            {
                NSString *childPath = [fileName stringByAppendingPathComponent:childItem];
                [searchPaths addObject:childPath];
            }
            continue;
        }
        
        if (diskMode)
            totalSize += fileStat.st_blocks*512;
        else
            totalSize += fileStat.st_size;
    }
    
    return totalSize;
}
 */

@end
