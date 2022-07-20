//
//  LMScanViewController.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>

@interface LMScanViewController : QMBaseViewController
- (void)scan:(NSArray<NSString *> *)scanPaths;
@end
