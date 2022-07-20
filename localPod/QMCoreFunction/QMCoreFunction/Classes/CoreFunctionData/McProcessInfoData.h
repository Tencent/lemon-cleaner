//
//  McProcessInfoData.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface McProcessInfoData:NSObject<NSCoding>
{
    int pid;
    int ppid;
    int uid;
    int pflag;
    
    NSString *pUserName;
    NSString *pName;
    NSString *pExecutePath;
    
    NSImage * iconImage;
    
    int threadCount;
    
    uint64_t cpuTime;
    uint64_t currentTime;
    
    float cpuUsage;
    
    NSMutableArray * subProcessArray;
}
@property (retain) NSImage * iconImage;
@property (assign) uint64_t resident_size, virtual_size;
@property (assign) int threadCount, pid, ppid, uid, pflag;
@property (retain) NSString *pUserName;
@property (retain) NSString *pName;
@property (retain) NSString *pExecutePath;
@property (assign) uint64_t cpuTime, currentTime;
@property (assign) float cpuUsage;
@property (assign) double upSpeed, downSpeed;

@end
