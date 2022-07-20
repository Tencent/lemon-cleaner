//
//  McCpuInfo.m
//  TestFunction
//
//  Created by developer on 11-1-13.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcProcessor.h"
#import "McLogUtil.h"
#import "McCpuInfo.h"


@implementation McCpuInfo

// properties
@synthesize loadAverage;
@synthesize processCount;
@synthesize threadCount;
@synthesize cpuCount;
@synthesize cpuBrandStr;

- (id) init
{
    if (self = [super init])
    {
        loadAverage = nil;
        processCount = nil;
        threadCount = nil;
        cpuCount = nil;
        cpuBrandStr = nil;
        
        // update values
        [self UpdateLoadAverage];
        [self UpdateProcessCount];
        [self UpdateThreadCount];
        [self UpdateCpuCount];
        [self UpdateCpuBrandStr];
        if (cpuCount) {
            cpuTicks = malloc(sizeof(uint32_t) * [cpuCount unsignedIntValue] * 4);
        }
        [self UpdateCpuTicks];
    }
    
    return self;
}

- (void) dealloc
{

    if (cpuTicks != NULL)
        free(cpuTicks);
    
}

- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McCpuInfo class"];
    return descStr;
}

// update cpu load average
- (NSArray *) UpdateLoadAverage
{
    double value[3];
    if (CmcGetLoadavg(value) == -1)
        return nil;
    
    
    loadAverage = [[NSArray alloc] initWithObjects:
                   [NSNumber numberWithDouble:value[0]],
                   [NSNumber numberWithDouble:value[1]],
                   [NSNumber numberWithDouble:value[2]], 
                   nil];
    return loadAverage;
}

// update process count
- (NSNumber *) UpdateProcessCount
{
    int nCount = CmcGetProcessCount();
    if (nCount == -1)
        return nil;
    
    
    processCount = [[NSNumber alloc] initWithInt:nCount];
    return processCount;
}

// update thread count
- (NSNumber *) UpdateThreadCount
{
    int nCount = CmcGetThreadCount();
    if (nCount == -1)
        return nil;
    
    
    threadCount = [[NSNumber alloc] initWithInt:nCount];
    return threadCount;
}

// update cpu count
- (NSNumber *) UpdateCpuCount
{
    int nCount = CmcGetCpuCount();
    if (nCount == -1)
        return nil;
    
    
    cpuCount = [[NSNumber alloc] initWithInt:nCount];
    return cpuCount;
}

// update cpu ticks
- (BOOL) UpdateCpuTicks
{
    if (CmcGetCpuTicks(cpuTicks) == -1)
        return NO;
    
    return YES;
}

// get cpu usage
- (NSMutableArray *) GetCpuUsage
{
    if ([cpuCount unsignedIntegerValue] == 0 || NULL == cpuTicks) {
        return nil;
    }
    // record old values
    uint32_t *oldCpuTicks = malloc(sizeof(uint32_t) * [cpuCount unsignedIntValue] * 4);
    memcpy(oldCpuTicks, cpuTicks, sizeof(uint32_t) * [cpuCount unsignedIntValue] * 4);
    
    // update
    if (![self UpdateCpuTicks])
    {
        free(oldCpuTicks);
        return nil;
    }
    
    NSMutableArray *usageArray = [NSMutableArray arrayWithCapacity:3*10];
    float allUserTicks = 0;
    float allSystemTicks = 0;
    float allIdleTicks = 0;
    float allTotalTicks = 0;
    for (int i = 0; i < [cpuCount unsignedIntValue]; i++)
    {
        // user+nice
        float userTicks = (cpuTicks[i*4] - oldCpuTicks[i*4])
                             + (cpuTicks[i*4 + 3] - oldCpuTicks[i*4 + 3]);
        allUserTicks += userTicks;
        // system
        float systemTicks = cpuTicks[i*4 + 1] - oldCpuTicks[i*4 + 1];
        allSystemTicks += systemTicks;
        // idle
        float idleTicks = cpuTicks[i*4 + 2] - oldCpuTicks[i*4 + 2];
        allIdleTicks += idleTicks;
        float totalTicks = userTicks + systemTicks + idleTicks;
        allTotalTicks += totalTicks;
        
        if (allTotalTicks == 0)
        {
            [usageArray addObject:[NSNumber numberWithFloat:0]];
            [usageArray addObject:[NSNumber numberWithFloat:0]];
            [usageArray addObject:[NSNumber numberWithFloat:0]];
        }
        else
        {
            [usageArray addObject:[NSNumber numberWithFloat:userTicks/totalTicks]];
            [usageArray addObject:[NSNumber numberWithFloat:systemTicks/totalTicks]];
            [usageArray addObject:[NSNumber numberWithFloat:idleTicks/totalTicks]];
        }
    }
    // last add information for all cpus
    if (allTotalTicks == 0)
    {
        [usageArray addObject:[NSNumber numberWithFloat:0]];
        [usageArray addObject:[NSNumber numberWithFloat:0]];
        [usageArray addObject:[NSNumber numberWithFloat:0]];
    }
    else
    {
        [usageArray addObject:[NSNumber numberWithFloat:allUserTicks/allTotalTicks]];
        [usageArray addObject:[NSNumber numberWithFloat:allSystemTicks/allTotalTicks]];
        [usageArray addObject:[NSNumber numberWithFloat:allIdleTicks/allTotalTicks]];
        
    }
    free(oldCpuTicks);
    return usageArray;
}

// update cpu brand string
- (NSString *) UpdateCpuBrandStr
{
    char brand_str[200] = {0};
    if (CmcGetCpuBrandString(brand_str, sizeof(brand_str)) == -1)
        return nil;
    
    
    cpuBrandStr = [[NSString alloc] initWithUTF8String:brand_str];
    return cpuBrandStr;
}

@end
