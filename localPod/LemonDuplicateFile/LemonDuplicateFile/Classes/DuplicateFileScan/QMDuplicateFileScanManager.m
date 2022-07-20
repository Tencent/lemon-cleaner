
//
//  QMFileScanManager.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "QMDuplicateFileScanManager.h"
#include <fts.h>
#include <err.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/attr.h>
#import <QMUICommon/LMiCloudPathHelper.h>
#import <QMCoreFunction/NSString+PathExtension.h>

const float kDuplicateIndexFileProgress = 0.2f; // 索引所有文件部分占用的进度
const float kDuplicateCalculateProgress = 0.6f; // 计算索引文件大小占用的进度
const float kDuplicateMaxSearchProgress = kDuplicateIndexFileProgress + kDuplicateCalculateProgress; // 搜索部分占用的进度, 搜索完还有 识别重复文件占用的进度.

#define MINBLOCK 4096

#define kProtectArray @[[@"~/Library/" stringByExpandingTildeInPathIgnoreSandbox], @"/Library", @"/System", @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",[@"~/.Trash/" stringByExpandingTildeInPathIgnoreSandbox]]

#define kPicturePrefix [@"~/Pictures/" stringByExpandingTildeInPathIgnoreSandbox]

#define kProtectExtensionArray @[@"framework", @"dll", @"jar",  @"bin"]  // dll: windows 虚拟机动态库


@implementation QMFileItem

- (NSString *)description {
    return [NSString stringWithFormat:@"%@  %lld", _filePath, _fileSize];
}


- (void)addChildrenItem:(QMFileItem *)item {
    if (!_childrenItemArray) _childrenItemArray = [[NSMutableArray alloc] init];
    [_childrenItemArray addObject:item];
}

- (NSArray *)childrenItemArray {
    return _childrenItemArray;
}

@end

@interface QMDuplicateFileScanManager () {
    NSArray *_excludeArray;
}
@end

@implementation QMDuplicateFileScanManager




- (id)init {
    if (self = [super init]) {
        _excludeArray = @[[@"~/Library/" stringByExpandingTildeInPathIgnoreSandbox], @"/Library", @"/System",
                @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",
                [@"~/.Trash/" stringByExpandingTildeInPathIgnoreSandbox]];
    }
    return self;
}


- (NSUInteger)pathLevel:(NSString *)path {
    return [[path componentsSeparatedByString:@"/"] count];
}


- (NSArray *)protectedFolderArray {
    return _excludeArray;
}


