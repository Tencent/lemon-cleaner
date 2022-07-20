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

- (void)startScanCategory:(NSString *)categoryID;

- (void)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item;

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
    
    QMActionItem * m_curScanActionItem;
    QMCategorySubItem * m_curScanSubCategoryItem;
    QMCategoryItem * m_curScanCategoryItem;
    
    // 过滤判断
    int m_logicLevel;
    NSMutableArray * m_filterItemArray;
    
    float m_scanFlags;
    int m_scanCount;
    int m_curScanIndex;
}
@property (nonatomic, retain) NSDictionary * m_filerDict;
@property (nonatomic, weak) id<QMScanCategoryDelegate> delegate;
@property (nonatomic, assign) BOOL isStopScan;

- (void)startScanAllCategoryArray:(NSArray *)itemArray;
- (void)startQuickScanCategoryArray:(NSArray *)itemArray;

@end
