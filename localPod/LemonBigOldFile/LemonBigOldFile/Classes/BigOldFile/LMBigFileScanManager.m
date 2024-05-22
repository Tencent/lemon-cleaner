//
//  LMBigFileScanManager.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "LMBigFileScanManager.h"
#include <fts.h>
#include <err.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/attr.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <LemonFileManager/LMFileAttributesTool.h>

@implementation LMBigFileItem

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@  %lld", _filePath, _fileSize];
}


- (void)addChildrenItem:(LMBigFileItem *)item
{
    if (!_childrenItemArray) _childrenItemArray = [[NSMutableArray alloc] init];
    [_childrenItemArray addObject:item];
}
- (NSArray *)childrenItemArray
{
    return _childrenItemArray;
}

@end

@interface LMBigFileScanManager()
{
    NSArray * _excludeArray;
}
@end

@implementation LMBigFileScanManager


#define MINBLOCK 4096

const float kMaxSearchProgress = 1.0f;

#define kProtectArray @[[@"~/Library/" stringByExpandingTildeInPath], @"/Library", @"/System", @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",[@"~/.Trash/" stringByExpandingTildeInPath]]

- (id)init
{
    if (self = [super init])
    {
//        _excludeArray = @[[@"~/Library/" stringByExpandingTildeInPath], @"/Library", @"/System",
//                          @"/Applications", @"/bin", @"/cores", @"/sbin", @"/usr", @"~/.Trash/",
//                          [@"~/.Trash/" stringByExpandingTildeInPath]];
        _excludeArray = @[[NSString stringWithFormat:@"%@/Library/",[NSString getUserHomePath]], [NSString stringWithFormat:@"%@/.Trash/",[NSString getUserHomePath]], [NSString stringWithFormat:@"/Library/"]];
    }
    return self;
}

