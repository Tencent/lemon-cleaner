//
//  QMRemoveManager.m
//  QMCleaner
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMRemoveManager.h"
#import "QMCleanerUtils.h"
#import "QMCoreFunction/McCoreFunction.h"
#import "QMDataConst.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#include <sys/sysctl.h>

@interface QMRemoveManager() {
    int cleanedItemCount;
}
@property(nonatomic, strong) NSString *allShellString;
@end

@implementation QMRemoveManager


+ (QMRemoveManager *)getInstance
{
    QMRemoveManager * instance = [[QMRemoveManager alloc] init];
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        m_warnResultItemDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)_saveCleanResult:(UInt64)size
{
    // 配置保存
    // 上次清理的时间
    QMDataCenter * dataCenter = [QMDataCenter defaultCenter];
    [dataCenter setDouble:[[[QMNetworkClock sharedInstance] networkTime] timeIntervalSince1970]
                   forKey:kQMLastCleanTime];
    [dataCenter setObject:[NSNumber numberWithUnsignedLongLong:size]
                   forKey:kQMLastCleanSize];
    UInt64 totalCleanSize = [[dataCenter objectForKey:kQMTotalCleanSize] unsignedLongLongValue];
    totalCleanSize += size;
    [[QMDataCenter defaultCenter] setObject:[NSNumber numberWithUnsignedLongLong:totalCleanSize]
                                     forKey:kQMTotalCleanSize];
    
    // 今天清理的大小
    [QMCleanerUtils saveCurrentCleanSize:size];
}


// 调用CoreFunction 删除文件
- (void)removeItemWithCleanType:(NSArray *)array cleanType:(QMCleanType)type
{
    if ([McCoreFunction isAppStoreVersion]){
#ifdef DEBUG
        NSLog(@"debug not delete pathArray : %@", array);
#else
        if (array){
            NSLog(@"pathArray : %@", array);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            for (NSString *tempPath in array) {
                if(type == QMCleanTruncate){
                    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:tempPath];
                    if (file != nil)
                    {
                        [file truncateFileAtOffset:0];
                        [file closeFile];
                    }
                }else{
                    NSError *error;
                    [fileManager removeItemAtPath:tempPath error:&error];
                    NSLog(@"delete file error = %@", error);
                }
            }
        }
#endif
    } else {
        McCoreFunction * coreFunction = [McCoreFunction shareCoreFuction];
        McCleanRemoveType removeType = McCleanRemoveRoot;
        switch (type)
        {
                case QMCleanCutBinary:
                    removeType = McCleanCutBinaryRoot;
                    break;
                case QMCleanDeleteBinary:
                    removeType = McCleanCutBinaryRoot;
                    break;
                case QMCleanTruncate:
                    removeType = McCleanTruncateRoot;
                    break;
                case QMCleanDeletePackage:
                case QMCleanMoveTrash:
                    removeType = McCleanMoveTrashRoot;
                    break;
                case QMCleanRemoveLogin:
                    {
                        for (NSString * str in array)
                        [QMCleanerUtils removeUserLoginItem:str];
                        return;
                    }
                default:
                    break;
        }
        if (type == QMCleanSafariCookies)
        {
            NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            NSArray * cookies = [cookieStorage cookies];
            for (NSHTTPCookie * cookie in cookies)
            {
                [cookieStorage deleteCookie:cookie];
            }
        }
        if (type == QMCleanRemoveLanguage)
        {
            // 删除语言文件对当前文件夹lproj文件判断
            //        for (NSString * languageStr in array)
            //        {
            //            if ([QMCleanerUtils checkLanguageCanRemove:languageStr])
            //            {
            //                [coreFunction cleanItemAtPath:nil array:array removeType:removeType];
            //            }
            //        }
            
            [coreFunction cleanItemAtPath:nil array:array removeType:removeType];
        }
        else
        {
            [coreFunction cleanItemAtPath:nil array:array removeType:removeType];
        }
    }
}

