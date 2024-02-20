//
//  QMLargeOldManager.m
//  QMBigOldFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMLargeOldManager.h"
#import "NSString+Extension.h"
#import "QMTimeHelp.h"
#import <LemonFileManager/LMAppleScriptTool.h>

#define k50MBSize       50 * 1000 * 1000
#define k100MBSize      2 * k50MBSize
#define k300MBSize      3 * k100MBSize
#define k500MBSize      5 * k100MBSize
#define k1GBSize        10 * k100MBSize
#define k3GBSize        3 * (uint64)k1GBSize
#define k5GBSize        5 * (uint64)k1GBSize
#define k10GBSize       10 * (uint64)k1GBSize

#define kNumber(a)      [NSNumber numberWithUnsignedLongLong:a]


@implementation QMLargeOldResultItem

@end

@implementation QMLargeOldResultRoot


- (void)addSubItem:(QMLargeOldResultItem *)item
{
    if (!_subItem) _subItem = [NSMutableArray array];
    [_subItem addObject:item];
}
- (void)sortedSubItem:(QMResultOrderEnum)orderType {
    [_subItem sortUsingComparator:^NSComparisonResult(QMLargeOldResultItem * obj1, QMLargeOldResultItem * obj2) {
        if(orderType == QMResultOrderAccessTime) {
            if ([obj1 lastAccessTime] < [obj2 lastAccessTime])
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
            return NSOrderedSame;
        } else {
            if ([obj1 fileSize] > [obj2 fileSize])
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
            return NSOrderedSame;
        }
    }];
}

- (NSArray *)subItemArray
{
    return _subItem;
}

@end

@interface QMLargeOldManager()
{
    NSMutableArray * _resultArray;
    NSArray * _sizeArray;
    NSMutableArray * _currentResultArray;
    NSMutableArray * _acessItemArray;
    
    NSArray * _typeOrderArray;
    
    BOOL _isStop;
}
@end

@implementation QMLargeOldManager

static QMLargeOldManager * instance = nil;

+ (instancetype)sharedManager
{
    @synchronized(self){
        if(instance == nil) {
            instance = [[QMLargeOldManager alloc] init];
        }
    }
    return instance;
//    static QMLargeOldManager * instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [[QMLargeOldManager alloc] init];
//    });
//    return instance;
}

+ (void)destroyManager {
    instance = nil;
}

- (void)dealloc
{
    
}

- (id)init
{
    if (self = [super init])
    {
        _resultArray = [[NSMutableArray alloc] init];
        _currentResultArray = [[NSMutableArray alloc] init];
        _sizeArray = @[kNumber(k50MBSize), kNumber(k100MBSize), kNumber(k500MBSize), kNumber(k1GBSize)];
        _acessItemArray = [NSMutableArray array];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_1", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMAnyTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_2", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMWeekTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_3", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMTwoWeekTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_4", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMMothTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_5", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMTwoMothTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_6", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMThreeMothTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_7", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMSixMothTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_8", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMYearTime)}];
        [_acessItemArray addObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_9", nil, [NSBundle bundleForClass:[self class]], @""),
                                     @"value": @(QMTwoYearTime)}];
        
        _typeOrderArray = @[NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_10", nil, [NSBundle bundleForClass:[self class]], @""),
                            NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_11", nil, [NSBundle bundleForClass:[self class]], @""),
                            NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_12", nil, [NSBundle bundleForClass:[self class]], @""),
                            NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_13", nil, [NSBundle bundleForClass:[self class]], @""),
                            NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_14", nil, [NSBundle bundleForClass:[self class]], @""),
                            NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_init_1553075107_15", nil, [NSBundle bundleForClass:[self class]], @"")];
    }
    return self;
}

- (NSArray *)sizeArray
{
    return _sizeArray;
}
- (NSArray *)accessTimeArray
{
    NSMutableArray * retArray = [_acessItemArray mutableCopy];
    [retArray replaceObjectAtIndex:0 withObject:@{@"label": NSLocalizedStringFromTableInBundle(@"QMLargeOldManager_accessTimeArray_1553075107_1", nil, [NSBundle bundleForClass:[self class]], @""),
                                                  @"value": @(0)}];
    return retArray;
}


