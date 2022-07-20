//
//  McMemoryInfo.m
//  TestFunction
//
//  Created by developer on 11-1-24.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcMemory.h"
#import "McMemoryInfo.h"
#import "McLogUtil.h"
#import "McSystem.h"

@implementation McMemoryInfo

// properties
@synthesize physMemInfo;
@synthesize memSpeed;
@synthesize memType;
@synthesize pageInfo;

- (id) init
{
    if (self = [super init])
    {
        physMemInfo = nil;
        memSpeed = nil;
        memType = nil;
        
        pageInfo = nil;
        lastUpdateTime = 0;
        oldPagein = 0;
        oldPageout = 0;
        
        // update values
        [self UpdatePhysMemInfo];
        [self UpdateMemSpeedType];
    }
    
    return self;
}


- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McMemoryInfo class"];
    return descStr;
}

// update physical memory information
- (BOOL) UpdatePhysMemInfo
{
    uint64_t memInfo[5];
    uint64_t memInout[2];
    double pageinSpeed = 0;
    double pageoutSpeed = 0;
    double curTime = McGetAbsoluteNanosec()/(1000.0*1000*1000);
    
    if (CmcGetPhysMemoryInfo(memInfo, memInout) == -1)
        return NO;
    
    if (lastUpdateTime != 0)
    {
        pageinSpeed = (double)(memInout[0] - oldPagein) / (curTime - lastUpdateTime);
        pageoutSpeed = (double)(memInout[1] - oldPageout) / (curTime - lastUpdateTime);
    }
    oldPagein = memInout[0];
    oldPageout = memInout[1];
    lastUpdateTime = curTime;
    
    pageInfo = [NSArray arrayWithObjects:
                [NSNumber numberWithUnsignedLongLong:memInout[0]],
                [NSNumber numberWithUnsignedLongLong:memInout[1]], 
                [NSNumber numberWithDouble:pageinSpeed],
                [NSNumber numberWithDouble:pageoutSpeed],
                nil];
    //NSLog(@"%@", pageInfo);
    
    physMemInfo = [[NSArray alloc] initWithObjects:
                   [NSNumber numberWithUnsignedLongLong:memInfo[0]],
                   [NSNumber numberWithUnsignedLongLong:memInfo[1]],
                   [NSNumber numberWithUnsignedLongLong:memInfo[2]],
                   [NSNumber numberWithUnsignedLongLong:memInfo[3]],
                   [NSNumber numberWithUnsignedLongLong:(memInfo[0] + memInfo[1] + memInfo[2] + memInfo[3])],
                   [NSNumber numberWithUnsignedLongLong:memInfo[4]],
                   nil];
    return YES;
}

// update memory speed and type
- (BOOL) UpdateMemSpeedType
{
    char type[200] = {0};
    char speed[200] = {0};
    if (CmcGetMemoryType(type, sizeof(type), speed, sizeof(speed)) == -1)
        return NO;
    
    memSpeed = [[NSString alloc] initWithUTF8String:speed];
    memType = [[NSString alloc] initWithUTF8String:type];
    
    return YES;
}

@end
