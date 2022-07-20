//
//  McNetInfo.h
//  TestFunction
//
//  Created by developer on 11-1-22.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface McNetInfo : NSObject 
{
    double lastUpdateTime;
    
    NSNumber   *packetsRecv;
    NSNumber   *packetsSend;
    NSNumber   *bytesRecv;
    NSNumber   *bytesSend;
    // interface info
    NSString   *netLocation;
    NSString   *interfaceName;
    NSString   *userDefName;
    NSString   *ipAddr;
    NSString   *hardware;
    NSString   *ssidName;
    NSString   *interfaceType;
    NSString   *displayName;
}

// update packets information
// unsgined long long (B)
- (BOOL) UpdatePacketsInfo;

// get download/upload speed (B/s)
// index 0:download 1:upload
// double (B/s)
- (NSArray *) GetNetworkSpeed;

// get interface information
- (BOOL) GetInterfaceInformation;

// properties
@property (strong) NSNumber   *packetsRecv;
@property (strong) NSNumber   *packetsSend;
@property (strong) NSNumber   *bytesRecv;
@property (strong) NSNumber   *bytesSend;
// interface info
@property (strong) NSString   *netLocation;
@property (strong) NSString   *interfaceName;
@property (strong) NSString   *userDefName;
@property (strong) NSString   *ipAddr;
@property (strong) NSString   *hardware;
@property (strong) NSString   *ssidName;
@property (strong) NSString   *interfaceType;
@property (strong) NSString   *displayName;

@end
