//
//  QMCleanManager.h
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMWarnReultItem.h"
#import "QMRemoveManager.h"
#import "QMXMLParseManager.h"

@protocol QMCleanManagerDelegate <NSObject>

- (void)scanCategoryStart:(QMCategoryItem *)item;
- (void)scanProgressInfo:(float)value
                scanPath:(NSString *)path
                category:(QMCategoryItem *)categoryItem
         subCategoryItem:(QMCategorySubItem *)subItem;
- (void)scanSubCategoryDidStart:(QMCategorySubItem *)subItem;
- (void)scanSubCategoryDidEnd:(QMCategorySubItem *)subItem;
- (void)scanCategoryDidEnd:(QMCategoryItem *)item;
- (void)scanCategoryAllDidEnd:(long long)num;

- (void)cleanCategoryStart:(QMCategoryItem *)categoryItem;
- (void)cleanCategoryEnd:(QMCategoryItem *)categoryItem;
- (void)cleanProgressInfo:(float)value item:(QMCategoryItem *)item path:(NSString *)path  totalSize:(NSUInteger)totalSize;
- (void)cleanSubCategoryStart:(QMCategorySubItem *)subCategoryItem;
- (void)cleanSubCategoryEnd:(QMCategorySubItem *)subCategoryItem;
- (void)cleanFileNums:(NSUInteger) cleanFileNums;
- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize;

@end

@interface QMCleanManager : NSObject
{
    NSDictionary * m_categoryDict;
    NSMutableDictionary * m_subCategoryDict;
    NSMutableDictionary * m_scanResultDict;
    id<QMCleanManagerDelegate> m_delegate;
    id<QMCleanManagerDelegate> m_bigDelegate;
    
    NSMutableArray * m_scanCategoryArray;
    
    QMCategoryItem * m_curCategoryItem;
    
    NSMutableArray * m_curScanCategoryArray;
    
    BOOL m_StopScan;
    
}

+ (QMCleanManager *)sharedManger;

- (void)parseCleanXMLItem;

//设置大清理界面的delegate-------后面会更改成 QMCleanManagerDelegate --》数据中心 ----》 小界面 | 大界面 订阅形式
-(void)setBigViewCleanDelegate:(id<QMCleanManagerDelegate>)bigDelegate;

// 开始扫描
- (void)customStartScan:(id<QMCleanManagerDelegate>)delegate array:(NSArray *)array;

- (BOOL)startCleaner;

- (void)stopScan;

- (NSArray *)warnResultItemArray;
- (BOOL)canRemoveWarnItem;
- (BOOL)cleanWarnResultItem:(id<QMCleanWarnItemDelegate>)delegate item:(QMWarnReultItem *)warnItem;
- (BOOL)isStopScan;
//如果文件夹文件数量特别巨大 每计算一千个文件回调一次主界面路径 其他全部不做回调
- (void)caculateSizeScanPath:(NSString *)path;

@end
