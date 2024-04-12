//
//  LMPhotoFileScanManager.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "LMPhotoFileScanManager.h"
#include <fts.h>
#include <err.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/attr.h>
#import <LemonFileManager/LMFileAttributesTool.h>

@implementation LMPhotoFileItem

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@  %lld", _filePath, _fileSize];
}


- (void)addChildrenItem:(LMPhotoFileItem *)item
{
    if (!_childrenItemArray) _childrenItemArray = [[NSMutableArray alloc] init];
    [_childrenItemArray addObject:item];
}
- (NSArray *)childrenItemArray
{
    return _childrenItemArray;
}

@end

@interface LMPhotoFileScanManager()
{
    NSArray * _excludeArray;
}
@end

@implementation LMPhotoFileScanManager


#define MINBLOCK 4096

const float kMaxSearchProgress = 0.2f;

#define kProtectArray @[[@"~/Library/" stringByExpandingTildeInPath], @"/Library", @"/System", @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",[@"~/.Trash/" stringByExpandingTildeInPath]]

- (id)init
{
    if (self = [super init])
    {
        _excludeArray = @[[@"~/Library/" stringByExpandingTildeInPath], @"/Library", @"/System",
                          @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",
                          [@"~/.Trash/" stringByExpandingTildeInPath]];
    }
    return self;
}

+ (instancetype)sharedManager
{
    static LMPhotoFileScanManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance)
            instance = [[LMPhotoFileScanManager alloc] init];
    });
    return instance;
}


- (NSUInteger)pathLevel:(NSString *)path
{
    return [[path componentsSeparatedByString:@"/"] count];
}


- (NSArray *)protectedFolderArray
{
    return _excludeArray;
}

// 判断隐藏文件
- (BOOL)isHiddenItemForPath:(NSString *)path
{
    if ([[path lastPathComponent] hasPrefix:@"."])
        return YES;
    
    LSItemInfoRecord itemInfo;
    LSCopyItemInfoForURL((__bridge CFURLRef)([NSURL fileURLWithPath:path]), kLSRequestAllFlags, &itemInfo);
    BOOL isInvisible = itemInfo.flags & kLSItemInfoIsInvisible;
    return isInvisible;
}

