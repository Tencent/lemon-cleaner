//
//  LMKeychain.m
//  LMKeychain
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.

#import "LMKeychain.h"

@interface LMKeychainItem (Private)
- (BOOL)modifyAttributeWithTag:(SecItemAttr)attributeTag toBeString:(NSString *)newStringValue;
@end

@implementation LMKeychainItem

static BOOL _logErrors;

+ (void)lockKeychain {
	SecKeychainLock(NULL);
}
+ (void)unlockKeychain {
	SecKeychainUnlock(NULL, 0, NULL, NO);
}
+ (void)setLogsErrors:(BOOL)flag {
	_logErrors = flag;
}
+(BOOL)deleteKeychainItem:(LMKeychainItem*)kcItem error:(NSError**)error {
	OSStatus returnStatus = SecKeychainItemDelete([kcItem coreKeychainItem]);
	if (returnStatus != noErr)
	{
		NSString *errorText = [NSString stringWithFormat: @"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus)];
		NSLog(@"%@", errorText);
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue: errorText forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"LMKeychainErrorDomain" code:returnStatus userInfo:errorDetail];
		return NO;
	} else {
		return YES;
	}
}

- (id)initWithCoreKeychainItem:(SecKeychainItemRef)item username:(NSString *)username password:(NSString *)password {
	if (self = [super init]) 	{
		coreKeychainItem = item;
		[self setValue:username forKey:@"myUsername"];
		[self setValue:password forKey:@"myPassword"];
	}
	return self;
}

- (NSString *)password {
	return myPassword;
}
- (NSString *)username {
	return myUsername;
}
- (NSString *)label {
	return myLabel;
}
- (SecKeychainItemRef)coreKeychainItem {
	return coreKeychainItem;
}
- (BOOL)setPassword:(NSString *)newPasswordString {
	if (!newPasswordString)
		return NO;
	
	[self willChangeValueForKey:@"password"];
	myPassword = [newPasswordString copy];
	[self didChangeValueForKey:@"password"];
	
	const char *newPassword = [newPasswordString UTF8String];
	OSStatus returnStatus = SecKeychainItemModifyAttributesAndData(coreKeychainItem, NULL, (UInt32)strlen(newPassword), (void *)newPassword);
	return (returnStatus == noErr);	
}
- (BOOL)setUsername:(NSString *)newUsername {
	[self willChangeValueForKey:@"username"];
	myUsername = [newUsername copy];
	[self didChangeValueForKey:@"username"];	
	
	return [self modifyAttributeWithTag:kSecAccountItemAttr toBeString:newUsername];
}
- (BOOL)setLabel:(NSString *)newLabel {
	[self willChangeValueForKey:@"label"];
	myLabel = [newLabel copy];
	[self didChangeValueForKey:@"label"];
	
	return [self modifyAttributeWithTag:kSecLabelItemAttr toBeString:newLabel];
}
- (void)dealloc {
	if (coreKeychainItem) CFRelease(coreKeychainItem);
	
}
@end

@implementation LMKeychainItem (Private)
- (BOOL)modifyAttributeWithTag:(SecItemAttr)attributeTag toBeString:(NSString *)newStringValue {
	const char *newValue = [newStringValue UTF8String];
	SecKeychainAttribute attributes[1];
	attributes[0].tag = attributeTag;
	attributes[0].length = (UInt32)strlen(newValue);
	attributes[0].data = (void *)newValue;
	
	SecKeychainAttributeList list;
	list.count = 1;
	list.attr = attributes;
	
	OSStatus returnStatus = SecKeychainItemModifyAttributesAndData(coreKeychainItem, &list, 0, NULL);
	return (returnStatus == noErr);
}

