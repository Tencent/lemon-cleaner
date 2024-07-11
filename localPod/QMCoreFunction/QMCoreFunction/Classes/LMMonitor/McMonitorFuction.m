//
//  McMonitorFuction.m
//  McCoreFunction
//
//  Created by developer on 13-2-19.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McMonitorFuction.h"
#import <mach/mach_time.h>
#import "McMonitorDefines.h"
#import <LemonStat/McBatteryInfo.h>
#import <LemonStat/McCpuInfo.h>
#import <LemonStat/McGpuInfo.h>
#import <LemonStat/McDiskInfo.h>
#import <LemonStat/McMemoryInfo.h>
#import <LemonStat/McNetInfo.h>
#import <LemonStat/McNetInfo.h>
#import "McCoreFunction.h"

@interface McMonitorFuction ()

@end

@implementation McMonitorFuction{
    NSInteger debugCounter; // 1s 执行一次, 3600 次打印一次 Log,防止过多数据.
}


+ (McMonitorFuction *)sharedFuction
{
    static McMonitorFuction * fuction = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fuction = [[McMonitorFuction alloc] init];
    });
    return fuction;
}

// Battery info
- (NSDictionary *)batteryStateInfo
{
    if (batteryInfo == nil)
    {
        batteryInfo = [[McBatteryInfo alloc] init];
    }
    
    isExistBattery = [batteryInfo UpdateAllInfo];
    
    if (!isExistBattery)
        return nil;
    
    float percentage = (float)[batteryInfo.batCurCapacity intValue] / (float)[batteryInfo.batMaxCapacity intValue];
    
    float health = (float)[batteryInfo.batMaxCapacity intValue]/(float)[batteryInfo.batDesignCapacity intValue];
    
    //Error Information :-1
    NSNumber *myNull = [NSNumber numberWithInt:-1];
    NSNumber *batCycle = batteryInfo.batCycle;
    if (batCycle == nil) batCycle = myNull;
    
    NSNumber *batRemainTime = batteryInfo.batRemainTime;
    if (batRemainTime == nil) batRemainTime = myNull;
    NSString *batSerial = batteryInfo.batSerial;
    if (batSerial == nil) batSerial = @"-1";
    NSNumber *batRemain = [batteryInfo batRemainTime];
    if (batRemain == nil) batRemain = myNull;
    NSNumber *batMaxCapacity = batteryInfo.batMaxCapacity;
    if (batMaxCapacity == nil) batMaxCapacity = myNull;
    NSNumber *batDesignCapacity = batteryInfo.batDesignCapacity;
    if (batDesignCapacity == nil) batDesignCapacity = myNull;
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithFloat:percentage],@"percentage",
                         [NSNumber numberWithFloat:health],@"health",
                         batteryInfo.batIsCharging,@"isCharging",
                         batteryInfo.batExternalCharge,@"externalPlug",
                         batCycle,@"batCycle",
                         batRemainTime,@"batRemainTime",
                         batSerial,@"batSerial",
                         [batteryInfo MovieRemainTime], @"movieRemain",
                         [batteryInfo MusicRemainTime], @"musicRemain",
                         [batteryInfo InternetRemainTime], @"internetRemain",
                         [batteryInfo StandbyRemainTime], @"standyRemain",
                         batRemain ,@"batRemain",
                         batMaxCapacity, @"batMaxCapacity",
                         batDesignCapacity,@"batDesignCapacity",
                         batteryInfo.manufactureDate, @"manufactureDate",
                         nil];
    return dic;
}

- (NSDictionary *)cpuStateInfo
{
    if (cpuInfo == nil)
    {
        cpuInfo = [[McCpuInfo alloc] init];
    }
    
    static mach_timebase_info_data_t sTimebaseInfo = {0};
    if (sTimebaseInfo.denom == 0)
        mach_timebase_info(&sTimebaseInfo);
    
    // update ticks user/system/idel/.../
    NSMutableArray *cpuTicks = [cpuInfo GetCpuUsage];
    if (cpuTicks == nil)
        return nil;
    
    int realCpuCount = [cpuInfo.cpuCount intValue];
    float cpuValue = [[cpuTicks objectAtIndex:(realCpuCount*3)] floatValue] +
    [[cpuTicks objectAtIndex:(realCpuCount*3 + 1)] floatValue];
    
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         [[cpuInfo UpdateProcessCount] description],@"ProcessCount",
                         [[cpuInfo UpdateThreadCount] description],@"ThreadCount",
                         cpuTicks,@"Ticks",
                         cpuInfo.cpuCount,@"Count",
                         cpuInfo.cpuBrandStr,@"BrandStr",
                         [NSNumber numberWithFloat:cpuValue],@"CpuUsage",
                         nil];
    return dic;
}