- (void)listPathContent:(NSArray *)paths
           excludeArray:(NSArray *)array
               delegate:(id<LMPhotoFileScanManagerDelegate>)delegate
{
    NSMutableArray * pathArray = [NSMutableArray array];
    for (NSString * path in paths)
    {
        BOOL flags = NO;
        for (NSString * comparePath in paths)
        {
            if (comparePath == path)
                continue;
            if (comparePath.length < path.length
                && [[path stringByDeletingLastPathComponent] hasPrefix:comparePath])
            {
                flags = YES;
                break;
            }
        }
        if (flags)
            continue;
        [pathArray addObject:path];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //NSLog(@"Start");
        // 过滤的目录
        NSArray * excludeExtesionArray = array;
        NSMutableArray * resultPathArray = [NSMutableArray array];
        BOOL cancelScan = NO;
        int j = 0;
        for (NSString * path in pathArray) {
            
            NSFileManager * fm = [NSFileManager defaultManager];
            NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                             includingPropertiesForKeys:nil
                                                                options:NSDirectoryEnumerationSkipsPackageDescendants
                                                           errorHandler:nil];
            [resultPathArray addObject:path];
            int i = 0;
            for (NSURL * contentURL in dirEnumerator)
            {
                @autoreleasepool {
                    // 过滤快捷方式
                    NSNumber * result = nil;
                    [contentURL getResourceValue:&result forKey:NSURLIsAliasFileKey error:NULL];
                    if (result && [result boolValue])
                        continue;
                    
                    NSNumber * dir = nil;
                    [contentURL getResourceValue:&dir forKey:NSURLIsDirectoryKey error:NULL];
                    
                    NSString * resultPath = [contentURL path];
                    // 过滤系统特殊目录
                    for (NSString * excludePath in self->_excludeArray)
                    {
                        if ([resultPath hasPrefix:excludePath])
                        {
                            [dirEnumerator skipDescendants];
                            continue;
                        }
                    }
                    // 根据参数过滤后缀文件
                    if ([excludeExtesionArray count] > 0)
                    {
                        if ([excludeExtesionArray containsObject:resultPath.pathExtension])
                        {
                            [dirEnumerator skipDescendants];
                            continue;
                        }
                    }
                    // 隐藏文件
                    if ([self isHiddenItemForPath:resultPath])
                    {
                        if ([dir boolValue])
                            [dirEnumerator skipDescendants];
                        else if ([[resultPath lastPathComponent] isEqualToString:@".DS_Store"])
                            continue;
                    }
                    [resultPathArray addObject:resultPath];
                    // 进度信息
                    if (delegate)
                    {
                        cancelScan = [delegate scanFileItemProgress:nil progress:0.2 * (1 - pow(0.5, i)) * ((j + 0.0) / pathArray.count)];
                        if (cancelScan)
                            break;
                    }
                    i++;
                }
            }
            j++;
        }
        
        // 进度
        if (delegate)
        {
            if (cancelScan)
            {
                [delegate scanFileItemDidEnd:cancelScan];
                return;
            }
            else
            {
                [delegate scanFileItemProgress:nil progress:0.2];
            }
        }
        //NSLog(@"Enumear Path End");
        
        NSMutableDictionary * cacheDict = [NSMutableDictionary dictionary];
        NSMutableArray * resultArray = [NSMutableArray array];
        int n = 0;
        for (NSString * resultPath in resultPathArray)
        {
            @autoreleasepool {
                struct stat fileStat;
                NSUInteger totalSize = 0;
                if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)
                    continue;
                
                LMPhotoFileItem * fileItem = nil;
                if (!(fileStat.st_mode & S_IFDIR))
                {
                    totalSize += fileStat.st_size;
                    fileItem = [[LMPhotoFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = NO;
                    fileItem.fileSize = totalSize;
                    fileItem.parentItem = [cacheDict objectForKey:[resultPath stringByDeletingLastPathComponent]];
                    LMPhotoFileItem * parentItem = fileItem.parentItem;
                    [parentItem addChildrenItem:fileItem];
                    while (parentItem)
                    {
                        parentItem.fileSize += totalSize;
                        parentItem = parentItem.parentItem;
                    }
                    [resultArray addObject:fileItem];
                    n++;
                }
                else
                {
                    fileItem = [[LMPhotoFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = YES;
                    fileItem.parentItem = [cacheDict objectForKey:[resultPath stringByDeletingLastPathComponent]];
                    LMPhotoFileItem * parentItem = fileItem.parentItem;
                    [parentItem addChildrenItem:fileItem];
                    [cacheDict setObject:fileItem forKey:resultPath];
                }
                  // fileItem肯定不为Nil
//                if (!fileItem)
//                    continue;
                
                // 进度
                if (delegate && !fileItem.isDir)
                {
                    cancelScan = [delegate scanFileItemProgress:fileItem progress:0.2 + ((n + 0.0) / [resultPathArray count]) * 0.8];
                    if (cancelScan)
                        break;
                }
            }
        }
        
        // 取消扫描
        if (cancelScan && delegate)
        {
            [delegate scanFileItemDidEnd:cancelScan];
            return;
        }
        
        for (LMPhotoFileItem * fileItem in cacheDict.allValues)
        {
            if (delegate)
            {
                cancelScan = [delegate scanFileItemProgress:fileItem progress:0.2 + ((n + 0.0) / [resultPathArray count]) * 0.8];
                if (cancelScan)
                    break;
            }
            n++;
        }
        
        // 扫描完成
        [delegate scanFileItemDidEnd:cancelScan];
        
        //NSLog(@"Sacn Path End");
    });
}

// get total size by path
+ (uint64)caluactionSize:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return 0;
    uint64 fileSize = 0;
    BOOL diskMode = NO;
    
    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) == noErr)
    {
        if (fileStat.st_mode & S_IFDIR)
            fileSize = [LMFileAttributesTool lmFastFolderSizeAtFSRef:path diskMode:diskMode];
        else
        {
            //codecc 平台deadCode: if条件永远不成立
//            if (diskMode && fileStat.st_blocks != 0)
//                fileSize += fileStat.st_blocks * 512;
//            else
                fileSize += fileStat.st_size;
        }
    }
    return fileSize;
}


+ (NSArray *)systemProtectPath
{
    return kProtectArray;
}

@end
