//
//  McNetInfo.m
//  TestFunction
//
//  Created by developer on 11-1-22.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcNetSysctl.h"
#import "McSystem.h"
#import "McNetInfo.h"
#import "McLogUtil.h"


@implementation McNetInfo

// properties
@synthesize packetsRecv;
@synthesize packetsSend;
@synthesize bytesRecv;
@synthesize bytesSend;
// interface info
@synthesize netLocation;
@synthesize interfaceName;
@synthesize userDefName;
@synthesize ipAddr;
@synthesize hardware;
@synthesize ssidName;
@synthesize interfaceType;
@synthesize displayName;

- (id) init
{
    if (self = [super init])
    {
        lastUpdateTime = 0.0;
        packetsRecv = nil;
        packetsSend = nil;
        bytesRecv = nil;
        bytesSend = nil;
        netLocation = nil;
        interfaceName = nil;
        userDefName = nil;
        ipAddr = nil;
        hardware = nil;
        ssidName = nil;
        
        // update values
        [self UpdatePacketsInfo];
        //[self GetInterfaceInformation];
    }
    
    return self;
}

- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McNetInfo class"];
    return descStr;
}

// update packets information
- (BOOL) UpdatePacketsInfo
{
    uint64_t uiPackRecv;
    uint64_t uiPackSend;
    uint64_t uiBytesRecv;
    uint64_t uiBytesSend;
    
    if (CmcGetNetPacketsInfo(&uiPackRecv, &uiPackSend, &uiBytesRecv, &uiBytesSend) == -1)
    {
        return NO;
    }
    
    // record last update time
    lastUpdateTime = McGetAbsoluteNanosec()/(1000*1000*1000);
    
    packetsRecv = [NSNumber numberWithUnsignedLongLong:uiPackRecv];
    packetsSend = [NSNumber numberWithUnsignedLongLong:uiPackSend];
    bytesRecv = [NSNumber numberWithUnsignedLongLong:uiBytesRecv];
    bytesSend = [NSNumber numberWithUnsignedLongLong:uiBytesSend];
    
    return YES;
}

// get download/upload speed (B/s)
// index 0:download 1:upload
- (NSArray *) GetNetworkSpeed
{
    if (bytesRecv == nil || bytesSend == nil)
    {
        return nil;
    }
    
    uint64_t oldBytesRecv = [bytesRecv unsignedLongLongValue];
    uint64_t oldBytesSend = [bytesSend unsignedLongLongValue];
    double oldUpdateTime = lastUpdateTime;
    
    // update value
    if (![self UpdatePacketsInfo])
        return nil;
    
    double downSpeed = 0.0;
    if ([bytesRecv unsignedLongLongValue] > oldBytesRecv
        && lastUpdateTime > oldUpdateTime)
    {
        downSpeed = (double)([bytesRecv unsignedLongLongValue] - oldBytesRecv) / (lastUpdateTime - oldUpdateTime);
    }
    double upSpeed = 0.0;
    if ([bytesSend unsignedLongLongValue] > oldBytesSend
        && lastUpdateTime > oldUpdateTime)
    {
        upSpeed = (double)([bytesSend unsignedLongLongValue] - oldBytesSend) / (lastUpdateTime - oldUpdateTime);
    }
    
    return ([NSArray arrayWithObjects:
             [NSNumber numberWithDouble:downSpeed],
             [NSNumber numberWithDouble:upSpeed],
             nil]);
}

// get interface information
- (BOOL) GetInterfaceInformation
{
    char location[200] = {0};
    char name[200] = {0};
    char user_name[200] = {0};
    char ip[200] = {0};
    char chardware[200] = {0};
    char ssid[200] = {0};
    char interface_type[200] = {0};
    char display_name[200] = {0};
    
    if (CmcGetNetInterfaceInfo(name, 
                               sizeof(name), 
                               user_name, 
                               sizeof(user_name), 
                               ip, 
                               sizeof(ip), 
                               chardware,
                               sizeof(chardware),
                               ssid, 
                               sizeof(ssid)) == -1)
    {
        ipAddr = nil;
        return NO;
    }
    
    NSString *strName = [NSString stringWithUTF8String:name];
    NSString *strUserName = [NSString stringWithUTF8String:user_name];
    NSString *strIp = [NSString stringWithUTF8String:ip];
    NSString *strHardware = [NSString stringWithUTF8String:chardware];
    if ([interfaceName isEqualToString:strName]
        && [userDefName isEqualToString:strUserName]
        && [ipAddr isEqualToString:strIp]
        && [hardware isEqualToString:strHardware])
    {
        // nothing changed, to save CPU usage
        return YES;
    }
    
    ipAddr = strIp;
    interfaceName = strName;
    userDefName = strUserName;
    hardware = strHardware;
    ssidName = [NSString stringWithUTF8String:ssid];

    // name - en0
    if (CmcGetInterfacePref(name, interface_type, sizeof(interface_type), display_name, sizeof(display_name)) == -1)
    {
        return NO;
    }
    displayName = [NSString stringWithUTF8String:display_name];
    interfaceType = [NSString stringWithUTF8String:interface_type];

    if (CmcGetNetLocation(location, sizeof(location)) == -1)
    {
        return NO;
    }
    
    netLocation = [NSString stringWithUTF8String:location];
    // kSCNetworkInterfaceTypeEthernet / kSCNetworkInterfaceTypeIEEE80211
    
    return YES;
}

@end
