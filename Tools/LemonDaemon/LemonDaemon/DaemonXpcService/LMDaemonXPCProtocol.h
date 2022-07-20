//
//  LMDaemonXPCProtocol.h
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#ifndef LMDaemonXPCProtocol_h
#define LMDaemonXPCProtocol_h

#import <Foundation/Foundation.h>
#import "McPipeStruct.h"

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@protocol LMDaemonXPCProtocol <NSObject>

//build
- (void)buildXPCConnectChannel;

// Replace the API of this protocol with an API appropriate to the service you are vending.
- (void)sendDataToDaemon:(NSData *)paramData withReply:(void (^)(NSData *))replyData;

@end

/*
 int clent :
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:
 
 //_connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.tencent.Lemon"];
 //for daemon/agent must use initWithMachServiceName to init, and the plist must set the (chown root:wheel plist)
 _connectionToService = [[NSXPCConnection alloc] initWithMachServiceName:@"com.tencent.LemonDaemon"
 _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMDaemonXPCProtocol)];
 [_connectionToService resume];
 
 Once you have a connection to the service, you can use it like this:
 
 [[_connectionToService remoteObjectProxy] sendDataToDaemon:nil withReply:^(NSData *replyData) {
 // We have received a response. Update our text field, but do it on the main thread.
 NSLog(@"Result replyData was: %@", replyData);
 }];
 
 And, when you are finished with the service, clean up the connection like this:
 
 [_connectionToService invalidate];
 
 
 in service :
 LMDaemonListenerDelegate *delegate = [LMDaemonListenerDelegate new];
 
 // Set up the one NSXPCListener for this service. It will handle all incoming connections.
 listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.tencent.LemonDaemon"];
 listener.delegate = delegate;
 
 // Resuming the serviceListener starts this service. This method does not return.
 [listener resume];
 */

#endif /* LMDaemonXPCProtocol_h */
