//
//  McStatMonitor.m
//  McStat
//
//  Created by developer on 12-4-6.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McStatMonitor.h"
#import "McStatInfoHelp.h"
#include <pthread.h>
#include <sys/sysctl.h>
#import <libproc.h>
#import "McMonitorFuction.h"
#import "McStatInfoConst.h"
#import "QMSampleStorage.h"

#define STATUS_TYPE_LOGO (1 << 0)
#define STATUS_TYPE_MEM  (1 << 1)
#define STATUS_TYPE_DISK (1 << 2)
#define STATUS_TYPE_TEP  (1 << 3)
#define STATUS_TYPE_FAN  (1 << 4)
#define STATUS_TYPE_NET  (1 << 5)
#define STATUS_TYPE_CPU  (1 << 6)
#define STATUS_TYPE_GPU  (1 << 7)

@interface McStatMonitor()
{
    McMonitorFuction * m_monitorFunction;
    
    NSDictionary * m_cpuDict;
    NSDictionary * m_gpuDict;
    NSDictionary * m_fanDict;
    NSDictionary * m_memoryDict;
    NSDictionary * m_networkDict;
    NSDictionary * m_tempCpuDict;
    NSDictionary * m_diskDict;
    QMSampleStorage *storage;
}
@property int processSamplerLifeCounter;
@end

@implementation McStatMonitor

- (id)init
{
    if (self = [super init])
    {
        refreshInterval = 2;
        storage = [[QMSampleStorage alloc] init];
        // 创建对象，用于线程调用
        m_monitorFunction = [[McMonitorFuction alloc] init];
        isExistBattery = [McStatInfoHelp checkBatteryExist];
        [self _loopStatData];
    }
    
    return self;
}


+ (McStatMonitor *)shareMonitor
{
    static dispatch_once_t onceToken = 0;
    __strong static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

-(void)dealloc
{
    escThread = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_loopStatData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
                   {
                       while (1)
                       {
                           @autoreleasepool
                           {
                               if (!self->escThread)
                               {
                                   [self networkInfo];
                                   if ((self.trayType & STATUS_TYPE_MEM) || (self.isTrayPageOpen)) {
                                       [self memoryInfo];
                                   }
                                   if ((self.trayType & STATUS_TYPE_FAN) || (self.isTrayPageOpen)) {
                                       [self fanInfo];
                                   }
                                   if ((self.trayType & STATUS_TYPE_CPU) || (self.isTrayPageOpen)) {
                                       [self cpuInfo];
                                   }
                                   if ((self.trayType & STATUS_TYPE_DISK) || (self.isTrayPageOpen)) {
                                       [self diskInfo];
                                   }
                                   if ((self.trayType & STATUS_TYPE_TEP) || (self.isTrayPageOpen)) {
                                       [self tempInfo];
                                   }
                                   if ((self.trayType & STATUS_TYPE_GPU) || (self.isTrayPageOpen)) {
                                       [self gpuInfo];
                                   }
                                   //                                   [self batteryStateInfo];
                                   if (self.processSamplerOn) {
                                       self.processSamplerLifeCounter -= 1;
                                       [self->storage sample];
                                   }
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [self sendStatInfoNotification];
                                   });
                               }
                               usleep(1000 * 1000 * self->refreshInterval);
                           }
                       }
                   });
}

- (void)startRunMonitor
{
    escThread = NO;
    
}
- (void)stopRunMonitor
{
    escThread = YES;
}

- (void)refreshTime:(NSNotification *)notification
{
    refreshInterval = [[notification object] intValue];
}

