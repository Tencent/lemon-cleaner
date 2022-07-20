//
//  LMCleanScanViewController.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/QMBaseViewController.h>
#define MAS_CLEAN_TRASH_FINISH @"mac_clean_trash_finish"  //垃圾清理


@interface LMCleanScanViewController : QMBaseViewController

@property (nonatomic, assign) long long fileMoveTotalNum;

- (void)showAnimate;

@end
