//
//  LMMainViewController.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
#import <LemonClener/LMCleanScanViewController.h>

@interface LMMainViewController : QMBaseViewController

@property (strong, nonatomic) LMCleanScanViewController *scanViewContoller;

- (void)showAnimate;

@end
