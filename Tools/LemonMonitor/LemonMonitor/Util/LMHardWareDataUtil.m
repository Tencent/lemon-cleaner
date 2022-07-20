//
//  LMHardWareDataUtil.m
//  LemonMonitor
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMHardWareDataUtil.h"
#import <LemonStat/McDiskInfo.h>

@implementation LMHardWareDataUtil

+(void)calculateDiskUsageInfoWithMainDiskName: (NSString *)mainDiskName volumeArray: (NSArray *) volumnesArray freeBytes: (uint64_t *)freeBytes totalBytes: (uint64_t *)totalBytes{
    uint64_t mainDiskTotalBytes = 0;
    uint64_t mainDiskFreeBytes = 0;
    if (mainDiskName == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (int i=0; i<volumnesArray.count; i++)
        {
            McVolumeInfo *volumnInfo = volumnesArray[i];
            if (![volumnInfo.devName isEqualToString:@"Disk Image"]&& ![volumnInfo.volName isEqualToString:@"Recovery"] && volumnInfo.writeble) {
                //TODO: realPath返回 “/” 说明该磁盘是mainDisk, 为什么?
                NSString *realPath = [fileManager destinationOfSymbolicLinkAtPath:volumnInfo.volPath error:nil];
                if ((realPath != nil) && [realPath isEqualToString:@"/"]) {
                    mainDiskName = volumnInfo.volName;
                    mainDiskTotalBytes = volumnInfo.totalBytes;
                    mainDiskFreeBytes = volumnInfo.freeBytes;
                    break;
                }
                
            }
        }
    }
    for (int i=0; i<volumnesArray.count; i++)
    {
        McVolumeInfo *volumeInfo = volumnesArray[i];
        
        if (volumeInfo.networkDevice) {
            continue;
        }
        if ([volumeInfo.volName isEqualToString:mainDiskName] && volumeInfo.internalDevice) {
            //重新进行计算可用空间
            NSInteger freeBytes = [self getAllUsableBytes];
//            NSLog(@"%s, newLeftSize: %ld", __FUNCTION__, (long)freeBytes);
            if (freeBytes > 0) {
                volumeInfo.freeBytes = freeBytes;
            }
        }
//           NSLog(@"DiskInfo--%s--[volumnInfo.volName:%@,volumnInfo.devName:%@,volumnInfo.freeBytes:%llu,volumnInfo.totalBytes:%llul,]",__FUNCTION__,volumeInfo.volName, volumeInfo.devName,volumeInfo.freeBytes,volumeInfo.totalBytes);
        //如果不是Disk Image，并且磁盘可写，不是Recovery; Recovery:用于恢复系统、修复磁盘用的一个可启动应用
        if (![volumeInfo.volName isEqualToString:@"Disk Image"] && ![volumeInfo.volName isEqualToString:@"Recovery"] && volumeInfo.writeble) {
            //如果有两个完全一样的磁盘，则认为是同一个磁盘
            if (![volumeInfo.volName isEqualToString:mainDiskName] && (volumeInfo.totalBytes == mainDiskTotalBytes) && (volumeInfo.freeBytes == mainDiskFreeBytes)) {
                continue;
            }
            *freeBytes += volumeInfo.freeBytes;
            *totalBytes += volumeInfo.totalBytes;
        }
    }
    
}

+(float)getAllUsableBytes{
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        //TODO: 拿到有效的剩余空间
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        //    NSLog(@"float Available capacity for important usage: %lf",[[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]);
        return [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue];
    }else{
        return 0;
    }
}
@end
