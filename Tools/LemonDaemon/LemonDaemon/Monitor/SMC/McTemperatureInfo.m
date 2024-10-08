//
//  McTemperatureInfo.m
//  TestFunction
//
//  Created by developer on 11-1-19.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#ifndef APPSTORE_VERSION

#import "CmcTemperature.h"
#import "CmcSmartQuery.h"
#import "McTemperatureInfo.h"

@implementation McTemperatureInfo

// properties
@synthesize cpuTemp;
@synthesize batteryTemp;
@synthesize northbgTemp;
@synthesize hddTemp;

- (id) init
{
    if (self = [super init])
    {
        cpuTemp = nil;
        batteryTemp = nil;
        northbgTemp = nil;
        hddTemp = nil;
        
        hasBattery = YES;
        
        // update values
//        [self UpdateCpuTemp];
//        [self UpdateBatteryTemp];
//        [self UpdateNorthbgTemp];
//        [self UpdateHddTemp];
    }
    
    return self;
}

- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McTemperatureInfo class"];
    return descStr;
}

// update cpu temperature
- (NSNumber *) UpdateCpuTemp
{
    double value;
    
    if (CmcGetCpuTemperature(&value) == -1)
        return nil;
    
    cpuTemp = [[NSNumber alloc] initWithDouble:value];
    return cpuTemp;
}

// update battery temperature
- (NSNumber *) UpdateBatteryTemp
{
    if (!hasBattery)
        return nil;
    
    double value;
    
    if (CmcGetBatteryTemperature(&value) == -1)
    {
        hasBattery = NO;
        return nil;
    }
    
    batteryTemp = [[NSNumber alloc] initWithDouble:value];
    return batteryTemp;
}

// update northbridge temperature
- (NSNumber *) UpdateNorthbgTemp
{
    double value;
    
    if (CmcGetNBridgeTemperature(&value) == -1)
        return nil;
    
    northbgTemp = [[NSNumber alloc] initWithDouble:value];
    return northbgTemp;
}

// update hard disk temperature
- (NSNumber *) UpdateHddTemp
{
    unsigned char value;
    
    // only get the first hard disk now
    if (CmcGetSmartDriverTemperature(&value, 1) <= 0)
        return nil;
    
    hddTemp = [[NSNumber alloc] initWithUnsignedChar:value];
    return hddTemp;
}

@end

#endif
