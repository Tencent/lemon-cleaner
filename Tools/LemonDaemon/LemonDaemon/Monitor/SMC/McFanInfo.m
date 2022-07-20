//
//  McFanInfo.m
//  TestFunction
//
//  Created by developer on 11-1-18.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcFan.h"
#import "McFanInfo.h"


@implementation McFanInfo

// properties
@synthesize fanCount;
@synthesize fanSpeeds;
@synthesize fanIds;
@synthesize fanMinSpeeds;
@synthesize fanMaxSpeeds;

- (id) init
{
    if (self = [super init])
    {
        fanCount = 0;
        fanSpeeds = [NSMutableArray arrayWithCapacity:10];
        fanIds = [NSMutableArray arrayWithCapacity:10];
        fanMinSpeeds = [NSMutableArray arrayWithCapacity:10];
        fanMaxSpeeds = [NSMutableArray arrayWithCapacity:10];
        
        // update values
        [self UpdateFanCount];
        [self UpdateFanSpeeds]; // must be called after update count
    }
    
    return self;
}


- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McFanInfo class"];
    return descStr;
}

// update fan count
- (int) UpdateFanCount
{
    int ncount = CmcGetFanCount();
    if (ncount == -1)
        return 0;
    
    fanCount = ncount;
    
    char szFanIds[10][20] = {0};
    if (CmcGetFanIds(fanCount, szFanIds) == 0)
    {
        [fanIds removeAllObjects];
        for (int i = 0; i < fanCount; i++)
            [fanIds addObject:[NSString stringWithUTF8String:szFanIds[i]]];
    }
    
    return fanCount;
}

// update fan speeds, depends on fanCount
- (NSArray *) UpdateFanSpeeds
{
    // we must have count first
    if (fanCount == 0 || fanCount >= 10)
        return nil;
    
    // get min speed
    [fanMinSpeeds removeAllObjects];
    for (int i = 0; i < fanCount; i++)
    {
        [fanMinSpeeds addObject:[NSNumber numberWithFloat:CmcGetMinFanSpeed(i)]];
    }
    // get max speed
    if ([fanMaxSpeeds count] != fanCount)
    {
        [fanMaxSpeeds removeAllObjects];
        for (int i = 0; i < fanCount; i++)
        {
            [fanMaxSpeeds addObject:[NSNumber numberWithFloat:CmcGetMaxFanSpeed(i)]];
        }
    }
    
    // get speeds
    float fSpeeds[10] = {0};
    if (CmcGetFanSpeeds(fanCount, fSpeeds) == -1)
        return nil;
    
    [fanSpeeds removeAllObjects];
    for (int i = 0; i < fanCount; i++)
        [fanSpeeds addObject:[NSNumber numberWithFloat:fSpeeds[i]]];
    
    return fanSpeeds;
}

// set min fan speed
- (void)SetMinFanSpeed:(float)minSpeed
{
    for (int i = 0; i < fanCount; i++)
    {
        CmcSetMinFanSpeed(i, minSpeed);
    }
}


// set min fan speed for certain fan
- (void)SetMinFanSpeed:(float)minSpeed index:(int)idx
{
    CmcSetMinFanSpeed(idx, minSpeed);
}

@end
