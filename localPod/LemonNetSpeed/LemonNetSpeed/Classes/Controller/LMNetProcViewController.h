//
//  LMNetProcViewController.h
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>

@interface LMNetProcViewController : QMBaseViewController

+ (NSDictionary *)networkInfoItemWithPid:(id)pid name:(NSString *)processName icon:(NSImage *)image upSpeed:(NSNumber *)upSpeed downSpeed:(NSNumber *)downSpeed;
- (void)networkChange:(BOOL)isReachable;
@end