+ (id)getKeychainAttribute:(SecItemAttr)attrTag fromItem:(SecKeychainItemRef)item {
	SecKeychainAttribute attribute[1];
	attribute[0].tag = attrTag;
	SecKeychainAttributeList list;
	list.count = 1;
	list.attr = attribute;
	
	OSStatus returnStatus = SecKeychainItemCopyContent(item, NULL, &list, NULL, NULL);
	if (returnStatus != noErr || !item) {
		if (_logErrors) {
			NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		}
		return nil;
	}
	
	NSString *attrString;
	if (attrTag == kSecPortItemAttr || attrTag == kSecProtocolItemAttr) {
		// Thanks, Omni
		NSData *attrData = [NSData dataWithBytes:list.attr[0].data length:list.attr[0].length];
		UInt32 int4 = 0;
		UInt16 int2 = 0;
		UInt8 int1 = 0;
		switch([attrData length]) {
			case 4:
				[attrData getBytes:&int4];
				break;
			case 2:
				[attrData getBytes:&int2];
				int4 = int2;
				break;
			case 1:
				[attrData getBytes:&int1];
				int4 = int1;
				break;
			default:
				NSLog(@"Unexpected integer format in keychain item.");
				int4 = 0;
		}
		return [NSNumber numberWithUnsignedInt:int4];
	} else {
		attrString = [[NSString alloc] initWithBytes:list.attr[0].data length:list.attr[0].length encoding: NSUTF8StringEncoding];
	}

	SecKeychainItemFreeContent(&list, NULL);
	return attrString;
}
@end

@implementation LMGenericKeychainItem

+ (LMGenericKeychainItem *)genericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString {
	const char *serviceName  = serviceNameString == nil ? "" : [serviceNameString UTF8String];
	UInt32 serviceNameLength = serviceNameString == nil ? 0  : (UInt32)strlen(serviceName);

	const char *username  = usernameString == nil ? "" : [usernameString UTF8String];
	UInt32 usernameLength = usernameString == nil ? 0  : (UInt32)strlen(username);
	
	UInt32 passwordLength = 0;
	char *password = nil;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, serviceNameLength, serviceName, usernameLength, username, &passwordLength, (void **)&password, &item);
	if (returnStatus != noErr || !item) {
		if (_logErrors) {
			NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		}
		return nil;
	}
	NSString *passwordString = [[NSString alloc] initWithBytes:password length:passwordLength encoding: NSUTF8StringEncoding];
	SecKeychainItemFreeContent(NULL, password);

	usernameString = [self getKeychainAttribute:kSecAccountItemAttr fromItem: item];
	serviceNameString = [self getKeychainAttribute:kSecServiceItemAttr fromItem: item];

	return [LMGenericKeychainItem genericKeychainItem:item forServiceName:serviceNameString username:usernameString password:passwordString];
}

+ (LMGenericKeychainItem *)addGenericKeychainItemForService:(NSString *)serviceNameString withUsername:(NSString *)usernameString password:(NSString *)passwordString {
	if (!usernameString || [usernameString length] == 0 || !serviceNameString || [serviceNameString length] == 0)
		return nil;
	
	const char *serviceName = [serviceNameString UTF8String];
	const char *username = [usernameString UTF8String];
	const char *password = [passwordString UTF8String];
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainAddGenericPassword(NULL, (UInt32)strlen(serviceName), serviceName, (UInt32)strlen(username), username, (UInt32)strlen(password), (void *)password, &item);
	
	if (returnStatus != noErr || !item) {
		NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		return nil;
	}
	return [LMGenericKeychainItem genericKeychainItem:item forServiceName:serviceNameString username:usernameString password:passwordString];
}

+ (void) setKeychainPassword:(NSString*)password forUsername:(NSString*)username service:(NSString*)serviceName {
	LMKeychainItem *item = [LMGenericKeychainItem genericKeychainItemForService:serviceName withUsername:username];
	if (item == nil)
		[LMGenericKeychainItem addGenericKeychainItemForService:serviceName withUsername:username password:password];
	else
		[item setPassword:password];
}

