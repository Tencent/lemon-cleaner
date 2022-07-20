//
//  McUninstallWindowController.h
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

@class LMLocalApp;

@protocol UninstallWindowProtocol
- (void)showUninstallListView;
- (void)showUninstallDetailViewWithSoft:(LMLocalApp *)soft;
- (void)uninstallSoft:(LMLocalApp *)soft;
@end


@interface McUninstallWindowController : QMBaseWindowController <UninstallWindowProtocol>

@end
