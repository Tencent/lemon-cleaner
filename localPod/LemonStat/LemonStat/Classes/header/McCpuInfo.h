//
//  McCpuInfo.h
//  TestFunction
//
//  Created by developer on 11-1-13.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface McCpuInfo : NSObject 
{
    // type:double, size: 3, load average for 5,10,15 mins
    NSArray     *loadAverage;
    NSNumber    *processCount;
    NSNumber    *threadCount;
    NSNumber    *cpuCount;
    NSString    *cpuBrandStr;
    // type:uint, size: 5, user/system/idle/nice
    // if cpu count bigger than 1, the size of this array is 4*count
    uint32_t    *cpuTicks;
}

// update cpu load average
// double
- (NSArray *) UpdateLoadAverage;

// update process count
// int
- (NSNumber *) UpdateProcessCount;

// update thread count
// int
- (NSNumber *) UpdateThreadCount;

// update cpu count
// int
- (NSNumber *) UpdateCpuCount;

// update cpu ticks
- (BOOL) UpdateCpuTicks;

// get cpu usage
// each cpu is represent by 3 values: user/system/idle/...
// float (percentage 0.0~1.0)
- (NSMutableArray *) GetCpuUsage;

// update cpu brand string
- (NSString *) UpdateCpuBrandStr;

// properties
// type:double, size: 3, load average for 5,10,15 mins
@property (copy) NSArray    *loadAverage;
@property (copy) NSNumber   *processCount;
@property (copy) NSNumber   *threadCount;
@property (copy) NSNumber   *cpuCount;
@property (copy) NSString   *cpuBrandStr;

@end
