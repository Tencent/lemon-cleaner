//
//  McUninstallViewController.h
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMLocalApp.h"
#import "McUninstallWindowController.h"
#import <QMUICommon/QMBaseViewController.h>


@interface McUninstallViewController : QMBaseViewController

- (void)uninstallSoft:(LMLocalApp *)software;

@end
