//
//  LMDuplicateWindowController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/16.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>
@class QMDuplicateItemManager;

@interface LMDuplicateWindowController : QMBaseWindowController

@property(nonatomic) QMDuplicateItemManager *itemManager;

- (void)showBaseViewController ;

@end
