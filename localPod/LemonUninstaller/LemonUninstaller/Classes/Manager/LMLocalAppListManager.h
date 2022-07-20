//
//  LMLocalSoftManager.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMLocalApp.h"

NS_ASSUME_NONNULL_BEGIN


//#define DebugAppUninstallScanBySerial  // 串行执行app卸载扫描工作.  不需要时,注释此宏定义.
//#define DebugNotUseBrewStrategy  // 不额外使用 brew 扫描策略



#define LMNotificationScanProgress             @"ScanProgressNotification"
#define LMNotificationScanInnerProgress        @"ScanProgressInnerNotification"
#define LMNotificationListChanged              @"NotificationListChanged"
#define LMKeyScanProgressTotal                 @"ScanProgressKeyTotal"
#define LMKeyScanProgressCurObject             @"ScanProgressKeyCurObject"
#define LMKeyScanProgressCurPhrase             @"ScanProgressCurPhrase"
#define LMKeyScanType                          @"KeyScanType"
#define LMScanTypeScanAll                      1
#define LMScanTypeScanIncrease                 2

enum
{
    LMSortTypeName = 0,
    LMSortTypeSize,
    LMSortTypeLastUsedDate
};
typedef NSInteger LMSortType;

@interface LMLocalAppListManager : NSObject
+ (id)defaultManager;
- (NSArray<LMLocalApp *> *)enumLocalAppsWithPath;
- (void)scanAllAppsItemAsync:(LMSortType)sortType  byAscendingOrder:(BOOL)ascendingOrder;
- (BOOL)fastScan:(LMSortType)sortType  byAscendingOrder:(BOOL)ascendingOrder;
- (NSArray<LMLocalApp *> *) appsListSortByType:(LMSortType)sortType byAscendingOrder:(BOOL) isAscending;
- (void) uninstall:(LMLocalApp *)app;
- (BOOL)isNeedFullScanBecauseOvertime; //超过一定时间需要重新全量扫描应用数据.
@property(nonatomic, strong, readonly) NSArray<LMLocalApp *> *appsList; // <<LMLocalApp *>
@property(nonatomic, assign) BOOL stopScaning; // <<LMLocalApp *>   //是否处于禁止扫描的状态(比如对应的窗口已经关闭)  ==>特别注意:卸载残留也是走的同一个扫描模块,触发时需要重置这个标志位.

@end

NS_ASSUME_NONNULL_END
