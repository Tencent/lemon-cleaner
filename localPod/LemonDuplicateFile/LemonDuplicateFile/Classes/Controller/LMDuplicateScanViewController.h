//
//  LMDuplicateScanViewController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/21.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMDuplicateWindowController.h"
#import <QMUICommon/QMBaseViewController.h>

@interface LMDuplicateScanViewController : QMBaseViewController

@property(nonatomic) NSArray* pathArray;
@property(nonatomic, weak) LMDuplicateWindowController *windowController;


- (void)stopScan;

@end
