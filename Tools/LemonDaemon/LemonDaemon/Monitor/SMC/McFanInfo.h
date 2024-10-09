//
//  McFanInfo.h
//  TestFunction
//
//  Created by developer on 11-1-18.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#ifndef APPSTORE_VERSION

#import <Cocoa/Cocoa.h>


@interface McFanInfo : NSObject
{
    int             fanCount;
    NSMutableArray  *fanSpeeds;
    NSMutableArray  *fanIds;
    NSMutableArray  *fanMinSpeeds;
    NSMutableArray  *fanMaxSpeeds;
}

// update fan count
// int
- (int) UpdateFanCount;

// update fan speeds, depends on fanCount
// float (rpm)
- (NSArray *) UpdateFanSpeeds;

// set min fan speed
- (void)SetMinFanSpeed:(float)minSpeed;

// set min fan speed for certain fan
- (void)SetMinFanSpeed:(float)minSpeed index:(int)idx;

// properties
@property (assign) int          fanCount;
@property (strong) NSMutableArray *fanSpeeds;
@property (strong) NSMutableArray *fanIds;
@property (strong) NSMutableArray *fanMinSpeeds;
@property (strong) NSMutableArray *fanMaxSpeeds;

@end

#endif