//+ (instancetype)sharedManager
//{
//    static LMBigFileScanManager * instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (!instance)
//            instance = [[LMBigFileScanManager alloc] init];
//    });
//    return instance;
//}


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
               delegate:(id<LMBigFileScanManagerDelegate>)delegate
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
//
//            NSFileManager * fm = [NSFileManager defaultManager];
//            NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
//                                             includingPropertiesForKeys:nil
//                                                                options:NSDirectoryEnumerationSkipsPackageDescendants
//                                                           errorHandler:nil];
        
            NSString *outputStr = [QMShellExcuteHelper excuteCmd:[NSString stringWithFormat:@"mdfind -onlyin %@ \"kMDItemFSSize > 52428800\"", path]];
            NSLog(@"big old file outputStr = %@", outputStr);
            NSArray *mdfindArr = [outputStr componentsSeparatedByString:@"\n"];
            [resultPathArray addObject:path];
            int i = 0;
            
            for (NSString * contentPath in mdfindArr)
            {
                @autoreleasepool {
                    NSLog(@"contentPath1==>%@",contentPath);
                    if ((contentPath == nil) || ([contentPath isEqualToString:@""])) {
                        continue;
                    }
                    NSLog(@"big old file path = %@", contentPath);
                    if ([contentPath isEqualToString:[NSString getUserHomePath]]) {
                        continue;
                    }
                    // 过滤系统特殊目录
                    BOOL isContain = NO;
                    for (NSString * excludePath in self->_excludeArray)
                    {
                        if ([contentPath containsString:excludePath])
                        {
                            isContain = YES;
                            break;
                        }
                    }
                    if (isContain) {
                        continue;
                    }
                    // 根据参数过滤后缀文件
                    if ([excludeExtesionArray count] > 0)
                    {
                        if ([excludeExtesionArray containsObject:contentPath.pathExtension])
                        {
                            continue;
                        }
                    }

                    // 过滤快捷方式
                    NSNumber * result = nil;
                    [[NSURL URLWithString:contentPath] getResourceValue:&result forKey:NSURLIsAliasFileKey error:NULL];
                    if (result && [result boolValue])
                        continue;
                    
                    NSNumber * dir = nil;
                    [[NSURL URLWithString:contentPath] getResourceValue:&dir forKey:NSURLIsDirectoryKey error:NULL];
                    
                    NSNumber * pacakge = nil;
                    [[NSURL URLWithString:contentPath] getResourceValue:&pacakge forKey:NSURLIsPackageKey error:NULL];
                    
                    
                    NSNumber * isHidden = nil;
                    [[NSURL URLWithString:contentPath] getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:NULL];
                    // 隐藏文件 -- 使用系统API
                    if ([isHidden boolValue])
                    {
                        continue;
                    }
                    NSLog(@"contentPath2==>%@",contentPath);
                    if (![dir boolValue] || [pacakge boolValue]){
                        [resultPathArray addObject:contentPath];
                    }
                        
                    // 进度信息
                    if (delegate)
                    {
                        cancelScan = [delegate scanFileItemProgress:nil progress:0 scanPath:contentPath];
                        if (cancelScan)
                            break;
                    }
                    i++;
                }
            }
            j++;
        }
        
        //去重 因为mdfind返回的数据可能会把 包文件和子文件一起返回，导致结果重复
        NSMutableArray *duplicateFileArr = [NSMutableArray new];
        for (NSInteger i = 0; i < [resultPathArray count]; i++) {
            for (NSInteger j = 0; j < [resultPathArray count]; j++) {
                NSString *path = [resultPathArray objectAtIndex:i];
                NSString *cmpPath = [resultPathArray objectAtIndex:j];
                NSString *cmpParentPath = [cmpPath stringByDeletingLastPathComponent];
                if ([path isEqualToString:cmpParentPath]) {
                    if (![duplicateFileArr containsObject:cmpPath]) {
                        [duplicateFileArr addObject:cmpPath];
                    }
                }
            }
        }
        
        if ([duplicateFileArr count] > 0) {
            [resultPathArray removeObjectsInArray:duplicateFileArr];
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
                [delegate scanFileItemProgress:nil progress:0.5*kMaxSearchProgress scanPath:nil];
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
                
                LMBigFileItem * fileItem = nil;
                if (!(fileStat.st_mode & S_IFDIR))
                {
                    totalSize += fileStat.st_size;
                    fileItem = [[LMBigFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = NO;
                    fileItem.fileSize = totalSize;
//                    fileItem.parentItem = [cacheDict objectForKey:[resultPath stringByDeletingLastPathComponent]];
//                    LMBigFileItem * parentItem = fileItem.parentItem;
//                    [parentItem addChildrenItem:fileItem];
//                    while (parentItem)
//                    {
//                        parentItem.fileSize += totalSize;
//                        parentItem = parentItem.parentItem;
//                    }
                    [resultArray addObject:fileItem];
                    n++;
                }
                else
                {
                    fileItem = [[LMBigFileItem alloc] init];
                    fileItem.filePath = resultPath;
                    fileItem.isDir = YES;
//                    fileItem.parentItem = [cacheDict objectForKey:[resultPath stringByDeletingLastPathComponent]];
//                    LMBigFileItem * parentItem = fileItem.parentItem;
//                    [parentItem addChildrenItem:fileItem];
                    [cacheDict setObject:fileItem forKey:resultPath];
                }
                // fileItem肯定不为Nil
//                if (!fileItem)
//                    continue;
                
                // 进度
                if (delegate)
                {
                    cancelScan = [delegate scanFileItemProgress:fileItem progress:(0.5 + ((n + 0.0) / [resultPathArray count]) * 0.5) * kMaxSearchProgress scanPath:fileItem.filePath];
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
        
//        for (LMBigFileItem * fileItem in cacheDict.allValues)
//        {
//            if (delegate)
//            {
//                cancelScan = [delegate scanFileItemProgress:fileItem progress:0.2 + ((n + 0.0) / [resultPathArray count]) * 0.8];
//                if (cancelScan)
//                    break;
//            }
//            n++;
//        }
        
        // 扫描完成
        [delegate scanFileItemDidEnd:cancelScan];
        
        //NSLog(@"Sacn Path End");
    });
}

// get total size by path
+ (uint64)caluactionSize:(NSString *)path
{
    return [LMFileAttributesTool caluactionSize:path diskMode:NO];
}


+ (NSArray *)systemProtectPath
{
    return kProtectArray;
}

@end
