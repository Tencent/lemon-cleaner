//
//  PrivacyResultViewController.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyData.h"
#import <QMUICommon/QMBaseViewController.h>

@interface PrivacyResultViewController : QMBaseViewController

@property(readwrite, strong) PrivacyData *privacyData;

- (void)updateViewsBy:(PrivacyData *)data;

- (void)cleanActionWithRunningApps:(NSArray *)apps needKill:(BOOL)needKill;

- (void)openFullDiskAccessSettingGuidePage;

- (void)hostWindowWillClose; // 宿主的 windowController对应的 window 关闭时.

@end
