//
//  McBatteryInfo.m
//  TestFunction
//
//  Created by developer on 11-1-21.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcSmartBattery.h"
#import "McBatteryInfo.h"
#import "McLogUtil.h"


@implementation McBatteryInfo

// properties
@synthesize batSerial;
@synthesize manufactureDate;
@synthesize batCycle;
@synthesize batMaxCapacity;
@synthesize batCurCapacity;
@synthesize batDesignCapacity;
@synthesize batExternalCharge;
@synthesize batIsCharging;
@synthesize batRemainTime;
@synthesize InternetRemainTime;
@synthesize MusicRemainTime;
@synthesize MovieRemainTime;
@synthesize StandbyRemainTime;

- (id) init
{
    if (self = [super init])
    {
        batSerial = nil;
        batCycle = nil;
        batMaxCapacity = nil;
        batCurCapacity = nil;
        batDesignCapacity = nil;
        batExternalCharge = nil;
        batIsCharging = nil;
        batRemainTime = nil;
        manufactureDate = nil;
        InternetRemainTime = nil;
        MusicRemainTime = nil;
        MovieRemainTime = nil;
        StandbyRemainTime = nil;
        
        // update values
        CmcBatteryInit();
        [self UpdateAllInfo];
    }
    
    return self;
}

- (void)dealloc
{
    CmcBatteryRelease();
}

- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McBatteryInfo class"];
    return descStr;
}

// update battery serial
- (NSString *) UpdateSerial
{
    if (batSerial != nil && manufactureDate != nil)
        return batSerial;
    
    char serial_buf[200] = {0};
    @try 
    {
        if (CmcGetBatterySerial(serial_buf, sizeof(serial_buf)) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert to nsstring
    batSerial = [[NSString alloc] initWithUTF8String:serial_buf];
    
    // get manufacture data
    int day, month, year;
    if (CmcGetBatteryManufactureDate(&year, &month, &day) == 0)
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setYear:year];
        [components setMonth:month];
        [components setDay:day];
        manufactureDate = [calendar dateFromComponents:components];
    }
    
    return batSerial;
}

// update battery cycle count
- (NSNumber *) UpdateCycleCount
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryCycleCount()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    batCycle = [[NSNumber alloc] initWithInt:value];
    return batCycle;
}

// update max capacity
- (NSNumber *) UpdateMaxCapacity
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryMaxCapacity()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    batMaxCapacity = [[NSNumber alloc] initWithInt:value];
    return batMaxCapacity;
}

// update current capacity
- (NSNumber *) UpdateCurrentCapacity
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryCurCapacity()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    batCurCapacity = [[NSNumber alloc] initWithInt:value];
    return batCurCapacity;
}

// update design capacity
- (NSNumber *) UpdateDesignCapacity
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryDesignCapacity()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    batDesignCapacity = [[NSNumber alloc] initWithInt:value];
    return batDesignCapacity;
}

// update remain time
- (NSNumber *) UpdateRemainTime
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryRemainTime()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    batRemainTime = [[NSNumber alloc] initWithInt:value];
    return batRemainTime;
}

// update charge capable info
- (NSNumber *) UpdateChargeCapable
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryChargeCapable()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    if (value == 1)
        batExternalCharge = [[NSNumber alloc] initWithBool:TRUE];
    else
        batExternalCharge = [[NSNumber alloc] initWithBool:FALSE];
    return batExternalCharge;
}

// update is charging info
- (NSNumber *) UpdateIsCharging
{
    int value;
    @try 
    {
        if ((value = CmcGetBatteryIsCharging()) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert
    
    if (value == 1)
        batIsCharging = [[NSNumber alloc] initWithBool:TRUE];
    else
        batIsCharging = [[NSNumber alloc] initWithBool:FALSE];
    return batIsCharging; 
}

// update all information
- (BOOL) UpdateAllInfo
{
    BOOL ret = YES;
    
    if ([self UpdateSerial] == nil)
    {
        ret = NO;
    }
    [self UpdateCycleCount];
    [self UpdateMaxCapacity];
    [self UpdateCurrentCapacity];
    [self UpdateDesignCapacity];
    [self UpdateRemainTime];
    [self UpdateChargeCapable];
    [self UpdateIsCharging];
    
    // cal times
    float fInternetScale = 936.0;
    float fMusicScale = 1044.0;
    float fMovieScale = 2160.0;
    float fStandbyScale = 7.056;
    float current = (float)[batCurCapacity intValue];
    
    InternetRemainTime = [NSNumber numberWithInt:(int)(current / fInternetScale * 60.0f)];
    MusicRemainTime = [NSNumber numberWithInt:(int)(current / fMusicScale * 60.0f)];
    MovieRemainTime = [NSNumber numberWithInt:(int)(current / fMovieScale * 60.0f)];
    StandbyRemainTime = [NSNumber numberWithInt:(int)(current / fStandbyScale * 60.0f)];
    return ret;
}

@end
