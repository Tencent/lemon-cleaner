//
//  LMMonitorTrashManager.h
//  LemonMonitor
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMCleanViewController.h"

typedef enum
{
    TrashScanNotStart = 0,
    TrashScaning,
    TrashScanEnd,
    TrashScanNeedReScan,  //主界面重新扫描后,需通知 Monitor 重新扫描.
    TrashCleaning
}QMMonitorTrashPhase;



@interface LMMonitorTrashManager : NSObject

@property(weak)   LMCleanViewController *delegate;  // 扫描清理 delegate
@property(assign) QMMonitorTrashPhase trashPhase;    // 所处的扫描阶段

- (void)startTrashScan;
- (NSInteger)getTrashSize;
- (void)cleanTrash;
+ (instancetype)sharedManager;


@end
