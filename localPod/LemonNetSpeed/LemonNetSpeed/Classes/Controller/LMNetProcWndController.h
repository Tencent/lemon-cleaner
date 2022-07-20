//
//  LMNetProcWndController.h
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

@interface LMNetProcWndController : QMBaseWindowController
- (void)networkChange:(BOOL)isReachable;
@end