// 检查删除ResultItem是否警告
- (BOOL)checkWarnResultItem:(QMResultItem *)resultItem
{
    // 需要警告操作
    NSString * bundle = nil;
    NSString * appName = nil;
    BOOL warnItem = NO;
    if ([_delegate respondsToSelector:@selector(checkWarnItemAtPath:bundleID:appName:)])
         warnItem = [_delegate checkWarnItemAtPath:resultItem
                                          bundleID:&bundle
                                           appName:&appName];
    if (warnItem)
    {
        pid_t pid = 0;
        NSString * warnAppPath = [QMCleanerUtils getPathWithRunProcess:bundle appName:appName pid:&pid];
        if (warnAppPath
            && [resultItem resultFileSize] != 0
            && pid != 0)
        {
            QMWarnReultItem * warnItem = [m_warnResultItemDict objectForKey:warnAppPath];
            if (!warnItem)
            {
                warnItem = [[QMWarnReultItem alloc] initWithPath:warnAppPath];
                warnItem.pid = pid;
            }
            [warnItem addResultPathArray:[[resultItem resultPath] allObjects] cleanType:resultItem.cleanType];
            warnItem.resultSize += [resultItem resultFileSize];
            [m_warnResultItemDict setObject:warnItem forKey:warnAppPath];
            return YES;
        }
    }
    return NO;
}

//// 遍历QMResultItem对象Array,删除结果
//- (NSUInteger)removeResultItemDict:(NSDictionary *)removeItemDict
//{
//    __block NSUInteger warnSize = 0;
//    // 清理项数量
//    NSUInteger totalKeyCount = 0;
//    for (NSString * categoryKey in removeItemDict.allKeys)
//    {
//        NSArray * removeItemArray = [removeItemDict objectForKey:categoryKey];
//        totalKeyCount += [removeItemArray count];
//    }
//    // 当前Queue
//    dispatch_queue_t myQueue = dispatch_queue_create("com.tencent.QMCleaner.checkwarn", 0);
//
//    __block int i = 0;
//    for (NSString * categoryKey in removeItemDict.allKeys)
//    {
//        NSArray * removeItemArray = [removeItemDict objectForKey:categoryKey];
//
//        // 多线程并发删除文件
//        dispatch_apply(removeItemArray.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
//
//            QMResultItem * resultItem = [removeItemArray objectAtIndex:index];
//            NSArray * array = [[resultItem resultPath] allObjects];
//            QMCleanType cleanType = resultItem.cleanType;
//
//            // 判断文件是否存在
//            NSUInteger resultSize = 0;
//            for (NSString * path in array)
//            {
//                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
//                {
//                    resultSize = [resultItem resultFileSize];
//                    break;
//                }
//            }
//
//            // 同步检查知否警告项
//            __block BOOL warnItem = NO;
//            dispatch_sync(myQueue, ^{
//                warnItem = [self checkWarnResultItem:resultItem];
//                if (warnItem)
//                    warnSize += resultSize;
//            });
//
//            // 不是警告项直接删除
//            if (!warnItem)
//            {
//                [self removeItemWithCleanType:array
//                                    cleanType:cleanType];
//            }
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                i++;
//                _removeAllSize -= (resultSize == 0 ? [resultItem resultFileSize] : 0);
//                // 获取进度信息
//                float progresss = (i + 0.0) / totalKeyCount;
//                // 计算删除大小
//                NSUInteger totalSize = [[m_curRemoveSizeDict objectForKey:categoryKey] unsignedIntegerValue];
//                if (!warnItem)
//                    totalSize = totalSize - resultSize;
//                [m_curRemoveSizeDict setObject:[NSNumber numberWithUnsignedInteger:totalSize]
//                                        forKey:categoryKey];
//                self.cleanFileNums += [array count];
//                // 刷新主界面
//                [_delegate cleanProgressInfo:progresss
//                                 categoryKey:categoryKey
//                                        path:([array count] > 0 ? [array objectAtIndex:0] : nil)
//                                   totalSize:totalSize];
//            });
//            [NSThread sleepForTimeInterval:(4.0 / totalKeyCount)];
//        });
//    }
//    // 释放queue
//    //dispatch_release(myQueue);
//     dispatch_async(dispatch_get_main_queue(), ^{
//         [_delegate cleanFileNums:self.cleanFileNums];
//     });
//    // 保存配置
//    [self _saveCleanResult:(_removeAllSize - warnSize)];
//
//    return warnSize;
//}

