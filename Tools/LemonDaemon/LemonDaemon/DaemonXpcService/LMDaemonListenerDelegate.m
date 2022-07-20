//
//  LMDaemonListenerDelegate.m
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMDaemonListenerDelegate.h"
#import "LMDaemonXPCProtocol.h"
#import "LMDaemonXPCService.h"
#import "LemonDaemonConst.h"
#import "LemonBizManager.h"
#import "LMLemonXPCProtocol.h"
#import "LMMonitorXPCProtocol.h"
#import <Libproc.h>
#import <dlfcn.h>

@implementation LMDaemonListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    // TODO: xpc authorization
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMDaemonXPCProtocol)];
    LMDaemonXPCService *exportedObject = [LMDaemonXPCService new];
    newConnection.exportedObject = exportedObject;
    char exe_path[MAXPATHLEN] = {0};
    NSString* path = nil;
    if (proc_pidpath(newConnection.processIdentifier, exe_path, sizeof(exe_path)) == 0)
    {
        path = @"";
    }
    else
    {
        path = [NSString stringWithUTF8String:exe_path];
        NSLog(@"LemonDaemon receive new connection exe_path == %@", path);
        if ([[path lastPathComponent] isEqualToString:[MAIN_APP_NAME stringByDeletingPathExtension]]) {
            newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMLemonXPCProtocol)];
            [LemonBizManager shareInstance].lemonCennection = newConnection;
        } else if ([[path lastPathComponent] isEqualToString:[MONITOR_APP_NAME stringByDeletingPathExtension]]) {
            newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMMonitorXPCProtocol)];
            [LemonBizManager shareInstance].monitorCennection = newConnection;
        }
    }
    
    // Resuming the connection allows the system to deliver more incoming messages.
    [newConnection resume];
    
    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end
