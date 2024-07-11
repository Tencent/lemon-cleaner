//
//  McMonitorFuction.h
//  McCoreFunction
//
//  Created by developer on 13-2-19.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class McBatteryInfo;
@class McCpuInfo;
@class McGpuInfo;
@class McDiskInfo;
@class McMemoryInfo;
@class McNetInfo;
@interface McMonitorFuction : NSObject
{
    // battery info
    McBatteryInfo * batteryInfo;
    BOOL isExistBattery;
    
    McCpuInfo * cpuInfo;
    McGpuInfo * gpuInfo;
    McDiskInfo * diskInfo;
    McMemoryInfo * memInfo;
    McNetInfo * netInfo;
    
    int lastHddTemp;
}

+ (McMonitorFuction *)sharedFuction;

- (NSDictionary *)batteryStateInfo;
- (NSDictionary *)cpuStateInfo;
- (NSDictionary *)gpuStateInfo;
- (NSDictionary *)diskStateInfo;
- (NSDictionary *)memoryStateInfo;
- (NSDictionary *)netStateInfo:(BOOL)interfaceInfo;
- (void)tempSateInfo:(void(^)(NSDictionary *info))completion;
- (void)fanStateInfo:(void(^)(NSDictionary *info))completion;

@end
