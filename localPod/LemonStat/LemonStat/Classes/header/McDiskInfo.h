//
//  McDiskInfo.h
//  TestFunction
//
//  Created by developer on 11-1-25.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface McVolumeInfo : NSObject<NSCoding>
{
    NSString    *devName;
    NSString    *volName;
    NSString    *icnsPath;
    NSString    *kindName;
    NSString    *volPath;
    
    uint64_t    freeBytes;
    uint64_t    totalBytes;
    
    BOOL        ejectable;
    
    BOOL        internalDevice;
    BOOL        networkDevice;
    BOOL        writeble;
}

@property (strong) NSString   *devName;
@property (strong) NSString   *volName;
@property (strong) NSString   *icnsPath;
@property (strong) NSString   *kindName;
@property (strong) NSString   *volPath;
@property (assign) uint64_t freeBytes;
@property (assign) uint64_t totalBytes;
@property (assign) BOOL     ejectable;
@property (assign) BOOL     internalDevice;
@property (assign) BOOL     networkDevice;
@property (assign) BOOL     writeble;

@end    // McVolumeInfo

@interface McDiskInfo : NSObject
{
    double lastUpdateTime;
    
    NSMutableDictionary *volumesDic;
    
    NSNumber        *bytesRead;
    NSNumber        *bytesWrite;
}

// get information of all volumes
- (NSArray *) GetVolumesInformation;

// update disk read and write bytes information
// unsigned long long (B)
- (BOOL) UpdateDiskReadWriteBytes;

// get speed
// index 0:read 1:write
// double (B/s)
- (NSArray *) GetDiskReadWriteSpeed;

// properties
@property (strong) NSNumber   *bytesRead;
@property (strong) NSNumber   *bytesWrite;

@end