- (void)listPathContent:(NSArray *)paths
               delegate:(id <QMFileScanManagerDelegate>)managerDelegate {
    NSMutableArray *pathArray = [NSMutableArray array];

    // 需要考虑到 用户选择的路径相互包含的问题.
    for (NSString *path in paths) {
        BOOL isIncludeByOtherPath = NO;
        for (NSString *comparePath in paths) {
            // path 自身不需要同自己比较.
            if (comparePath == path)
                continue;
            // path 是否是其他 path 的子目录
            if (comparePath.length < path.length
                    && [[path stringByDeletingLastPathComponent] hasPrefix:comparePath]) {
                isIncludeByOtherPath = YES;
                break;
            }
        }
        if (isIncludeByOtherPath)
            continue;
        [pathArray addObject:path];
    }


    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //NSLog(@"Start");
        // 过滤的目录
        NSArray *excludeExtensionArray = kProtectExtensionArray;
        NSMutableArray *resultPathArray = [NSMutableArray array];
        BOOL cancelScan = NO;
        int j = 0;

        CFAbsoluteTime measureTimeStart = CFAbsoluteTimeGetCurrent();
        NSLog(@"measureTimeStart is %lf", measureTimeStart);

        //该循环只是过滤掉不需要查找的文件
        for (NSString *path in pathArray) {

            NSFileManager *fm = [NSFileManager defaultManager];
            NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                            includingPropertiesForKeys:nil
                                                               options:0
                                                          errorHandler:nil];
            [resultPathArray addObject:path];
            CFAbsoluteTime measureTimeForLoopStart = CFAbsoluteTimeGetCurrent();
            NSLog(@"measureTimeForLoopStart %lf", measureTimeForLoopStart);

            int i = 0;
            for (NSURL *contentURL in dirEnumerator) {
                @autoreleasepool {
                    // 过滤快捷方式
                    NSNumber *result = nil;
                    [contentURL getResourceValue:&result forKey:NSURLIsAliasFileKey error:NULL];
                    if (result && [result boolValue])
                        continue;

                    NSNumber *dir = nil;
                    [contentURL getResourceValue:&dir forKey:NSURLIsDirectoryKey error:NULL];
                    
                    NSNumber *package = nil;
                    [contentURL getResourceValue:&package forKey:NSURLIsPackageKey error:NULL];

                    NSString *resultPath = [contentURL path];
                    // 过滤系统特殊目录 ,需要考虑 iCloud 的问题. 另外选择目录的时候 已经排除
                    for (NSString *excludePath in self->_excludeArray) {
                        if ([resultPath hasPrefix:excludePath] && ![LMiCloudPathHelper isICloudSubPath:path]) {
                            [dirEnumerator skipDescendants];
                            continue;
                        }
                    }
                    
                    // package(app) 作为一个整体进行比对, 但特殊的 package  ~/Pictures/照片图库.photoslibrary      ~/Pictures/Photo Booth 图库 应该深入到 app 中搜索图片.


                    if(package && [package boolValue]){
                        if ([resultPath hasPrefix:kPicturePrefix]) {
                        }else{
                            [dirEnumerator skipDescendants];
                        }
                    }
                    
                    // 根据参数过滤后缀文件
                    if ([excludeExtensionArray count] > 0) {
                        if ([excludeExtensionArray containsObject:resultPath.pathExtension]) {
                            [dirEnumerator skipDescendants];
                            continue;
                        }
                    }

                    // 隐藏文件
//                    BOOL isHidden = [self isHiddenItemForPath:resultPath]; //老做法

                    NSNumber *hidden = nil;
                    [contentURL getResourceValue:&hidden forKey:NSURLIsHiddenKey error:NULL];
                    if ([hidden boolValue]) {
                        if ([dir boolValue])
                            [dirEnumerator skipDescendants];
                        else if ([[resultPath lastPathComponent] isEqualToString:@".DS_Store"])
                            continue;
                    }

                    [resultPathArray addObject:resultPath];
                    // 模拟进度信息
                    if (managerDelegate) {
                        double itemProcess = 0.0;
                        if (i <= 10000) {
                            if (arc4random_uniform(1000) == 1) {
                                itemProcess = 0.15 * (1 - pow(0.99999, i)) * ((j + 1.0) / pathArray.count);
                            }
                        } else {
                            if (arc4random_uniform(1000) == 1) {
                                itemProcess = 0.15 + 0.05 * (1 - pow(0.99999, i - 10000)) * ((j + 1.0) / pathArray.count);
                            }
                        }

                        if (itemProcess > 0) { //需要更改进度
//                            NSLog(@"itemProcess is %f",itemProcess);
                            cancelScan = [managerDelegate scanFileItemProgress:nil progress:itemProcess scanPath:contentURL.path];
                        }

                        if (cancelScan) {
                            if (managerDelegate) {
                                [managerDelegate scanFileItemDidEnd:cancelScan];
                            }
                            return;
                        }
                    }
                    i++;
                }
            } //内层for 结束

            CFAbsoluteTime measureTimeForLoop = CFAbsoluteTimeGetCurrent();
            NSLog(@"measureTimeForLoop %d is %lf", j, measureTimeForLoop);


            j++;
        } //外层 for 结束

        // 进度
        if (cancelScan) {
            if (managerDelegate) {
                [managerDelegate scanFileItemDidEnd:cancelScan];
            }
            return;
        }
        //NSLog(@"Enum Path End");

        NSMutableDictionary *cacheDict = [NSMutableDictionary dictionary];
        NSMutableArray *resultArray = [NSMutableArray array];
        int n = 0;
        for (NSString *resultPath in resultPathArray) {
            @autoreleasepool {
                struct stat fileStat;
                NSUInteger totalSize = 0;
                if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)  //获取文件信息
                    continue;

                QMFileItem *fileItem = nil;
                if (!(fileStat.st_mode & S_IFDIR))     //判断是否是文件夹
                {
                    totalSize += fileStat.st_size;     //获取文件大小
                    fileItem = [[QMFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = NO;
                    fileItem.fileSize = totalSize;
                    fileItem.parentItem = cacheDict[[resultPath stringByDeletingLastPathComponent]];
                    QMFileItem *parentItem = fileItem.parentItem;
                    [parentItem addChildrenItem:fileItem];
                    //依次更新上一层目录的大小
                    while (parentItem) {
                        parentItem.fileSize += totalSize;
                        parentItem = parentItem.parentItem;
                    }
                    [resultArray addObject:fileItem];
                    n++;
                } else {
                    fileItem = [[QMFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = YES;
                    fileItem.parentItem = cacheDict[[resultPath stringByDeletingLastPathComponent]];
                    QMFileItem *parentItem = fileItem.parentItem;
                    [parentItem addChildrenItem:fileItem];
                    cacheDict[resultPath] = fileItem;
                }

                if (!fileItem)
                    continue;

                // 进度
                if (managerDelegate && !fileItem.isDir) {
                    cancelScan = [managerDelegate scanFileItemProgress:fileItem progress:kDuplicateIndexFileProgress + ((n + 0.0) / [resultPathArray count]) * kDuplicateCalculateProgress scanPath:resultPath];
                    if (cancelScan) {
                        if (managerDelegate) {
                            [managerDelegate scanFileItemDidEnd:cancelScan];
                        }
                        return;
                    }
                }

            }
        }


        for (QMFileItem *fileItem in cacheDict.allValues) {
            if (managerDelegate) {
                cancelScan = [managerDelegate scanFileItemProgress:fileItem progress:kDuplicateIndexFileProgress + ((n + 0.0) / [resultPathArray count]) * kDuplicateCalculateProgress scanPath:fileItem.filePath];
                if (cancelScan)
                    break;
            }

            n++;
        }

        // 取消扫描
        if (cancelScan) {
            if (managerDelegate) {
                [managerDelegate scanFileItemDidEnd:cancelScan];
            }
            return;
        }

        // 扫描完成
        if (managerDelegate) {
            [managerDelegate scanFileItemDidEnd:cancelScan];
        }

        //NSLog(@"scan  Path End");
    });
}