+ (NSString*) passwordForUsername:(NSString*)username service:(NSString*)serviceName {
	return [[LMGenericKeychainItem genericKeychainItemForService:serviceName withUsername:username] password];
}

- (id)initWithCoreKeychainItem:(SecKeychainItemRef)item serviceName:(NSString *)serviceName username:(NSString *)username password:(NSString *)password {
	if (self = [super initWithCoreKeychainItem:item username:username password:password]) {
		[self setValue:serviceName forKey:@"myServiceName"];
	}
	return self;
}
+ (id)genericKeychainItem:(SecKeychainItemRef)item forServiceName:(NSString *)serviceName username:(NSString *)username password:(NSString *)password {
	return [[LMGenericKeychainItem alloc] initWithCoreKeychainItem:item serviceName:serviceName username:username password:password];
}
- (NSString *)serviceName {
	return myServiceName;
}

- (BOOL)setServiceName:(NSString *)newServiceName {
	[self willChangeValueForKey:@"serviceName"];
	myServiceName = [newServiceName copy];
	[self didChangeValueForKey:@"serviceName"];	
	
	return [self modifyAttributeWithTag:kSecServiceItemAttr toBeString:newServiceName];
}
- (void)dealloc {
    
}
@end

@implementation LMInternetKeychainItem
+ (LMInternetKeychainItem *)internetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol {
	
	const char *server  = serverString == nil ? "" : [serverString UTF8String];
//    UInt32 serverLength = serverString == nil ? 0 : (UInt32)strlen(server);

	const char *username  = usernameString == nil ? "" : [usernameString UTF8String];
//    UInt32 usernameLength = usernameString == nil ? 0 : (UInt32)strlen(username);
	
	const char *path  = pathString == nil ? "" : [pathString UTF8String];
//    UInt32 pathLength = pathString == nil ? 0 : (UInt32)strlen(path);
	
	char *password = nil;
	UInt32 passwordLength = 0;
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainFindInternetPassword(NULL, (UInt32)strlen(server), server, 0, NULL, (UInt32)strlen(username), username, (UInt32)strlen(path), path, port, protocol, kSecAuthenticationTypeAny, &passwordLength, (void **)&password, &item);
	
	if (returnStatus != noErr && protocol == kSecProtocolTypeFTP) {
		//Some clients (like Transmit) still save passwords with kSecProtocolTypeFTPAccount, which was deprecated.  Let's check for that.
		protocol = kSecProtocolTypeFTPAccount;		
		returnStatus = SecKeychainFindInternetPassword(NULL, (UInt32)strlen(server), server, 0, NULL, (UInt32)strlen(username), username, (UInt32)strlen(path), path, port, protocol, 0, &passwordLength, (void **)&password, &item);
	}
	
	if (returnStatus != noErr || !item) {
		if (_logErrors) {
			NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		}
		return nil;
	}
	NSString *passwordString = [[NSString alloc] initWithBytes:password length:passwordLength encoding: NSUTF8StringEncoding];
	SecKeychainItemFreeContent(NULL, password);

	usernameString = [self getKeychainAttribute:kSecAccountItemAttr fromItem: item];
	serverString = [self getKeychainAttribute:kSecServerItemAttr fromItem: item];
	pathString = [self getKeychainAttribute:kSecPathItemAttr fromItem: item];
	port = [[self getKeychainAttribute:kSecPortItemAttr fromItem: item] intValue];
	protocol = [[self getKeychainAttribute:kSecProtocolItemAttr fromItem: item] intValue];
	return [LMInternetKeychainItem internetKeychainItem:item forServer:serverString username:usernameString password:passwordString path:pathString port:port protocol:protocol];
}