- (NSDictionary *)gpuStateInfo {
    if (gpuInfo == nil)
    {
        gpuInfo = [[McGpuInfo alloc] init];
    }
    [gpuInfo updateInfoType:McGpuInfoTypeUsage];
    
    CGFloat usage = 0;
    for (McGpuCore *core in gpuInfo.cores) {
        usage = MAX(usage, core.usage);
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@(usage), @"usage", nil];
    
    return dic;
}

- (NSDictionary *)diskStateInfo
{
    if (diskInfo == nil)
    {
        diskInfo = [[McDiskInfo alloc] init];
    }
    
    NSArray *diskSpeed = [diskInfo GetDiskReadWriteSpeed];
    NSArray * volumnesArray = [diskInfo GetVolumesInformation];
    if (debugCounter % 3600 == 1){
        for (McVolumeInfo *volumeInfo in volumnesArray){
            NSLog(@"%s : volumeInfo :%@,dev name:%@-> total size: %llu, free size %llu", __FUNCTION__, volumeInfo.volName, volumeInfo.devName, volumeInfo.totalBytes,  volumeInfo.freeBytes);
        }
    }
    debugCounter ++ ;
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    if (diskSpeed)
        [dict setObject:diskSpeed forKey:@"DiskSpeed"];
    if (volumnesArray)
        [dict setObject:volumnesArray forKey:@"Volumnes"];
    return dict;
}

- (NSDictionary *)memoryStateInfo
{
    if (memInfo == nil)
    {
        memInfo = [[McMemoryInfo alloc] init];
    }
    
    if (![memInfo UpdatePhysMemInfo])
        return nil;
    
    //            NSLog(@"%@", memInfo.pageInfo);
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         memInfo.physMemInfo,@"SizeArray",
                         memInfo.memSpeed,@"memSpeed",
                         memInfo.memType,@"memType",
                         memInfo.pageInfo,@"memPageInfo",
                         nil];
    return dic;
}

- (NSDictionary *)netStateInfo:(BOOL)interfaceInfo
{
    if (netInfo == nil)
    {
        netInfo = [[McNetInfo alloc] init];
    }
    /*
     static mach_timebase_info_data_t sTimebaseInfo = {0};
     if (sTimebaseInfo.denom == 0)
     mach_timebase_info(&sTimebaseInfo);
     */
    // get speed
    NSArray *netSpeed = [netInfo GetNetworkSpeed];
    if (netSpeed == nil)
        return nil;
    
    if (interfaceInfo)
        [netInfo GetInterfaceInformation];
    
    NSNumber *downSpeed = [netSpeed objectAtIndex:0];
    NSNumber *upSpeed = [netSpeed objectAtIndex:1];
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         upSpeed,@"UpSpeed",
                         downSpeed,@"DownSpeed",
                         //                         netInfo.bytesSend,@"bytesSend",
                         //                         netInfo.bytesRecv,@"bytesRecv",
                         netInfo.ipAddr?:@"",@"ipAddr",
                         //                         netInfo.netLocation?:@"",@"netLocation",
                         //                         netInfo.interfaceType?:@"",@"interfaceType",
                         nil];
    return dic;
}

- (void)tempSateInfo:(void(^)(NSDictionary *info))completion
{
    [[McCoreFunction shareCoreFuction] getCPUTemperature:^(NSArray *array) {
        double temperature = [array.firstObject doubleValue];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@(temperature),@"CpuTemp", nil];
        completion(dic);
    }];
}

- (void)fanStateInfo:(void(^)(NSDictionary *info))completion
{
    [[McCoreFunction shareCoreFuction] getFanSpeeds:^(NSArray * _Nonnull fanSpeeds) {
        NSMutableArray *fansArray = [NSMutableArray array];
        for (int i = 0; i < [fanSpeeds count]; i++)
        {
            NSNumber *speed = [fanSpeeds objectAtIndex:i];
            NSDictionary *fanDic = [NSDictionary dictionaryWithObjectsAndKeys:speed, @"fanSpeed", nil];
            [fansArray addObject:fanDic];
        }
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:fansArray,@"fanArray", nil];
        completion(dic);
    }];
}

@end