// get total size by path
+ (uint64)calculateSize:(NSString *)path delegate:(id<McDuplicateFilesDelegate>) showDelegate{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return 0;
    uint64 fileSize = 0;
    BOOL diskMode = NO;

    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) == noErr) {
        if (fileStat.st_mode & S_IFDIR)
//            fileSize = [self fastFolderSizeAtFSRef:path diskMode:diskMode delegate:showDelegate];
            fileSize = [self sizeAtPath:path diskMode:diskMode delegate:showDelegate];
        else {
            if (diskMode && fileStat.st_blocks != 0)
                fileSize += fileStat.st_blocks * 512;
            else
                fileSize += fileStat.st_size;
        }
        
     
    }
    return fileSize;
}


+ (uint64_t)sizeAtPath:(NSString *)filePath diskMode:(BOOL)diskMode delegate:(id<McDuplicateFilesDelegate>) showDelegate
{
    uint64_t totalSize = 0;
    uint64_t limitCount = 0;
    
    NSMutableArray *searchPaths = [NSMutableArray arrayWithObject:filePath];
    while ([searchPaths count] > 0 && limitCount++ < 10240 * 3) //我这计算1w 个文件大约 1s 左右
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
                    NSArray *childSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:nil];
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
            
            // 取消扫描
            if(!showDelegate || [showDelegate cancelScan]){
                break;
            }
        }
    }
    
    return totalSize;
}

//废弃
+ (unsigned long long)fastFolderSizeAtFSRef:(NSString *)path diskMode:(BOOL)diskMode delegate:(id<McDuplicateFilesDelegate>) showDelegate{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                    includingPropertiesForKeys:nil
                                                       options:0
                                                  errorHandler:nil];
    NSUInteger totalSize = 0;
    for (NSURL *pathURL in dirEnumerator) {
        NSString *resultPath = [pathURL path];
        struct stat fileStat;
        if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)
            continue;
        if (fileStat.st_mode & S_IFDIR)
            continue;
        if (diskMode) {
            if (fileStat.st_flags != 0)
                totalSize += (((fileStat.st_size +
                        MINBLOCK - 1) / MINBLOCK) * MINBLOCK);
            else
                totalSize += fileStat.st_blocks * 512;

        } else
            totalSize += fileStat.st_size;
        
        if(!showDelegate || [showDelegate cancelScan]){
            
        }
        //特别注意,!!!!好坑的遗留代码. 最多计算10s, 超过的时候舍弃. 所以两个相同文件计算的大小也可能不相同.
        if (CFAbsoluteTimeGetCurrent() - startTime > 10)
            break;
    }
    return totalSize;
}


+ (NSArray *)systemProtectPath {
    return kProtectArray;
}

@end