// 遍历QMResultItem对象Array,删除结果
- (NSUInteger)removeResultItemDict:(NSDictionary *)removeItemDict categoryId:(NSString *)categoryId totalCount:(NSInteger)totalCount
{
    __block NSUInteger warnSize = 0;
//    // 清理项数量
//    NSUInteger totalKeyCount = 0;
//    for (NSString * categoryKey in removeItemDict.allKeys)
//    {
//        NSArray * removeItemArray = [removeItemDict objectForKey:categoryKey];
//        totalKeyCount += [removeItemArray count];
//    }
    // 当前Queue
    __weak QMRemoveManager *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        
        [strongSelf->_delegate cleanCategoryStart:categoryId];
    });
    
//    dispatch_queue_t myQueue = dispatch_queue_create("com.tencent.QMCleaner.checkwarn", 0);
    
//    __block int i = 0;
    NSArray *keys = removeItemDict.allKeys;
    NSArray *sortKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [((NSString *)obj1) compare:obj2];
    }];
    for (NSString * categoryKey in sortKeys)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            QMRemoveManager *strongSelf = weakSelf;
            
            [strongSelf->_delegate cleanSubCategoryStart:categoryKey];
        });
        
        NSArray * removeItemArray = [removeItemDict objectForKey:categoryKey];
        
        // 多线程并发删除文件
        dispatch_apply(removeItemArray.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
            QMRemoveManager *strongSelf = weakSelf;
            
            QMResultItem * resultItem = [removeItemArray objectAtIndex:index];
            NSArray * array = [[resultItem resultPath] allObjects];
            QMCleanType cleanType = resultItem.cleanType;
            
            // 判断文件是否存在
            NSUInteger resultSize = 0;
        
            for (NSString * path in array)
            {
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    resultSize = [resultItem resultFileSize];
                    break;
                }
            }
//            // 同步检查知否警告项
//            __block BOOL warnItem = NO;
//            dispatch_sync(myQueue, ^{
//                warnItem = [self checkWarnResultItem:resultItem];
//                if (warnItem)
//                    warnSize += resultSize;
//            });
            
            // 不是警告项直接删除
//            if (!warnItem)
//            {
            if(QMCleanDeleteBinary == cleanType) {
                [self deleteGeneralBinary:resultItem];
            } else {
                [strongSelf removeItemWithCleanType:array
                                    cleanType:cleanType];
            }
                
//            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
//                i++;
                strongSelf->cleanedItemCount++;
                strongSelf->_removeAllSize -= (resultSize == 0 ? [resultItem resultFileSize] : 0);
                // 获取进度信息
                float progresss = (strongSelf->cleanedItemCount + 0.0) / totalCount;
//                NSLog(@"total count %ld, i:%d, progress:%f ", totalCount, self->cleanedItemCount, progresss);
                // 计算删除大小
                NSUInteger totalSize = [[strongSelf->m_curRemoveSizeDict objectForKey:categoryKey] unsignedIntegerValue];
                NSUInteger cleanSize = resultSize;
//                if (!warnItem)
//                {
                    totalSize = totalSize - resultSize;
//                }
                
//                if (warnItem){
//                    cleanSize = 0;
//                }
                
                [strongSelf->m_curRemoveSizeDict setObject:[NSNumber numberWithUnsignedInteger:totalSize]
                                        forKey:categoryKey];
                
                if(QMCleanDeleteBinary == cleanType || QMCleanDeletePackage == cleanType) {
                    strongSelf.cleanFileNums ++;
                } else {
                    strongSelf.cleanFileNums += [array count];
                }
                
                // 刷新主界面
                [strongSelf->_delegate cleanProgressInfo:progresss
                                 categoryKey:categoryId
                                        path:([array count] > 0 ? [array objectAtIndex:0] : nil)
                                   totalSize:cleanSize];
            });
            [NSThread sleepForTimeInterval:(4.0 / totalCount)];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            QMRemoveManager *strongSelf = weakSelf;
            
            [strongSelf->_delegate cleanSubCategoryEnd:categoryKey ];
        });
    }
    // 释放queue
    //dispatch_release(myQueue);
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        
        [strongSelf->_delegate cleanFileNums:strongSelf.cleanFileNums];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        [strongSelf->_delegate cleanCategoryEnd:categoryId];
    });
    // 保存配置
    [self _saveCleanResult:(_removeAllSize - warnSize)];
    
    return warnSize;
}

