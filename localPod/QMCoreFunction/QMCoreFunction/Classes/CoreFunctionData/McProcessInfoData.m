//
//  McProcessInfoData.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "McProcessInfoData.h"

@implementation McProcessInfoData

@synthesize resident_size, virtual_size;
@synthesize threadCount, pid, ppid, uid, pflag;
@synthesize pUserName, pName, pExecutePath;
@synthesize cpuTime, currentTime;
@synthesize cpuUsage;
@synthesize iconImage;
@synthesize upSpeed, downSpeed;
-(id)init
{
    if(self = [super init])
    {
        pUserName = nil;
        pName = nil;
        pExecutePath = nil;
        cpuUsage = 0.0;
        resident_size = 0;
        virtual_size = 0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:pUserName forKey:@"pUserName"];
    [aCoder encodeObject:pName forKey:@"pName"];
    [aCoder encodeObject:pExecutePath forKey:@"pExecutePath"];
    [aCoder encodeFloat:cpuUsage forKey:@"cpuUsage"];
    [aCoder encodeInt64:cpuTime forKey:@"cpuTime"];
    [aCoder encodeInt64:currentTime forKey:@"currentTime"];
    [aCoder encodeInt:threadCount forKey:@"threadCount"];
    [aCoder encodeInt:pid forKey:@"pid"];
    [aCoder encodeInt:ppid forKey:@"ppid"];
    [aCoder encodeInt:uid forKey:@"uid"];
    [aCoder encodeInt:pflag forKey:@"pflag"];
    [aCoder encodeInt64:resident_size forKey:@"resident_size"];
    [aCoder encodeInt64:virtual_size forKey:@"virtual_size"];
    [aCoder encodeDouble:upSpeed forKey:@"upSpeed"];
    [aCoder encodeDouble:downSpeed forKey:@"downSpeed"];
    //NSLog(@"process encode");
    
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil)
    {
        //NSLog(@"process init coder");
        pUserName = [aDecoder decodeObjectForKey:@"pUserName"];
        pName = [aDecoder decodeObjectForKey:@"pName"];
        pExecutePath = [aDecoder decodeObjectForKey:@"pExecutePath"];
        cpuUsage = [aDecoder decodeFloatForKey:@"cpuUsage"];
        cpuTime = [aDecoder decodeInt64ForKey:@"cpuTime"];
        currentTime = [aDecoder decodeInt64ForKey:@"currentTime"];
        threadCount = [aDecoder decodeIntForKey:@"threadCount"];
        pid = [aDecoder decodeIntForKey:@"pid"];
        ppid = [aDecoder decodeIntForKey:@"ppid"];
        uid = [aDecoder decodeIntForKey:@"uid"];
        pflag = [aDecoder decodeIntForKey:@"pflag"];
        resident_size = (uint64_t)[aDecoder decodeInt64ForKey:@"resident_size"];
        virtual_size = (uint64_t)[aDecoder decodeInt64ForKey:@"virtual_size"];
        upSpeed = [aDecoder decodeDoubleForKey:@"upSpeed"];
        downSpeed = [aDecoder decodeDoubleForKey:@"downSpeed"];
        iconImage = nil;
    }
    return self;
}

@end
