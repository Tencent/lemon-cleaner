//
//  PrivacyWindowController.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

@class PrivacyData;

@interface PrivacyWindowController : QMBaseWindowController

- (void)showDataResultViewController:(PrivacyData *)data;

- (void)showCleanProcessViewController:(PrivacyData *)data runningApps:(NSArray *)apps needKill:(BOOL)killFlag;

- (void)showCleanResultViewController:(PrivacyData *)data;

- (void)showScanViewController;

@end



/*
 ## 需要优化的点
 1. browser manager 需要考虑 浏览器的版本号, 考虑兼容性.
 2. 多语言
 3. category的说明
 4. 列表页 app 前面的 checkButton 按钮 是否需要.
 5. kill app 的弹出页时在 scan 时弹出 还是在 列表页弹出, 主要是考虑到 取消 按钮后的交互
 
 */
