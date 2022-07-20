//
//  LMXPCInterfaceDelegate.h
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMXPCInterfaceDelegate <NSObject>
- (void)receiveData:(NSData *)rData;
- (void)receiveDictionary:(NSDictionary *)rDic;
@end

/*
 int clent :
 1. implement LMXPCInterfaceDelegate
 2. [[LMXpcClientManager sharedInstance] setDelegate:];
 3. [[LMXpcClientManager sharedInstance] buildXPCConnectChannel];
 ps: 2 and 3, dispatch_after 2 second in the applictionDidFinishLaunch
 */
