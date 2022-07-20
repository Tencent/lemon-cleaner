/*
 *  CmcSmartBattery.c
 *  TestFunction
 *
 *  Created by developer on 11-1-20.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <IOKit/IOKitLib.h>
#include "CmcSmartBattery.h"
#include "McLogUtil.h"

#define kAppleSmartBattery          "AppleSmartBattery"
#define kBatterySerialKey           "BatterySerialNumber"
#define kBatteryCycleCountKey       "CycleCount"
#define kBatteryMaxCapacityKey      "MaxCapacity"
#define kBatteryCurrentCapacityKey  "CurrentCapacity"
#define kBatteryDesignCapacityKey   "DesignCapacity"
#define kBatteryExternalChargeKey   "ExternalChargeCapable"
#define kBatteryIsChargingKey       "IsCharging"
#define kBatteryTimeRemainKey       "TimeRemaining"
#define kBatteryManufactureDateKey  "ManufactureDate"

io_service_t g_smartBattery = 0;

void CmcBatteryInit()
{
    if (g_smartBattery != 0)
        return;
    
    // get AppleSmartBattery service object
    g_smartBattery = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                                 IOServiceMatching(kAppleSmartBattery));
}

void CmcBatteryRelease()
{
    if (g_smartBattery == 0)
        return;
    
    IOObjectRelease(g_smartBattery);
}

// get battery serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int CmcGetBatterySerial(char *serial_buf, int buf_size)
{
    CFStringRef serial;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    // get serial value
    serial = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatterySerialKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (serial == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery serial fail", __FUNCTION__);
        return -1;
    }
    
    // output serial to buffer
    if (!CFStringGetCString(serial, serial_buf, buf_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery serial string fail", __FUNCTION__);
        
        CFRelease(serial);
        return -1;
    }
    
    CFRelease(serial);
    return 0;
}

// get battery cycle count
int CmcGetBatteryCycleCount()
{
    CFNumberRef count;
    int16_t retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    // get cycle count value
    count = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                            CFSTR(kBatteryCycleCountKey), 
                                            kCFAllocatorDefault, 
                                            kNilOptions);
    if (count == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery cycle count fail", __FUNCTION__);
        return -1;
    }
    
    // output cycle count to buffer
    if (!CFNumberGetValue(count, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery cycle count fail", __FUNCTION__);
        
        CFRelease(count);
        return -1;
    }
    
    CFRelease(count);
    return retvalue;
}

// get battery max capacity
int CmcGetBatteryMaxCapacity()
{
    CFNumberRef number;
    int16_t retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                            CFSTR(kBatteryMaxCapacityKey), 
                                            kCFAllocatorDefault, 
                                            kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery max capacity fail", __FUNCTION__);
        return -1;
    }
    
    if (!CFNumberGetValue(number, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery max capacity fail", __FUNCTION__);
        
        CFRelease(number);
        return -1;
    }
    
    CFRelease(number);
    return retvalue;
}

// get battery design capacity
int CmcGetBatteryDesignCapacity()
{
    CFNumberRef number;
    int16_t retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryDesignCapacityKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery design capacity fail", __FUNCTION__);
        return -1;
    }
    
    if (!CFNumberGetValue(number, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery design capacity fail", __FUNCTION__);
        
        CFRelease(number);
        return -1;
    }
    
    CFRelease(number);
    return retvalue;
}

// get battery current capacity
int CmcGetBatteryCurCapacity()
{
    CFNumberRef number;
    int16_t retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryCurrentCapacityKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery current capacity fail", __FUNCTION__);
        return -1;
    }
    
    if (!CFNumberGetValue(number, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery current capacity fail", __FUNCTION__);
        
        CFRelease(number);
        return -1;
    }
    
    CFRelease(number);
    return retvalue;
}

// get battery remain time
int CmcGetBatteryRemainTime()
{
    CFNumberRef number;
    int16_t retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryTimeRemainKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery remain time fail", __FUNCTION__);
        return -1;
    }
    
    if (!CFNumberGetValue(number, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery remain time fail", __FUNCTION__);
        
        CFRelease(number);
        return -1;
    }
    
    CFRelease(number);
    return retvalue;
}

// get battery externel charge
// return 0 for false, 1 for true, -1 for error
int CmcGetBatteryChargeCapable()
{
    CFBooleanRef number;
    int retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryExternalChargeKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get charge capable fail", __FUNCTION__);
        return -1;
    }
    
    if (CFBooleanGetValue(number))
        retvalue = 1;
    else
        retvalue = 0;
    
    CFRelease(number);
    return retvalue;
}

// get battery is charging
// return 0 for false, 1 for true, -1 for error
int CmcGetBatteryIsCharging()
{
    CFBooleanRef number;
    int retvalue;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryIsChargingKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get charging stat fail", __FUNCTION__);
        return -1;
    }
    
    if (CFBooleanGetValue(number))
        retvalue = 1;
    else
        retvalue = 0;
    
    CFRelease(number);
    return retvalue;
}

/*
 * Date is published in a bitfield per the Smart Battery Data spec rev 1.1 
 * in section 5.1.26
 *   Bits 0...4 => day (value 1-31; 5 bits)
 *   Bits 5...8 => month (value 1-12; 4 bits)
 *   Bits 9...15 => years since 1980 (value 0-127; 7 bits)
 */
int CmcGetBatteryManufactureDate(int *year, int *month, int *day)
{
    CFNumberRef number;
    int16_t retvalue;
    
    if (year == NULL || month == NULL || day == NULL)
        return -1;
    
    if (g_smartBattery == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get smart battery device fail", __FUNCTION__);
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery, 
                                             CFSTR(kBatteryManufactureDateKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (number == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get battery manufacture date fail", __FUNCTION__);
        return -1;
    }
    
    if (!CFNumberGetValue(number, kCFNumberSInt16Type, &retvalue))
    {
        McLog(MCLOG_ERR, @"[%s] convert battery manufacture date fail", __FUNCTION__);
        
        CFRelease(number);
        return -1;
    }
    
    CFRelease(number);
    
    *day = retvalue & 0x1f;
    *month = (retvalue >> 5) & 0xf;
    *year = 1980 + ((retvalue >> 9) & 0x7f);
    
    return 0;
}
