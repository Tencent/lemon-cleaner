//
//  RunningAppPopViewController.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BrowserApp.h"
#import "PrivacyResultViewController.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface RunningAppPopViewController : QMBaseViewController

- (instancetype)initWithApps:(NSArray *)apps superController:(PrivacyResultViewController *)controller;

- (void)killSimpleAppAndCloseWindow:(BrowserApp *)app;

@property(nonatomic, retain) PrivacyData *data;

@property(nonatomic, weak) NSViewController *parentViewController;

@end