- (NSString *)_fileSizeName:(uint64)maxSize minSize:(uint64)minSize
{
    NSString * maxSizeStr = nil;
    NSString * minSizeStr = [NSString stringFromDiskSize:minSize];
    if (maxSize != UINT64_MAX)
    {
        maxSizeStr = [NSString stringFromDiskSize:maxSize];
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileSizeName_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), minSizeStr, maxSizeStr];
    }
    else
    {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileSizeName_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""), minSizeStr];
    }
}
- (BOOL)_compareAccessTime:(QMAccessTimeEnum)time resultItem:(QMLargeOldResultItem *)resultItem
{
    if (time == QMAnyTime)
    {
        return YES;
    }
    else
    {
        NSDate * resultDate = [NSDate dateWithTimeIntervalSince1970:resultItem.lastAccessTime];
        NSDate * compareDate = [NSDate date];
        NSInteger offset = 0;
        if (time >= QMWeekTime && time <= QMTwoWeekTime)
            offset = [QMTimeHelp weeksBetweenDate:resultDate toDate:compareDate];
        else if (time >= QMMothTime && time <= QMSixMothTime)
            offset = [QMTimeHelp mothsBetweenDate:resultDate toDate:compareDate];
        else
            offset = [QMTimeHelp yearsBetweenDate:resultDate toDate:compareDate];
        if (time == QMWeekTime || time == QMMothTime || time == QMYearTime)
            return offset >= 1;
        else if (time == QMTwoWeekTime || time == QMTwoMothTime || time == QMTwoYearTime)
            return offset >= 2;
        else if (time == QMThreeMothTime)
            return offset >= 3;
        else if (time == QMSixMothTime)
            return offset >= 6;
        return NO;
    }
}

- (QMAccessTimeEnum)_resultItemAccessTimeEnum:(QMLargeOldResultItem *)resultItem
{
    NSDate * resultDate = [NSDate dateWithTimeIntervalSince1970:resultItem.lastAccessTime];
    NSDate * compareDate = [NSDate date];
    NSDateComponents * dateComponents = [QMTimeHelp dateBetweenDate:resultDate toDate:compareDate];
    if (dateComponents.year >= 2)
        return QMTwoYearTime;
    if (dateComponents.year == 1)
        return QMYearTime;
    if (dateComponents.month >= 6)
        return QMSixMothTime;
    if (dateComponents.month >= 3)
        return QMThreeMothTime;
    if (dateComponents.month == 2)
        return QMTwoMothTime;
    if (dateComponents.month == 1)
        return QMMothTime;
    if (dateComponents.weekOfMonth >= 2)
        return QMTwoWeekTime;
    if (dateComponents.weekOfMonth == 1)
        return QMWeekTime;
    return QMAnyTime;
}

- (NSString *)_fileExtensionName:(NSString *)filePath
{
    QMFileTypeEnum type = [QMFileClassification fileExtensionType:filePath];
    if(type == QMFileTypeMusic)
        return NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileExtensionName_1553075107_1", nil, [NSBundle bundleForClass:[self class]], @"");
    if(type == QMFileTypeVideo)
        return NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileExtensionName_1553075107_2", nil, [NSBundle bundleForClass:[self class]], @"");
    if(type == QMFileTypeDocument)
        return NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileExtensionName_1553075107_3", nil, [NSBundle bundleForClass:[self class]], @"");
    if(type == QMFileTypePicture)
        return NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileExtensionName_1553075107_4", nil, [NSBundle bundleForClass:[self class]], @"");
    return NSLocalizedStringFromTableInBundle(@"QMLargeOldManager__fileExtensionName_1553075107_5", nil, [NSBundle bundleForClass:[self class]], @"");
}

- (void)addLargeOldItem:(NSString *)path
               fileSize:(UInt64)size
             accessTime:(NSTimeInterval)accessTime
{
    QMLargeOldResultItem * resultItem = [[QMLargeOldResultItem alloc] init];
    resultItem.filePath = path;
    resultItem.fileSize = size;
    resultItem.lastAccessTime = accessTime;
    NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [image setSize:NSMakeSize(32, 32)];
    resultItem.iconImage = image;
    resultItem.fileType = [QMFileClassification fileExtensionType:path];
    [_resultArray addObject:resultItem];
}


