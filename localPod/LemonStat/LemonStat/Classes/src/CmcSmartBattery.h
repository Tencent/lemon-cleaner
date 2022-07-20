/*
 *  CmcSmartBattery.h
 *  TestFunction
 *
 *  Created by developer on 11-1-20.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

void CmcBatteryInit();
void CmcBatteryRelease();

// get battery serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int CmcGetBatterySerial(char *serial_buf, int buf_size);

// get battery cycle count
int CmcGetBatteryCycleCount();

// get battery max capacity
int CmcGetBatteryMaxCapacity();

// get battery design capacity
int CmcGetBatteryDesignCapacity();

// get battery current capacity
int CmcGetBatteryCurCapacity();

// get battery remain time
int CmcGetBatteryRemainTime();

// get battery externel charge
// return 0 for false, 1 for true, -1 for error
int CmcGetBatteryChargeCapable();

// get battery is charging
// return 0 for false, 1 for true, -1 for error
int CmcGetBatteryIsCharging();

// get battery manufacture date
int CmcGetBatteryManufactureDate(int *year, int *month, int *day);
