//
//  LMDaemonXPCService.h
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMDaemonXPCProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface LMDaemonXPCService : NSObject <LMDaemonXPCProtocol>

@end
