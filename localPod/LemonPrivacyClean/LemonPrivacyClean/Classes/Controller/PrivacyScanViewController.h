//
//  ScanViewController.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScanDelegate.h"
#import <QMUICommon/QMBaseViewController.h>


@interface PrivacyScanViewController : QMBaseViewController

- (instancetype)init:(ScanType)type;

- (void)startToCleanWithData:(PrivacyData *)data runningApps:(NSArray *)apps needKill:(BOOL)killFlag;

- (void)startToScan;

- (void)cancelScanPrivateData;

- (void)startToInnerScan:(NSArray *)apps needKill:(BOOL)killFlag;


@end