- (void)processLanguageItemArray:(NSMutableDictionary *)removeItemDict {
    NSMutableDictionary * systemRubbishCategory = [removeItemDict objectForKey:@"1"];
    NSArray * removeLanguageItemArray = [systemRubbishCategory objectForKey:@"1003"];
    // 过滤语言，始终保持一个语言
    NSMutableArray * removeLanguageArray = [NSMutableArray array];
    if ([removeLanguageItemArray count] > 0)
    {
        NSArray * laungageArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        
        // 按照软件路径将改软件需要删除的语言分类
        NSMutableDictionary * languageDict = [NSMutableDictionary dictionary];
        NSMutableDictionary * languageItemDict = [NSMutableDictionary dictionary];
        for (QMResultItem * resultItem in removeLanguageItemArray)
        {
            if (!resultItem.path)
                continue;
            if (!resultItem.languageKey)
                continue;
            NSMutableArray * array = [languageDict objectForKey:resultItem.path];
            if (!array) array = [NSMutableArray array];
            [array addObject:resultItem.languageKey];
            [languageDict setObject:array forKey:resultItem.path];
            
            
            array = [languageItemDict objectForKey:resultItem.path];
            if (!array) array = [NSMutableArray array];
            [array addObject:resultItem];
            [languageItemDict setObject:array forKey:resultItem.path];
        }
        
        NSArray *keepLanguages = [[QMDataCenter defaultCenter] objectForKey:kQMCleanerKeepLanguages];
        for (NSString * key in languageDict.allKeys)
        {
            NSBundle * bundle = [NSBundle bundleWithPath:key];
            NSArray * localizationsArray = [bundle localizations];
            NSString * keepLanguage = nil;
            // 如果当前没有默认不过滤语言，根据系统语言顺序保留一个
            BOOL haveDefault = NO;
            for (NSString * curLanguage in localizationsArray)
            {
                NSString * languageID = [NSLocale canonicalLanguageIdentifierFromString:curLanguage];
                NSRange range = [languageID rangeOfString:@"-"];
                if (range.length != 0)
                {
                    languageID = [languageID substringToIndex:range.location];
                }
                if ([keepLanguages containsObject:languageID])
                {
                    haveDefault = YES;
                    break;
                }
            }
            // 语言全部选择了，过滤一个
            if (!haveDefault && [localizationsArray count] <= [[languageDict objectForKey:key] count])
            {
                NSArray * array = [languageDict objectForKey:key];
                for (NSString * sysLanguage in laungageArray)
                {
                    if ((int)[array indexOfObject:sysLanguage] != -1)
                    {
                        keepLanguage = sysLanguage;
                        break;
                    }
                }
            }
            // 过滤语言
            for (QMResultItem * item in [languageItemDict objectForKey:key])
            {
                if (keepLanguage && [item.languageKey isEqualToString:keepLanguage])
                    continue;
                [removeLanguageArray addObject:item];
            }
        }
    }
    
    if (removeLanguageArray && [removeLanguageArray count] > 0)
        [systemRubbishCategory setObject:removeLanguageArray forKey:@"1003"];
}

// 删除文件
- (NSUInteger)cleanItemWithDictionary:(NSMutableDictionary *)removeItemDict categoryId:(NSString *)categoryId totalCount:(NSInteger)totalCount
{
    // 警告文件大小
    NSUInteger warnSize = 0;
    // 删除文件
    warnSize += [self removeResultItemDict:removeItemDict categoryId:categoryId totalCount:totalCount];
    
    
    
    return warnSize;
}


