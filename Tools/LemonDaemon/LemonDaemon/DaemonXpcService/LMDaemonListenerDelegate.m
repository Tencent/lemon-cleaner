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

static BOOL _isAllowedClientIdentifier(NSString *identifier)
{
    return [identifier isEqualToString:MAIN_APP_BUNDLEID] ||
           [identifier isEqualToString:MONITOR_APP_BUNDLEID];
}

static BOOL _evaluateRequirement(SecCodeRef code, NSString *requirementString)
{
    if (code == NULL || requirementString.length == 0) {
        return NO;
    }
    SecRequirementRef requirement = NULL;
    OSStatus status = SecRequirementCreateWithString((__bridge CFStringRef)requirementString,
                                                     kSecCSDefaultFlags,
                                                     &requirement);
    if (status != errSecSuccess || requirement == NULL) {
        NSLog(@"[security] SecRequirementCreateWithString failed: %d", (int)status);
        return NO;
    }
    status = SecCodeCheckValidity(code, kSecCSDefaultFlags, requirement);
    CFRelease(requirement);
    return status == errSecSuccess;
}

// 强制 Team ID + identifier。禁止再用「仅 identifier」作为生产回退。
static BOOL _verifyConnectingClient(audit_token_t token)
{
    NSData *auditData = [NSData dataWithBytes:&token length:sizeof(token)];
    NSDictionary *attrs = @{ (__bridge NSString *)kSecGuestAttributeAudit : auditData };
    SecCodeRef code = NULL;
    OSStatus status = SecCodeCopyGuestWithAttributes(NULL,
                                                     (__bridge CFDictionaryRef)attrs,
                                                     kSecCSDefaultFlags,
                                                     &code);
    if (status != errSecSuccess || code == NULL) {
        NSLog(@"[security] SecCodeCopyGuestWithAttributes failed: %d", (int)status);
        return NO;
    }

    NSString *prodRequirement = [NSString stringWithFormat:
                                 @"anchor apple generic and certificate leaf [subject.OU] = \"%@\" and "
                                 @"(identifier \"%@\" or identifier \"%@\")",
                                 LEMON_TEAM_ID, MAIN_APP_BUNDLEID, MONITOR_APP_BUNDLEID];

    BOOL accepted = _evaluateRequirement(code, prodRequirement);
#ifdef DEBUG
    if (!accepted) {
        // 仅本地 Xcode：允许本机 Apple Development 签名。Release 绝不走此路径。
        NSString *debugRequirement = [NSString stringWithFormat:
                                      @"anchor apple generic and (identifier \"%@\" or identifier \"%@\")",
                                      MAIN_APP_BUNDLEID, MONITOR_APP_BUNDLEID];
        if (_evaluateRequirement(code, debugRequirement)) {
            NSLog(@"[security] DEBUG-only identifier fallback accepted. Release builds reject this path.");
            accepted = YES;
        }
    }
#endif
    if (!accepted) {
        NSLog(@"[security] client requirement check failed");
        CFRelease(code);
        return NO;
    }

    CFDictionaryRef signingInfoRef = NULL;
    status = SecCodeCopySigningInformation(code, kSecCSSigningInformation, &signingInfoRef);
    CFRelease(code);
    if (status != errSecSuccess || signingInfoRef == NULL) {
        NSLog(@"[security] SecCodeCopySigningInformation failed: %d", (int)status);
        return NO;
    }

    NSDictionary *signingInfo = CFBridgingRelease(signingInfoRef);
    NSString *identifier = signingInfo[(__bridge NSString *)kSecCodeInfoIdentifier];
    NSString *teamID = signingInfo[(__bridge NSString *)kSecCodeInfoTeamIdentifier];

    if (!_isAllowedClientIdentifier(identifier)) {
        NSLog(@"[security] reject client identifier: %@", identifier);
        return NO;
    }

#ifndef DEBUG
    if (![LEMON_TEAM_ID isEqualToString:teamID]) {
        NSLog(@"[security] reject Team ID: %@ (expected %@)", teamID, LEMON_TEAM_ID);
        return NO;
    }
#else
    if (![LEMON_TEAM_ID isEqualToString:teamID]) {
        NSLog(@"[security] DEBUG-only: Team ID %@ is not Tencent; identifier=%@", teamID, identifier);
    }
#endif

    NSLog(@"[security] accept client identifier=%@ team=%@", identifier, teamID);
    return YES;
}

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
#ifdef DEBUG
        NSLog(@"LemonDaemon receive new connection exe_path == %@", path);
#endif
        if ([[path lastPathComponent] isEqualToString:[MAIN_APP_NAME stringByDeletingPathExtension]]) {
            newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMLemonXPCProtocol)];
            [LemonBizManager shareInstance].lemonCennection = newConnection;
        } else if ([[path lastPathComponent] isEqualToString:[MONITOR_APP_NAME stringByDeletingPathExtension]]) {
            newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMMonitorXPCProtocol)];
            [LemonBizManager shareInstance].monitorCennection = newConnection;
        }
    }

    [newConnection resume];
    
    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end
