//
//  QMLiteCleanerManager.m
//  QMCleaner
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMLiteCleanerManager.h"
#import "QMScanCategory.h"
#import "QMRemoveManager.h"
#import "QMXMLParseManager.h"
#import "QMCleanUtils.h"
#import "LMCleanerDataCenter.h"

@interface QMLiteCleanerManager()
{
    // 扫描
    QMScanCategory * _scanCategory;
    // 删除
    QMRemoveManager * _removeManager;
    
    QMXMLParseManager * _parseManager;
    
    // 结果
    NSMutableDictionary * _resultDict;
    UInt64 _totalSize;
    uint64 _totalSize2;
    
    NSDictionary * _categoryDict;
    
    NSUInteger _scanItemCount;
    NSArray * _scanItemArray;
    
    NSLock* mTrashCleaningLock;
    BOOL scanning;
    BOOL cleanning;


}
@end

@implementation QMLiteCleanerManager

- (id)init
{
    if (self = [super init])
    {
//        _parseManager = [[QMXMLParseManager alloc] init];
        _scanCategory = [[QMScanCategory alloc] init];
        _removeManager = [QMRemoveManager getInstance];
        [_removeManager setDelegate:(id<QMRemoveManagerDelegate>)self];
        mTrashCleaningLock = [[NSLock alloc] init];

    }
    return self;
}

+ (QMLiteCleanerManager *)sharedManger
{
    static QMLiteCleanerManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMLiteCleanerManager alloc] init];
    });
    return instance;
}

// 多线程同时扫描的时候保证只扫一次.
- (void)startScan
{
    //在进入方法时,判断是否有扫描在执行. 如果在执行,等待这次扫描结束,采用这次扫描的结果,否则,重新进行扫描.
    BOOL needWait = scanning ? YES: NO;
    [mTrashCleaningLock lock];
    if(needWait){
        [mTrashCleaningLock unlock];
        return;
    }
    scanning = YES;
    _totalSize = 0;
    _totalSize2 = 0;
    [_scanCategory setIsStopScan:NO];
    _resultDict = [[NSMutableDictionary alloc] init];
    _parseManager = [QMXMLParseManager sharedManager];
    [_parseManager setParseEndNO];
    if ([_parseManager startParaseXML:_needRefresh])
    {
        _needRefresh = NO;
        _categoryDict = [_parseManager categoryItemDict];
        for (NSString * key in _categoryDict.allKeys)
        {
            QMCategoryItem * categoryItem = [_categoryDict objectForKey:key];
            for (QMCategorySubItem * categorySubItem in categoryItem.m_categorySubItemArray)
            {
                NSString *bundleId = [categorySubItem bundleId];
                if ([bundleId isEqualToString:@"com.jetbrains.intellij"] || [bundleId isEqualToString:@"com.google.android.studio"] || [bundleId isEqualToString:@"com.jetbrains.PhpStorm"]) {
                    [categorySubItem setRecommend:NO];
                }
                
                //读取数据库
                CleanSubcateSelectStatus status = [[LMCleanerDataCenter shareInstance] getSubcateSelectStatus:categorySubItem.subCategoryID];
                if (status == CleanSubcateSelectStatusDeselect){
                    NSLog(@"category sub item deselect title = %@", [categorySubItem title]);
                    [categorySubItem setFastMode:NO];
                }
            }
        }
        [_scanCategory setM_filerDict:[_parseManager filterItemDict]];
        [_scanCategory setDelegate:(id<QMScanCategoryDelegate>)self];
        [_scanCategory startQuickScanCategoryArray:_categoryDict.allValues];
    }
    scanning = NO;
    [mTrashCleaningLock unlock];
}
- (void)stopScan
{
    [_scanCategory setIsStopScan:YES];
}

- (void)startClean
{
    //在进入方法时,判断是否有清理在执行. 如果在执行,等待这次清理结束,采用这次清理的结果,否则,重新进行清理.
    BOOL needWait = cleanning ? YES: NO;
    [mTrashCleaningLock lock];
    if(needWait){
        [mTrashCleaningLock unlock];
        return;
    }
    cleanning = YES;
    
    if (!_categoryDict)
        return;
    // 删除
    // 获取category
    NSDictionary *m_categoryDict = [_parseManager categoryItemDict];
    NSMutableDictionary * removeItemDict = [NSMutableDictionary dictionary];
    
    for (QMCategoryItem * categoryItem in m_categoryDict.allValues)
    {
        if (categoryItem.state == NSOffState)
            continue;
        
        NSMutableDictionary *removeSubItemDict = [NSMutableDictionary dictionary];
        for (QMCategorySubItem *subItem in categoryItem.m_categorySubItemArray) {
            NSUInteger removeSize = 0;
            NSArray *array = [subItem getSelectedResultItem:&removeSize];
            //            if ([array count] > 0)
            [removeSubItemDict setObject:array forKey:subItem.subCategoryID];
        }
        
        [removeItemDict setObject:removeSubItemDict forKey:categoryItem.categoryID];
    }
    [_removeManager startCleaner:removeItemDict];
    
    cleanning = NO;
    [mTrashCleaningLock unlock];

}

- (UInt64)resultSize
{
    return _totalSize2;
}

#pragma mark-
#pragma mark 扫描

- (void)scanCategoryArray:(NSArray *)array
{
    _scanItemArray = array;
    _scanItemCount = 0;
}

- (void)startScanCategory:(NSString *)categoryID
{
    for (QMCategoryItem * item in _scanItemArray)
    {
        if ([item.categoryID isEqualToString:categoryID])
        {
            _resultItemArray = [[NSMutableArray alloc] init];
            break;
        }
    }
}

- (void)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item
{
    if (item && ![_resultItemArray containsObject:item])
    {
        _totalSize += item.resultSelectedFileSize;
        [_resultItemArray addObject:item];
    }
    [_delegate scanProgressInfo:(value + _scanItemCount) / _scanItemArray.count  scanPath:path];
//    NSLog(@"value : %f path : %@", value, path);
}

- (void)scanCategoryDidEnd:(NSString *)categoryID
{
    for (QMCategoryItem * item in _scanItemArray)
    {
        if ([item.categoryID isEqualToString:categoryID])
        {
            _totalSize2 += item.resultSelectedFileSize;
            [_resultDict setObject:_resultItemArray forKey:categoryID];
            _scanItemCount++;
            break;
        }
    }
}

#pragma mark-
#pragma mark 清理

- (void)cleanCategoryStart:(NSString *)categoryId{
    NSLog(@"lite cleanCategoryStart: %@", categoryId);
}

- (void)cleanCategoryEnd:(QMCategoryItem *)categoryItem{
    NSLog(@"lite cleanCategoryEnd: %@", categoryItem);
}

- (void)cleanSubCategoryStart:(NSString *)subCategoryID{
    
}

- (void)cleanSubCategoryEnd:(NSString *)subCategoryID{
    
}

- (void)cleanProgressInfo:(float)value categoryKey:(NSString *)key path:(NSString *)path totalSize:(NSUInteger)totalSize
{
    [_delegate cleanProgressInfo:value];
}
- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize
{
    [_delegate cleanDidEnd:totalSize - leftSize];
    
    NSLog(@"lite cleanResultDidEnd: totalSize: %lu, leftSize:%lu", totalSize,leftSize);
}

- (void)cleanFileNums:(NSUInteger) cleanFileNums{
    
}

- (BOOL)checkWarnItemAtPath:(QMResultItem *)resultItem bundleID:(NSString **)bundle appName:(NSString **)name
{
    return [_parseManager checkWarnItemAtPath:resultItem bundleID:bundle appName:name];
}

@end