//// 删除文件
//- (NSUInteger)cleanItemWithDictionary:(NSMutableDictionary *)removeItemDict
//{
//    // 获取语言对象
//    NSArray * removeLanguageItemArray = [removeItemDict objectForKey:@"103"];
//    // 过滤语言，始终保持一个语言
//    NSMutableArray * removeLanguageArray = [NSMutableArray array];
//    if ([removeLanguageItemArray count] > 0)
//    {
//        NSArray * laungageArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
//
//        // 按照软件路径将改软件需要删除的语言分类
//        NSMutableDictionary * languageDict = [NSMutableDictionary dictionary];
//        NSMutableDictionary * languageItemDict = [NSMutableDictionary dictionary];
//        for (QMResultItem * resultItem in removeLanguageItemArray)
//        {
//            if (!resultItem.path)
//                continue;
//            NSMutableArray * array = [languageDict objectForKey:resultItem.path];
//            if (!array) array = [NSMutableArray array];
//            [array addObject:resultItem.languageKey];
//            [languageDict setObject:array forKey:resultItem.path];
//
//
//            array = [languageItemDict objectForKey:resultItem.path];
//            if (!array) array = [NSMutableArray array];
//            [array addObject:resultItem];
//            [languageItemDict setObject:array forKey:resultItem.path];
//        }
//
//        NSArray *keepLanguages = [[QMDataCenter defaultCenter] objectForKey:kQMCleanerKeepLanguages];
//        for (NSString * key in languageDict.allKeys)
//        {
//            NSBundle * bundle = [NSBundle bundleWithPath:key];
//            NSArray * localizationsArray = [bundle localizations];
//            NSString * keepLanguage = nil;
//            // 如果当前没有默认不过滤语言，根据系统语言顺序保留一个
//            BOOL haveDefault = NO;
//            for (NSString * curLanguage in localizationsArray)
//            {
//                NSString * languageID = [NSLocale canonicalLanguageIdentifierFromString:curLanguage];
//                NSRange range = [languageID rangeOfString:@"-"];
//                if (range.length != 0)
//                {
//                    languageID = [languageID substringToIndex:range.location];
//                }
//                if ([keepLanguages containsObject:languageID])
//                {
//                    haveDefault = YES;
//                    break;
//                }
//            }
//            // 语言全部选择了，过滤一个
//            if (!haveDefault && [localizationsArray count] <= [[languageDict objectForKey:key] count])
//            {
//                NSArray * array = [languageDict objectForKey:key];
//                for (NSString * sysLanguage in laungageArray)
//                {
//                    if ((int)[array indexOfObject:sysLanguage] != -1)
//                    {
//                        keepLanguage = sysLanguage;
//                        break;
//                    }
//                }
//            }
//            // 过滤语言
//            for (QMResultItem * item in [languageItemDict objectForKey:key])
//            {
//                if (keepLanguage && [item.languageKey isEqualToString:keepLanguage])
//                    continue;
//                [removeLanguageArray addObject:item];
//            }
//        }
//    }
//
//    if (removeLanguageArray && [removeLanguageArray count] > 0)
//        [removeItemDict setObject:removeLanguageArray forKey:@"103"];
//
//    // 警告文件大小
//    NSUInteger warnSize = 0;
//    // 删除文件
//    warnSize += [self removeResultItemDict:removeItemDict];
//
//
//
//    return warnSize;
//}

//- (BOOL)startCleaner:(NSDictionary *)resultDict
//{
//    NSLog(@"%p, %p", self, self.class);
//    [QMRemoveManager getInstance];
//    [QMRemoveManager.class getInstance];
//    [self.class getInstance];
//    NSUInteger removeAllSize = 0;
//    //BOOL removeAll = YES;
//    //NSMutableArray * removeItemArray = [NSMutableArray array];
//    m_curRemoveSizeDict = [NSMutableDictionary dictionary];
//    NSMutableDictionary * removeItemDict = [NSMutableDictionary dictionary];
//
//    for (NSString * key in resultDict.allKeys)
//    {
//        NSUInteger removeSize = 0;
//        for (QMResultItem * item in [resultDict objectForKey:key])
//        {
//            removeSize += [item resultFileSize];
//        }
//        NSArray * array = [resultDict objectForKey:key];
//        if ([array count] > 0)
//            [removeItemDict setObject:array forKey:key];
//        [m_curRemoveSizeDict setObject:[NSNumber numberWithUnsignedInteger:removeSize]
//                                forKey:key];
//        removeAllSize += removeSize;
//    }
//    _removeAllSize = removeAllSize;
//
//    if ([removeItemDict count] == 0)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [_delegate cleanResultDidEnd:_removeAllSize leftSize:0];
//        });
//        return NO;
//    }
//    // 删除文件线程
//    if ([NSThread isMainThread])
//    {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//            NSUInteger warnSize = [self cleanItemWithDictionary:removeItemDict];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_delegate cleanResultDidEnd:_removeAllSize leftSize:warnSize];
//            });
//        });
//    }
//    else
//    {
//        NSUInteger warnSize = [self cleanItemWithDictionary:removeItemDict];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [_delegate cleanResultDidEnd:_removeAllSize leftSize:warnSize];
//        });
//    }
//    return YES;
//}