- (void)sendStatInfoNotification
{
    //    NSMutableDictionary * statDict = [NSMutableDictionary dictionary];
    // cpu信息
    //    if (m_cpuDict)
    //    {
    //        // monitor暂时不用CPU信息
    //        [[NSNotificationCenter defaultCenter] postNotificationName:kStatCPUInfoNotification object:m_cpuDict];
    //        [statDict setObject:m_cpuDict forKey:kStatCPUInfoNotification];
    //    }
    //网络信息
    if (m_networkDict) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkInfoNotification object:m_networkDict];
        //            [statDict setObject:m_networkDict forKey:kNetworkInfoNotification];
    }
    
    // 内存信息
    if (m_memoryDict) {
        if ((self.trayType & STATUS_TYPE_MEM) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMemoryCPUInfoNotification object:m_memoryDict];
            //            [statDict setObject:m_memoryDict forKey:kMemoryCPUInfoNotification];
        }
    }
    
    //CPU温度
    if (m_tempCpuDict) {
        if ((self.trayType & STATUS_TYPE_TEP) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kTempCpuInfoNotification object:m_tempCpuDict];
        }
    }
    //风扇转速
    if (m_fanDict) {
        if ((self.trayType & STATUS_TYPE_FAN) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFanCpuInfoNotification object:m_fanDict];
        }
    }
    
    //
    if (m_diskDict) {
        if ((self.trayType & STATUS_TYPE_DISK) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDiskInfoNotification object:m_diskDict];
        }
    }
    
    if (m_cpuDict) {
        if ((self.trayType & STATUS_TYPE_CPU) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kStatCPUInfoNotification object:m_cpuDict];
        }
    }
    
    if (m_gpuDict) {
        if ((self.trayType & STATUS_TYPE_GPU) || (self.isTrayPageOpen)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kStatGpuInfoNotification object:m_gpuDict];
        }
    }
    
    // 发送到主程序
    //    [[QMPipeServer getInstance] sendCmd:statDict
    //                                command:QMPIPE_CMD_STATINFO];
}

#pragma mark-
#pragma mark get monitro data

- (void)batteryStateInfo
{
    if (!isExistBattery)
        return;
    NSDictionary *dic = [m_monitorFunction batteryStateInfo];
    if (!dic)
        return;
}

- (void)cpuInfo
{
    NSDictionary * result = [m_monitorFunction cpuStateInfo];
    if (result && [result isKindOfClass:[NSDictionary class]])
        m_cpuDict = result;
}

- (void)gpuInfo 
{
    NSDictionary * result = [m_monitorFunction gpuStateInfo];
    if (result && [result isKindOfClass:[NSDictionary class]])
        m_gpuDict = result;
}

- (void)fanInfo{
    __weak __typeof(self) weakSelf = self;
    [m_monitorFunction fanStateInfo:^(NSDictionary *info) {
        __strong __typeof(self) strongSelf = weakSelf;
        strongSelf->m_fanDict = info;
    }];
        
}

- (void)diskInfo
{
    NSDictionary * diskDict = [m_monitorFunction diskStateInfo];
    if (!diskDict)
        return;
    m_diskDict = diskDict;
}

- (NSDictionary*)getDiskInfoDict
{
    if (m_diskDict){
        return m_diskDict;
    }else{
        [self diskInfo];
        return m_diskDict;
    }
}


- (void)memoryInfo
{
    NSDictionary * result = [m_monitorFunction memoryStateInfo];
    if (result && [result isKindOfClass:[NSDictionary class]])
        m_memoryDict = result;
}

- (void)networkInfo
{
    NSDictionary * result = [m_monitorFunction netStateInfo:YES];
    if (result && [result isKindOfClass:[NSDictionary class]])
        m_networkDict = result;
}

- (void)tempInfo
{
    __weak __typeof(self) weakSelf = self;
    [m_monitorFunction tempSateInfo:^(NSDictionary *info) {
        __strong __typeof(self) strongSelf = weakSelf;
        strongSelf->m_tempCpuDict = info;
    }];
}

- (NSArray *)processInfo
{
    if (self.processSamplerLifeCounter == 0) {
        [storage sample];
    }
    self.processSamplerLifeCounter = 2;
    return storage.processInfoArray;
}
- (NSArray *)fetchCacheProcessInfo
{
    if (storage.originProcessInfoArray.count == 0) {
        return storage.processInfoArray;
    }
    return storage.originProcessInfoArray;
}
- (void)setProcessPortStat:(BOOL)isStat{
    [storage setProcessPortStat:isStat];
}

- (void)refreshProcessInfo
{
    [storage sample];
}

- (BOOL)isProcessSamplerOn
{
    return self.processSamplerLifeCounter > 0;
}
@end
