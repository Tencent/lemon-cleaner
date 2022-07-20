//
//  McUninstallDetailViewController.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMLocalApp.h"
#import <QMUICommon/QMBaseViewController.h>
NS_ASSUME_NONNULL_BEGIN

@interface McUninstallDetailViewController : QMBaseViewController

@property (nonatomic, strong) LMLocalApp *soft;

@end

NS_ASSUME_NONNULL_END