- (NSInteger)getTotalCount:(NSMutableDictionary *)dict
{
    NSInteger totalCount =0;
    for (NSString * key in dict.allKeys)
    {
        NSMutableDictionary * subItemDict = [dict objectForKey:key];
        for (NSMutableDictionary * subItemKey in subItemDict.allKeys)
        {
            NSArray *array = [subItemDict objectForKey:subItemKey];
            totalCount += array.count;
        }
    }
    return totalCount;
}



- (void)processClean:(NSMutableDictionary *)resultDict actionSource:(QMCleanerActionSource)source {
    
    NSInteger totalwarnSize = 0;
    self->cleanedItemCount = 0;
    [self processLanguageItemArray:resultDict];
    NSInteger totalCount = [self getTotalCount:resultDict];
    for (NSString *key in resultDict.allKeys) {
        NSMutableDictionary * subItemDict = [resultDict objectForKey:key];
        NSUInteger warnSize = [self cleanItemWithDictionary:subItemDict categoryId:key totalCount:totalCount];
        totalwarnSize += warnSize;
    }
    __weak QMRemoveManager *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        
        [strongSelf->_delegate cleanResultDidEnd:strongSelf->_removeAllSize leftSize:totalwarnSize];
    });
}

- (BOOL)startCleaner:(NSMutableDictionary *)resultDict actionSource:(QMCleanerActionSource)source
{
    __weak QMRemoveManager *weakSelf = self;
    NSLog(@"%p, %p, startCleaner", self, self.class);
    [QMRemoveManager getInstance];
    [QMRemoveManager.class getInstance];
    [self.class getInstance];
    NSUInteger removeAllSize = 0;
    //BOOL removeAll = YES;
    //NSMutableArray * removeItemArray = [NSMutableArray array];
    m_curRemoveSizeDict = [NSMutableDictionary dictionary];
    NSMutableDictionary * removeItemDict = [NSMutableDictionary dictionary];
    self.cleanFileNums = 0;

    for (NSString * key in resultDict.allKeys)
    {
        NSMutableDictionary * subItemDict = [resultDict objectForKey:key];
        for (NSString * subItemKey in subItemDict.allKeys)
        {
            NSUInteger removeSize = 0;
            NSMutableArray *array = [subItemDict objectForKey:subItemKey];
            for (QMResultItem *item in array)
            {
                removeSize += [item resultFileSize];
            }
            [m_curRemoveSizeDict setObject:[NSNumber numberWithUnsignedInteger:removeSize]
                                    forKey:subItemKey];
            removeAllSize += removeSize;
        }
        NSMutableDictionary * dict = [resultDict objectForKey:key];
        [removeItemDict setObject:dict forKey:key];
        
    }
    _removeAllSize = removeAllSize;
    
    if ([removeItemDict count] == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            QMRemoveManager *strongSelf = weakSelf;
            
            [strongSelf->_delegate cleanResultDidEnd:strongSelf->_removeAllSize leftSize:0];
        });
        return NO;
    }
    // 删除文件线程
    if ([NSThread isMainThread])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            QMRemoveManager *strongSelf = weakSelf;
            
            [strongSelf processClean:removeItemDict actionSource:source];
        });
    }
    else
    {
        [self processClean:removeItemDict actionSource:source];
    }
    return YES;
}

- (void)removeWarnItem
{    
    [m_warnResultItemDict removeAllObjects];
}

