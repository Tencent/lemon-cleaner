//
//  McBatteryInfo.h
//  TestFunction
//
//  Created by developer on 11-1-21.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface McBatteryInfo : NSObject 
{
    NSString    *batSerial;
    NSDate      *manufactureDate;
    
    NSNumber    *batCycle;
    NSNumber    *batMaxCapacity;
    NSNumber    *batCurCapacity;
    NSNumber    *batDesignCapacity;
    NSNumber    *batExternalCharge;
    NSNumber    *batIsCharging;
    NSNumber    *batRemainTime; 
    
    NSNumber    *InternetRemainTime;
    NSNumber    *MusicRemainTime;
    NSNumber    *MovieRemainTime;
    NSNumber    *StandbyRemainTime;
}

// update battery serial
- (NSString *) UpdateSerial;

// update battery cycle count
// int
- (NSNumber *) UpdateCycleCount;

// update max capacity
// int (mA)
- (NSNumber *) UpdateMaxCapacity;

// update current capacity
// int (mA)
- (NSNumber *) UpdateCurrentCapacity;

// update design capacity
// int (mA)
- (NSNumber *) UpdateDesignCapacity;

// update remain time
// int (second)
- (NSNumber *) UpdateRemainTime;

// update charge capable info
// BOOL
- (NSNumber *) UpdateChargeCapable;

// update is charging info
// BOOL
- (NSNumber *) UpdateIsCharging;

// update all information
- (BOOL) UpdateAllInfo;

// properties
@property (copy) NSString   *batSerial;
@property (copy) NSDate     *manufactureDate;
@property (copy) NSNumber   *batCycle;
@property (copy) NSNumber   *batMaxCapacity;
@property (copy) NSNumber   *batCurCapacity;
@property (copy) NSNumber   *batDesignCapacity;
@property (copy) NSNumber   *batExternalCharge;
@property (copy) NSNumber   *batIsCharging;
@property (copy) NSNumber   *batRemainTime;
@property (copy) NSNumber   *InternetRemainTime;
@property (copy) NSNumber   *MusicRemainTime;
@property (copy) NSNumber   *MovieRemainTime;
@property (copy) NSNumber   *StandbyRemainTime;

@end
