//
//  QMScanCategory.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCategoryItem.h"
#import "QMFilterItem.h"

#define kScanProgressNotification    @"ScanProgressNotification"
#define kScanEndNotification    @"ScanEndNotification"

@protocol QMScanCategoryDelegate <NSObject>

- (void)scanCategoryArray:(NSArray *)array;

/// 开始扫描 大类，子类，不包含action 的回调
- (void)startScanCategory:(NSString *)categoryID;

/// 扫描 action 的回调
- (void)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item actionItem:(QMActionItem *)actionItem;

/// 结束扫描 大类，子类，不包含action 的回调
- (void)scanCategoryDidEnd:(NSString *)categoryID;

@end

@class QMAppUnlessFile;
@class QMBrokenRegister;
@class QMDirectoryScan;
@class QMAppLeftScan;
@class QMMailScan;
@class QMSoftScan;
@class QMXcodeScan;
@class QMWechatScan;

@interface QMScanCategory : NSObject
{    
    QMAppUnlessFile * m_appUnlessFile;
    QMBrokenRegister * m_brokenRegister;
    QMDirectoryScan * m_directoryScan;
    QMAppLeftScan * m_appLeftScan;
    QMMailScan *m_mailScan;
    QMSoftScan *m_softScan;
    QMXcodeScan *m_xcodeScan;
    QMWechatScan *m_wechatScan;
  
//。业务逻辑其实并不关心当前action是哪个，进度多少
//    QMActionItem * m_curScanActionItem;
    QMCategorySubItem * m_curScanSubCategoryItem;
    QMCategoryItem * m_curScanCategoryItem;
    
    // 过滤判断
    int m_logicLevel;
    NSMutableArray * m_filterItemArray;
    
    float m_scanFlags;
    int m_scanCount;
    
    // 去掉 m_curScanIndex，现在并发之后，计数更好, 每个subcategory中已经完成的actionitem的数量，进度用（虽然目前看进度没有地方用到）
    //int m_curScanIndex;
    int m_curFinishedScanActionItemCount;
}
@property (nonatomic, retain) NSDictionary * m_filerDict;
@property (nonatomic, weak) id<QMScanCategoryDelegate> delegate;

// 原子的
@property (atomic, assign) BOOL isStopScan;

- (void)startScanAllCategoryArray:(NSArray *)itemArray;
- (void)startQuickScanCategoryArray:(NSArray *)itemArray;

@end