- (void)deleteGeneralBinary:(QMResultItem *)resultItem {
    McCoreFunction * coreFunction = [McCoreFunction shareCoreFuction];
    
    if (resultItem != nil) {
        for (NSString *path  in [resultItem resultPath]) {

            if (resultItem.binaryType == AppBinaryType_X86) {
                [coreFunction cutunlessBinary:path array:@[path] removeType:1];
            } else if (resultItem.binaryType == AppBinaryType_Arm64)  {
                [coreFunction cutunlessBinary:path array:@[path] removeType:2];
            } else {
                if ([self isRunOnAppleSilicon]) {
                    [coreFunction cutunlessBinary:path array:@[path] removeType:2];
                } else {
                    [coreFunction cutunlessBinary:path array:@[path] removeType:1];
                }
            }
        }
    }
}

#pragma mark-

- (BOOL)isRunOnAppleSilicon {
    BOOL result = NO;
    if (@available(macOS 11, *)) {
        char buf[100];
        size_t buflen = 100;
        sysctlbyname("machdep.cpu.brand_string", &buf, &buflen, NULL, 0);
        NSString *cupArch = [[NSString alloc] initWithCString:(char*)buf encoding:NSASCIIStringEncoding];
        if ([cupArch containsString:@"Apple"]) {
            result = YES;
        } else {
            result = NO;
        }
    }
    return result;
}


#pragma mark 删除警告项

- (NSArray *)warnResultItemArray
{
    return m_warnResultItemDict.allValues;
}
- (void)removeReusltItem:(NSString *)warnItemPath
{
    if (!warnItemPath)
        return;
    QMWarnReultItem * warnItem = [m_warnResultItemDict objectForKey:warnItemPath];
    if (!warnItem)
        return;
    
    __weak QMRemoveManager *weakSelf = self;
    
    // 开始删除文件
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        
        [strongSelf->_warnItemDelegate startRemoveWarnItem:warnItem];
    });
    // 删除文件
    NSDictionary * dict = warnItem.resultPathDict;
    for (NSString * key in [dict allKeys])
    {
        QMCleanType cleanType = [key intValue];
        [self removeItemWithCleanType:[dict objectForKey:key] cleanType:cleanType];
        [NSThread sleepForTimeInterval:2];
    }
    // 删除完成
    dispatch_async(dispatch_get_main_queue(), ^{
        QMRemoveManager *strongSelf = weakSelf;
        
        if (warnItem.showPath)
            [strongSelf->m_warnResultItemDict removeObjectForKey:warnItem.showPath];
        [strongSelf->_warnItemDelegate removeWarnItemEnd:warnItem];
        // 保存配置
        [strongSelf _saveCleanResult:[warnItem resultSize]];
    });
}
- (BOOL)canRemoveWarnItem
{
    for (QMWarnReultItem * warnItem in m_warnResultItemDict.allValues)
    {
        if (warnItem.selected)
        {
            pid_t pid = 0;
            // 获取关闭程序pid
            NSBundle * bundle = [NSBundle bundleWithPath:warnItem.showPath];
            [QMCleanerUtils getPathWithRunProcess:[bundle bundleIdentifier] appName:nil pid:&pid];
            if (pid == 0)
                continue;
            
            NSRunningApplication * runningApp = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
            if (runningApp)
            {
                if (![runningApp terminate])
                    return NO;
                int i = 0;
                BOOL goOn = NO;
                while (YES)
                {
                    runningApp = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
                    if (!runningApp)
                    {
                        goOn = YES;
                        break;
                    }
                    if (i == 200)
                    {
                        [runningApp activateWithOptions:NSApplicationActivateAllWindows];
                        break;
                    }
                    i++;
                }
                if (goOn)
                    continue;
                else
                    return NO;
            }
        }
    }
    return YES;
}
- (BOOL)cleanWarnResultItem:(QMWarnReultItem *)warnItem
{
    pid_t pid = 0;
    // 获取关闭程序pid
    NSBundle * bundle = [NSBundle bundleWithPath:warnItem.showPath];
    [QMCleanerUtils getPathWithRunProcess:[bundle bundleIdentifier] appName:nil pid:&pid];
    if (pid == 0)
    {
        [self removeReusltItem:warnItem.showPath];
        return YES;
    }
    return NO;
}

@end