+ (LMInternetKeychainItem *)addInternetKeychainItemForServer:(NSString *)serverString withUsername:(NSString *)usernameString password:(NSString *)passwordString path:(NSString *)pathString port:(int)port protocol:(SecProtocolType)protocol {
	if (!usernameString || [usernameString length] == 0 || !serverString || [serverString length] == 0 || !passwordString || [passwordString length] == 0)
		return nil;
	
	const char *server = [serverString UTF8String];
	const char *username = [usernameString UTF8String];
	const char *password = [passwordString UTF8String];
	const char *path = [pathString UTF8String];
	
	if (!pathString || [pathString length] == 0)
		path = "";
	
	SecKeychainItemRef item = nil;
	OSStatus returnStatus = SecKeychainAddInternetPassword(NULL, (UInt32)strlen(server), server, 0, NULL, (UInt32)strlen(username), username, (UInt32)strlen(path), path, port, protocol, kSecAuthenticationTypeDefault, (UInt32)strlen(password), (void *)password, &item);
	
	if (returnStatus != noErr || !item) {
		NSLog(@"Error (%@) - %s", NSStringFromSelector(_cmd), GetMacOSStatusErrorString(returnStatus));
		return nil;
	}
	return [LMInternetKeychainItem internetKeychainItem:item forServer:serverString username:usernameString password:passwordString path:pathString port:port protocol:protocol];
}

- (id)initWithCoreKeychainItem:(SecKeychainItemRef)item server:(NSString *)server username:(NSString *)username password:(NSString *)password path:(NSString *)path port:(int)port protocol:(SecProtocolType)protocol {
	if (self = [super initWithCoreKeychainItem:item username:username password:password]) {
		[self setValue:server forKey:@"myServer"];
		[self setValue:path forKey:@"myPath"];
		[self setValue:[NSNumber numberWithInt:port] forKey:@"myPort"];
		[self setValue:[NSNumber numberWithInt:protocol] forKey:@"myProtocol"];
	}
	return self;
}
+ (id)internetKeychainItem:(SecKeychainItemRef)item forServer:(NSString *)server username:(NSString *)username password:(NSString *)password path:(NSString *)path port:(int)port protocol:(SecProtocolType)protocol {
	return [[LMInternetKeychainItem alloc] initWithCoreKeychainItem:item server:server username:username password:password path:path port:port protocol:protocol];
}
- (NSString *)server {
	return myServer;
}
- (NSString *)path {
	return myPath;
}
- (int)port {
	return myPort;
}
- (SecProtocolType)protocol {
	return myProtocol;
}

- (BOOL)setServer:(NSString *)newServer {
	[self willChangeValueForKey:@"server"];
	myServer = [newServer copy];	
	[self didChangeValueForKey:@"server"];
	
	return [self modifyAttributeWithTag:kSecServerItemAttr toBeString:newServer];
}
- (BOOL)setPath:(NSString *)newPath {
	[self willChangeValueForKey:@"path"];
	myPath = [newPath copy];
	[self didChangeValueForKey:@"path"];
	
	return [self modifyAttributeWithTag:kSecPathItemAttr toBeString:newPath];
}
- (BOOL)setPort:(int)newPort {
	[self willChangeValueForKey:@"port"];
	myPort = newPort;
	[self didChangeValueForKey:@"port"];
	
	return [self modifyAttributeWithTag:kSecPortItemAttr toBeString:[NSString stringWithFormat:@"%i", newPort]];
}
- (BOOL)setProtocol:(SecProtocolType)newProtocol {
	[self willChangeValueForKey:@"protocol"];
	myProtocol = newProtocol;
	[self didChangeValueForKey:@"protocol"];
	
	SecKeychainAttribute attributes[1];
	attributes[0].tag = kSecProtocolItemAttr;
	attributes[0].length = sizeof(newProtocol);
	attributes[0].data = (void *)newProtocol;
	
	SecKeychainAttributeList list;
	list.count = 1;
	list.attr = attributes;
	
	OSStatus returnStatus = SecKeychainItemModifyAttributesAndData(coreKeychainItem, &list, 0, NULL);
	return (returnStatus == noErr);
}
- (void)dealloc {
    
}
@end