- (NSTimeInterval)resultItemMinAccessTime
{
    NSTimeInterval retTime = 0;
    for (QMLargeOldResultItem * resultItem in _resultArray)
    {
        if (retTime == 0)
            retTime = resultItem.lastAccessTime;
        else
            retTime = MIN(retTime, resultItem.lastAccessTime);
    }
    return retTime;
}

- (void)resultWithFilter:(QMFileTypeEnum)type
                   order:(QMResultOrderEnum)orderType
                   block:(void(^)(NSArray *, NSArray *))block
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(self) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        [strongSelf->_currentResultArray removeAllObjects];
        NSMutableDictionary * resultDict = [NSMutableDictionary dictionary];
        for (QMLargeOldResultItem * resultItem in strongSelf->_resultArray)
        {
            // 符合条件的结果
            if((resultItem.fileType & type) != 0)
            {
                NSString * key = nil;
                UInt64 minSize = 0;
                UInt64 maxSize = 0;
                QMAccessTimeEnum accessTime = QMAnyTime;
                if (orderType == QMResultOrderSize)
                {
                    // 文件大小区间
                    int i = 0;
                    for (NSNumber * sizeNum in strongSelf->_sizeArray)
                    {
                        UInt64 tempSize = [sizeNum unsignedLongLongValue];
                        UInt64 nextTempSize = UINT64_MAX;
                        if (i + 1 < strongSelf->_sizeArray.count)
                            nextTempSize = [[strongSelf->_sizeArray objectAtIndex:i + 1] unsignedLongLongValue];
                        if (resultItem.fileSize >= tempSize && resultItem.fileSize < nextTempSize)
                        {
                            minSize = tempSize;
                            maxSize = nextTempSize;
                            break;
                        }
                        i++;
                    }
                    key = [strongSelf _fileSizeName:maxSize minSize:minSize];
                }
                else if (orderType == QMResultOrderKind)
                {
                    // 文件种类
                    key = [strongSelf _fileExtensionName:resultItem.filePath];
                }
                else if (orderType == QMResultOrderAccessTime)
                {
                    // 文件访问时间区间
                    QMAccessTimeEnum timeEnum = [strongSelf _resultItemAccessTimeEnum:resultItem];
                    for (int i = 0; i < strongSelf->_acessItemArray.count; i++)
                    {
                        NSDictionary * dict = [strongSelf->_acessItemArray objectAtIndex:i];
                        QMAccessTimeEnum compareTimeEnum = [[dict objectForKey:@"value"] intValue];
                        if (timeEnum == compareTimeEnum)
                        {
                            key = [dict objectForKey:@"label"];
                            accessTime = timeEnum;
                            break;
                        }
                    }
                }
                if (key)
                {
                    // 创建大小区间分类
                    QMLargeOldResultRoot * rootItem = nil;
                    rootItem = [resultDict objectForKey:key];
                    if (!rootItem)
                    {
                        rootItem = [[QMLargeOldResultRoot alloc] init];
                        rootItem.minSize = minSize;
                        rootItem.maxSize = maxSize;
                        rootItem.accessTimeEnum = accessTime;
                        rootItem.typeName = key;
                        [resultDict setObject:rootItem forKey:key];
                    }
                    rootItem.totalSize += resultItem.fileSize;
                    [rootItem addSubItem:resultItem];
                }
                [strongSelf->_currentResultArray addObject:resultItem];
            }
        }

        // 结果排序
        NSMutableArray * retArray = nil;
        if ([resultDict count] > 0)
        {
            retArray = [NSMutableArray arrayWithArray:resultDict.allValues];
            [retArray sortUsingComparator:^NSComparisonResult(QMLargeOldResultRoot * obj1, QMLargeOldResultRoot * obj2) {
                if (orderType == QMResultOrderSize)
                {
                    if (obj1.minSize > obj2.minSize)
                        return NSOrderedAscending;
                    else if (obj1.minSize < obj2.minSize)
                        return NSOrderedDescending;
                }
                else if (orderType == QMResultOrderAccessTime)
                {
                    if (obj1.accessTimeEnum > obj2.accessTimeEnum)
                        return NSOrderedAscending;
                    else if (obj1.accessTimeEnum < obj2.accessTimeEnum)
                        return NSOrderedDescending;
                }
                else if (orderType == QMResultOrderKind)
                {
                    NSInteger index1 = [strongSelf->_typeOrderArray indexOfObject:obj1.typeName];
                    NSInteger index2 = [strongSelf->_typeOrderArray indexOfObject:obj2.typeName];
                    if (index1 < index2)
                        return NSOrderedAscending;
                    else if (index1 > index2)
                        return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];
            // 排序子项
            for (QMLargeOldResultRoot * rootItem in retArray)
            {
                [rootItem sortedSubItem:orderType];
            }
        }
        else
        {
            retArray = [NSMutableArray arrayWithArray:strongSelf->_currentResultArray];
            [retArray sortUsingComparator:^NSComparisonResult(QMLargeOldResultItem * obj1, QMLargeOldResultItem * obj2) {
                if (orderType == QMResultOrderFileName)
                {
                    NSString * fileName1 = [[NSFileManager defaultManager] displayNameAtPath:obj1.filePath];
                    NSString * fileName2 = [[NSFileManager defaultManager] displayNameAtPath:obj2.filePath];
                    return [fileName1 localizedCaseInsensitiveCompare:fileName2];
                }
                return [obj1.filePath localizedCaseInsensitiveCompare:obj2.filePath];
            }];
        }
        block(retArray, strongSelf->_resultArray);
    });
}

