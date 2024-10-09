//
//  McTemperatureInfo.h
//  TestFunction
//
//  Created by developer on 11-1-19.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#ifndef APPSTORE_VERSION

#import <Cocoa/Cocoa.h>


@interface McTemperatureInfo : NSObject 
{
    NSNumber   *cpuTemp;
    NSNumber   *batteryTemp;
    NSNumber   *northbgTemp;
    NSNumber   *hddTemp;
    
    BOOL        hasBattery;
}

// update cpu temperature
// double
- (NSNumber *) UpdateCpuTemp;

// update battery temperature
// double
- (NSNumber *) UpdateBatteryTemp;

// update northbridge temperature
// double
- (NSNumber *) UpdateNorthbgTemp;

// update hard disk temperature
// double
- (NSNumber *) UpdateHddTemp;

@property (copy) NSNumber   *cpuTemp;
@property (copy) NSNumber   *batteryTemp;
@property (copy) NSNumber   *northbgTemp;
@property (copy) NSNumber   *hddTemp;

@end

#endif
