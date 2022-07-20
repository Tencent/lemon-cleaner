//
//  MASXpcInterface.h
//  LemonASMonitor
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

// 用于 mas 版本,主界面和 monitor 进行通信.
@protocol MASXPCAgent

-(void)sendMessage:(NSString *)message;

@end
