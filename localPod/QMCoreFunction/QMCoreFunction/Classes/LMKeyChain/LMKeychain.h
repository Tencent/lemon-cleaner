//
//  LMKeychain.m
//  LMKeychain
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

@interface LMKeychainItem : NSObject {
	NSString *myPassword;
	NSString *myUsername;
	NSString *myLabel;
	SecKeychainItemRef coreKeychainItem;
}

+ (void)lockKeychain;
+ (void)unlockKeychain;
+ (void)setLogsErrors:(BOOL)flag;
+ (BOOL)deleteKeychainItem:(LMKeychainItem*)kcItem error:(NSError**)error;

- (NSString *)password;
- (NSString *)username;
- (NSString *)label;
- (SecKeychainItemRef)coreKeychainItem;
- (BOOL)setPassword:(NSString *)newPassword;
- (BOOL)setUsername:(NSString *)newUsername;
- (BOOL)setLabel:(NSString *)newLabel;

@end 

@interface LMGenericKeychainItem : LMKeychainItem
{
	NSString *myServiceName;
}

+ (LMGenericKeychainItem *)genericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString;
+ (LMGenericKeychainItem *)addGenericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString password:(NSString *)passwordString;

+ (void) setKeychainPassword:(NSString*)password forUsername:(NSString*)username service:(NSString*)serviceName;
+ (NSString*) passwordForUsername:(NSString*)username service:(NSString*)serviceName;

+ (id)genericKeychainItem:(SecKeychainItemRef)item forServiceName:(NSString *)serviceName username:(NSString *)username password:(NSString *)password;
- (NSString *)serviceName;
- (BOOL)setServiceName:(NSString *)newServiceName;
@end

@interface LMInternetKeychainItem : LMKeychainItem
{
	NSString *myServer;
	NSString *myPath;
	int myPort;
	SecProtocolType myProtocol;
}

+ (LMInternetKeychainItem *)internetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol;
+ (LMInternetKeychainItem *)addInternetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString password:(NSString *)passwordString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol;

+ (id)internetKeychainItem:(SecKeychainItemRef)item forServer:(NSString *)server username:(NSString *)username password:(NSString *)password path:(NSString *)path port:(int)port protocol:(SecProtocolType)protocol;
- (NSString *)server;
- (NSString *)path;
- (int)port;
- (SecProtocolType)protocol;
- (BOOL)setServer:(NSString *)newServer;
- (BOOL)setPath:(NSString *)newPath;
- (BOOL)setPort:(int)newPort;
- (BOOL)setProtocol:(SecProtocolType)newProtocol;
@end
