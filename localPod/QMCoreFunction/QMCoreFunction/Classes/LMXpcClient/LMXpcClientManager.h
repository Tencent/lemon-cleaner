//
//  LMXpcClientManager.h
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMXPCInterfaceDelegate.h"

@interface LMXpcClientManager : NSObject {
    
}

@property (nonatomic, strong) NSString *strLemonName;
@property (nonatomic, strong) NSString *strLemonMonitorName;
@property (nonatomic, weak) id<LMXPCInterfaceDelegate> delegate;

+ (LMXpcClientManager*)sharedInstance;
- (void)buildXPCConnectChannel;

// execute a command through xpc
- (NSData *)executeXPCCommandSync:(NSData *)paramData magic:(int)magic overtime:(int)MaxTime;
- (void)executeXPCCommand:(NSData *)paramData overtime:(int)MaxTime withReply:(void (^)(NSData *))replyData;
@end