#pragma mark-
#pragma mark remove All

- (NSArray *)needRemoveItem
{
    NSMutableArray * retArray = [NSMutableArray array];
    for (QMLargeOldResultItem * item in _resultArray)
    {
        if (item.isSelected)
            [retArray addObject:item];
    }
    return retArray;
}
- (NSArray *)resultItemArray
{
    return _resultArray;
}

- (void)removeAllResult
{
    [_currentResultArray removeAllObjects];
    [_resultArray removeAllObjects];
}
- (uint64)removeResultItem:(NSArray *)itemArray toTrash:(BOOL)toTrash block:(void(^)(float value, NSString* path))block
{
    _isStop = NO;
    NSMutableArray * removePathArray = [NSMutableArray array];
    UInt64 removeSize = 0;
    for (QMLargeOldResultItem * item in itemArray)
    {
        [removePathArray addObject:item.filePath];
        removeSize += item.fileSize;
    }
    // 移除item
    [_resultArray removeObjectsInArray:itemArray];
    
    // 删除文件
    // 多线程并发删除文件
    //__block int i = 0;
    __weak typeof(self) weakSelf = self;
    NSUInteger totalCount = removePathArray.count;
#ifdef DEBUG
    dispatch_apply(removePathArray.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
        __strong typeof(self) strongSelf = weakSelf;
        if(strongSelf == nil || strongSelf->_isStop) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            //i++;
            // 获取进度信息
            float progresss = (index + 0.0) / totalCount;
            block(progresss, [removePathArray objectAtIndex:index]);
        });
//        [NSThread sleepForTimeInterval:(2.0 / totalCount)];
    });
    return removeSize;
#else
    dispatch_queue_t removeQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t removeGroup =  dispatch_group_create();
    LMAppleScriptTool *removeTool = [[LMAppleScriptTool alloc] init];
    for(NSString * path in removePathArray) {
        NSInteger index = [removePathArray indexOfObject:path];
        dispatch_group_async(removeGroup, removeQueue, ^{
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:path]) {
                return;
            }
            if (!toTrash) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                return;
            }
            [removeTool removeFileToTrash:path];
            dispatch_async(dispatch_get_main_queue(), ^{
                //i++;
                // 获取进度信息，index由于dispatch_apply原有，会同时起几个线程，导致不是线性增大的，但是可以在界面忽略掉比上次值小的值
                float progresss = (index + 0.0) / totalCount;
                block(progresss, path);
            });
        });
    }
    return removeSize;
#endif
}

- (void)stopRemove {
    _isStop = YES;
}


@end
