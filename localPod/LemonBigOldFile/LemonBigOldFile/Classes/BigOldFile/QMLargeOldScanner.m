//
//  QMLargeOldScanner.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "QMLargeOldScanner.h"
#import "LMBigFileScanManager.h"
#include <sys/stat.h>

#define kSizeUnit           1000
#define kDefaultLargeSize   50 * kSizeUnit * kSizeUnit
#define kMAXLargeFolderSize kSizeUnit * kSizeUnit * kSizeUnit

@interface QMLargeOldItem()
{
    NSMutableArray * _childrenArray;
}
@end

@implementation QMLargeOldItem

- (id)initWithFileItem:(LMBigFileItem *)item
{
    if (self = [super init])
    {
        // 获取上次打开时间
        struct stat output;
        int ret = lstat([item.filePath UTF8String], &output);
        if (ret)
            return nil;
        // error handling omitted for this example
        struct timespec accessTime = output.st_mtimespec;
        _fileSize = item.fileSize;
        _filePath = item.filePath;
        _isDir = item.isDir;
        _lastAccessTime = accessTime.tv_sec;
        
        [self addChildrenItem:item];
    }
    return self;
}

- (void)addChildrenItem:(LMBigFileItem *)item
{
    if ([[item childrenItemArray] count] == 0)
        return;
    if (!_childrenArray) _childrenArray = [NSMutableArray array];
    for (LMBigFileItem * subItem in item.childrenItemArray)
    {
        QMLargeOldItem * largeOldItem = [[QMLargeOldItem alloc] initWithFileItem:subItem];
        [_childrenArray addObject:largeOldItem];
    }
}
- (NSArray *)childrenItemArray
{
    return _childrenArray;
}

- (NSString *)description
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_lastAccessTime];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@  %@", _filePath, formattedDateString];
}

@end

@interface QMLargeOldScanner()
{
    __weak id<QMLargeOldScannerDelegate> _delegate;
    NSMutableArray * _contentArray;
    
    LMBigFileScanManager * scanManager;
    
    NSArray * _excludeExtesionArray;
    NSArray * _singleExtesionArray;
    
//    NSMutableArray * _resultArray;
    
    BOOL _isStop;
}
@end

@implementation QMLargeOldScanner

- (id)init
{
    if (self = [super init])
    {
        _excludeExtesionArray = @[@"photolibrary", @"photoslibrary", @"app", @"framework"];
        _singleExtesionArray = @[@"framework"];
    }
    return self;
}

- (void)start:(id<QMLargeOldScannerDelegate>)scanDelegate
         path:(NSString *)path
 excludeArray:(NSArray *)array
{
    _isStop = NO;
    _delegate = scanDelegate;
    _contentArray = [NSMutableArray array];
    
    scanManager = [[LMBigFileScanManager alloc] init];
    [scanManager listPathContent:@[path]
                    excludeArray:_excludeExtesionArray
                        delegate:(id<LMBigFileScanManagerDelegate>)self];
}

- (void)stopScan
{
    _isStop = YES;
}

- (BOOL)checkCanRemove:(NSString *)path
{
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDir])
        return NO;
    // 过滤只读目录
    if (isDir && ![fm isWritableFileAtPath:path])
        return NO;
    if ([fm isDeletableFileAtPath:path])
        return YES;
    return NO;
}


- (NSArray *)resultWithType:(QMLargeOldType)type fileSize:(UInt64)size
{
    return _contentArray;
    /*
    NSArray * _largeOldArray = [self largeOldItemResult:size];
    NSMutableArray * resultArray = [NSMutableArray array];
    switch (type)
    {
        case QMLargeOldOnlyFile:
        {
            for (QMLargeOldItem * item in _largeOldArray)
            {
                if (!item.isDir)
                    [resultArray addObject:item];
            }
            break;
        }
        case QMLargeOldOnlyFolder:
        {
            for (QMLargeOldItem * item in _largeOldArray)
            {
                if (item.isDir)
                    [resultArray addObject:item];
            }
            break;
        }
        default:
        {
            NSArray * dirResult = [self resultWithType:QMLargeOldOnlyFolder fileSize:size];
            for (QMLargeOldItem * item in _largeOldArray)
            {
                if (!item.isDir)
                {
                    BOOL flags = NO;
                    for (QMLargeOldItem * dirItem in dirResult)
                    {
                        NSString * dirPath = [dirItem filePath];
                        NSRange range = [dirPath rangeOfString:@"/" options:NSBackwardsSearch];
                        if (range.length == 0)
                            continue;
                        if (range.location != dirPath.length - 1)
                            dirPath = [dirPath stringByAppendingString:@"/"];
                        if ([[item filePath] hasPrefix:dirPath])
                        {
                            flags = YES;
                            break;
                        }
                    }
                    if (flags)
                        continue;
                    [resultArray addObject:item];
                }
            }
            [resultArray addObjectsFromArray:dirResult];
            break;
        }
    }
    return resultArray;
     */
}

#pragma mark-
#pragma mark 文件搜索委托

