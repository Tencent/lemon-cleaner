//
//  LMCleanerDataCenter.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMCleanShowModel.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>
@class QMCategoryItem;

typedef enum {
    CleanStatusFirst,
    CleanStatusMainPage,
    CleanStatusScanProgress,
    CleanStatusScanResult,
    CleanStatusScanNoResult,
    CleanStatusCleanProgress,
    CleanStatusCleanResult,
} CleanStatus;

typedef enum {
    CleanCategoryStart = 0,
    CleanCategorySystem,
    CleanCategoryApp,
    CleanCategoryInternet,
}CleanCategory;

typedef enum {
    CleanSubcateSelectStatusNoSet = 0,
    CleanSubcateSelectStatusSelect,
    CleanSubcateSelectStatusDeselect,
}CleanSubcateSelectStatus;

@interface LMCleanerDataCenter : NSObject

@property (nonatomic, strong) NSMutableDictionary *m_subCategoryDict;
@property (nonatomic, assign) CGFloat progressValues;
@property (nonatomic, assign) BOOL isBigPage;
@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, assign) BOOL isCleanning;
@property (nonatomic, assign) UInt64 totalSize;
@property (nonatomic, assign) UInt64 totalSelectSize;
@property (nonatomic, assign) UInt64 cleanLeftSize;//清理过程中剩余大小
@property (nonatomic, assign) NSUInteger startScanTime;
@property (nonatomic, assign) NSUInteger startCleanTime;
@property (nonatomic, assign) UInt64 sysSelectSize;
@property (nonatomic, assign) UInt64 appSelectSize;
@property (nonatomic, assign) UInt64 intSelectSize;
@property (nonatomic, assign) NSInteger scanFileNumss;
@property (nonatomic, assign) CGFloat scanTimess;
@property (nonatomic, strong) NSMutableArray *subcateStatusArr;
@property (nonatomic, assign) QMFullDiskAuthorationStatus authStatus;//完全磁盘访问权限的状态，每次上来如果没有权限，在第一次扫描生命期间都是无权限，直到下一次扫描

+(id)shareInstance;

//增加一条清理记录 按照category来进行存储
-(void)addCleanRecordWithTotalSize:(UInt64) totalSize sysSize:(UInt64)sysSize appSize:(UInt64)appSize intSize:(UInt64)intSize cleanType:(NSInteger) cleanType fileNum:(NSUInteger) fileNum oprateTime:(NSUInteger) oprateTime;

//创建一个记录上一次选择的db
-(void)createLemonCleanerStatusTable;

//根据subcate初始化记录 --- 第一次初始化时候
-(void)addRecordIfNotExist:(QMCategoryItem *)cateItem;

//是否需要提示用户记录选择状态
-(BOOL)needTipUserSaveSubcateStatus;

//添加一条选中状态 到 待写入数据库中
-(void)addSubcateStatusToDatabaseWithId:(NSString *)subCateId selectStatus:(CleanSubcateSelectStatus) selectStatus;

//获取一条subcate选中状态
-(CleanSubcateSelectStatus)getSubcateStatusWithSubcateId:(NSString *)subCateId;

//remove all item
-(void)removeAllItemInSubCateArr;

//add to db
-(void)storeSubcateArrToDb;

//修改subcate的选中状态
-(void)changeSubcate:(NSString *)subCateId selectStatus:(CleanSubcateSelectStatus) selectStatus;

//获取subcate选中状态
-(CleanSubcateSelectStatus)getSubcateSelectStatus:(NSString *)subCateId;

//传入一个时间戳，获取最近七天总共数组值
-(UInt64)getSevenDaysTotalCleanSizeByTimeInterval:(NSTimeInterval) timeInterval;

//传入一个时间戳，获取最近七天的清理数值数组
-(NSArray *)getSevenDaysTotalCleanSizeArrByTimeInterval:(NSTimeInterval) timeInterval;

//传入一个时间戳，获取最近七天下表数组
-(NSArray *)getSevenDaysDateStrlByTimeInterval:(NSTimeInterval) timeInterval;

//传入一个时间戳 往前推七天获取cleanShowModel
-(NSArray *)getSevenDaysShowModelByTimeInterval:(NSTimeInterval) timeInterval;

//按照当天的时间戳来获取当日的LMCleanShowModel
-(LMCleanShowModel *)getCleanShowModelByTimeInterval:(NSUInteger) timeInterval;

//用户点击或者取消勾选item 刷新totalSelectSize
-(void)refreshTotalSelectSize;

-(void)setCategoryArray:(NSArray *)categoryArr;

-(NSArray *)getCategoryArray;

-(void)setCurrentCleanerStatus:(CleanStatus) status;

-(CleanStatus)getCurrentCleanerStatus;

//删除自适配软件 itemsize为0的项目
-(void)removeSoftAdaptSubItemSizeIsZero;

@end