- (BOOL)scanFileItemProgress:(LMBigFileItem *)item progress:(CGFloat)value scanPath:(NSString *)path
{
    if (_delegate) {
//        NSLog(@"scanFileItemProgress value:%f, path:%@", value, path);
        [_delegate progressRate:value path:path];
    }
    
    if (!item)
        return _isStop;
    
    if (![self checkCanRemove:item.filePath])
        return _isStop;
    
    if (item.isDir)
    {
        if ([_excludeExtesionArray containsObject:[item.filePath pathExtension]])
            return NO;
        NSNumber * package = nil;
        [[NSURL fileURLWithPath:item.filePath] getResourceValue:&package forKey:NSURLIsPackageKey error:NULL];
        if ([package boolValue])
        {
            item.fileSize = [LMBigFileScanManager caluactionSize:item.filePath];
        }
    }
    
    if (item.fileSize >= kDefaultLargeSize)
    {
//        [_contentArray addObject:item];
        
        QMLargeOldItem * largeOldItem = [[QMLargeOldItem alloc] initWithFileItem:item];
        [_contentArray addObject:largeOldItem];
    }
    return _isStop;
}
- (void)scanFileItemDidEnd:(BOOL)userCancel
{
    // 扫描完成
    if (_delegate)
    {
        [_delegate progressRate:1 path:nil];
        [_delegate largeOldFileSearchEnd];
    }
    //[self searchLargeOldFiles];
}

/*
#pragma mark-
#pragma mark 扫描大文件

// 检查当前项的最大子目录层
- (NSInteger)chekFileItemDirLevel:(QMLargeOldItem *)item layer:(int)layer
{
    if (layer > 20)
        return 20;
    NSInteger retLevel = 0;
    for (QMLargeOldItem * subItem in item.childrenItemArray)
    {
        if ([subItem isDir])
        {
            NSInteger level = [self chekFileItemDirLevel:subItem layer:layer + 1];
            retLevel = MAX(retLevel, level);
        }
    }
    if (item.childrenItemArray.count > 0)
        retLevel++;
    return retLevel;
}

// 检查目录是否满足结果
- (BOOL)checkDirItem:(QMLargeOldItem *)item defaultSize:(uint64)size
{
    if (!item)
        return NO;
    if (item.fileSize < size)
       return NO;
    NSUInteger maxSize = kMAXLargeFolderSize;
    if (item.fileSize >= maxSize * 3)
        return NO;
    NSInteger level = [self chekFileItemDirLevel:item layer:0];
    if (level <= 2)
    {
        UInt64 maxSize = 0;
        UInt64 minSize = item.fileSize;
        for (QMLargeOldItem * subItem in item.childrenItemArray)
        {
            if (subItem.isDir && subItem.childrenItemArray.count == 0)
                continue;
            if ([[subItem.filePath lastPathComponent] hasPrefix:@"."])
                continue;
            maxSize = MAX(subItem.fileSize, maxSize);
            minSize = MIN(subItem.fileSize, minSize);
        }
        if (maxSize == 0)
            return NO;
        if (minSize >= size)
            return YES;
        if (maxSize < size)
            return YES;
        if (item.fileSize - maxSize > size)
            return YES;
    }
    return NO;
}

// 通过给定的大小创建结果对象
- (NSArray *)largeOldItemResult:(uint64)fileSize
{
    NSMutableArray * retArray = [NSMutableArray array];
    for (QMLargeOldItem * item in _resultArray)
    {
        // 当前路径有没有只扫描文件类型
        BOOL singleFile = NO;
        QMLargeOldItem * tempItem = item;
        while (tempItem)
        {
            NSString * extension = [tempItem.filePath pathExtension];
            if ([_singleExtesionArray containsObject:extension])
            {
                singleFile = YES;
                break;
            }
            tempItem = tempItem.parentItem;
        }
        
        QMLargeOldItem * resultItem = nil;
        if (!item.isDir || !item.childrenItemArray)
        {
            if (item.fileSize >= fileSize)
                resultItem = item;
        }
        else
        {
            if (singleFile)
                continue;
            if ([self checkDirItem:item defaultSize:fileSize]
                && ![self checkDirItem:item.parentItem defaultSize:fileSize])
            {
                resultItem = item;
            }
        }
        
        if (!resultItem)// || [resultSet containsObject:resultItem])
            continue;
        [retArray addObject:resultItem];
    }
    return retArray;
}

- (void)searchLargeOldFiles
{
    NSMutableArray * resultArray = [NSMutableArray array];
    NSInteger i = 0;
    for (LMBigFileItem * item in _contentArray)
    {
        // 进度信息
        if (_delegate)
            [_delegate progressRate:((i + 1.0) / _contentArray.count) * (1 - kMaxSearchProgress) + kMaxSearchProgress];
        i++;
        
        // 过滤点开头文件
        if ([[item.filePath lastPathComponent] hasPrefix:@"."])
            continue;
        
        QMLargeOldItem * largeOldItem = [[QMLargeOldItem alloc] initWithFileItem:item];
        [resultArray addObject:largeOldItem];
        
        if (_isStop)
            break;
    }
    _resultArray = resultArray;
    _contentArray = nil;
    
    // 扫描完成
    if (_delegate)
        [_delegate largeOldFileSearchEnd];
}
*/
@end
