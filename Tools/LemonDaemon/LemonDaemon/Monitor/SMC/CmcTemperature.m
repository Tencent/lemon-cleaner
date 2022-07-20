/*
 *  CmcTemperature.c
 *  TestFunction
 *
 *  Created by developer on 11-1-19.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <stdint.h>
#include "CmcAppleSmc.h"
#include "CmcAppleSmc2.h"
#include "CmcTemperature.h"

#define MAX_TEMP_V      110.0f

// H - heatsink D - diode

// temperature key definition
// cpu
uint32_t g_cpuKey[] = {'TC0P', 'TCGc', 'TC0D', 'TC0H', 'TC0c', 'TCAD'};

//UInt32Char_t cpuTempKeyM1[] = {"Tc0a","Tc0b","Tc0x","Tc0z","Tc7a","Tc7b","Tc7x","Tc7z","Tc8a","Tc8b","Tc9a","Tc9b","Tc9x","Tc9z"};
UInt32Char_t cpuTempKeyM1[] = {"Tp09","Tp0T","Tp01","Tp05","Tp0D","Tp0H","Tp0L","Tc0a","Tc0b","Tc0x","Tc0z","Tc7a","Tc7b","Tc7x","Tc7z","Tc8a","Tc8b","Tc9a","Tc9b","Tc9x","Tc9z"};
int g_cpuKeyIndex = 0;

// battery
#define SMCKEY_TB0T     'TB0T'

// northbridge
uint32_t g_nbKey[] = {'TN0P', 'TM0P', 'Tm0P', 'TG0P', 'TN0D', 'TN0H', 'TG0H'};
int g_nbKeyIndex = 0;

// get cpu temperature for apple silicon
float GetCPUTemperature() {
    float temp = 0;
    for (int i = 0; i < 14; i++) {
        UInt32Char_t key;
        strcpy(key, cpuTempKeyM1[i]);
        SMCVal_t val;
        io_connect_t conn = GetSmcConnect();
        int ret = SMCReadKey2(key, &val, conn);
        if (ret == kIOReturnSuccess) {
            float result = parseSMCVal(val);
            temp = result > temp ? result : temp;
        }
    }
    return temp;
}

// get cpu temperature for intel
int CmcGetCpuTemperature(double *value)
{
    uint8_t buf[2];
    uint8_t nSize = sizeof(buf);
    
    if (value == NULL)
        return -1;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    int count = 0;
    int max_count = sizeof(g_cpuKey) / sizeof(uint32_t);
    while (YES)
    {
        nSize = sizeof(buf);
        if (CmcReadSmcKey(g_cpuKey[g_cpuKeyIndex%max_count], buf, &nSize, FALSE) == -1)
        {
            g_cpuKeyIndex++;
            count++;
        }
        else
        {
            *value = CmcConvertSp78ToDouble(buf);
            // unnormal value
            if (*value > MAX_TEMP_V || *value <= 0)
            {
                g_cpuKeyIndex++;
                count++;
            }
            else
            {
                return 0;
            }
        }
        
        if (count >= max_count)
            break;
    }
    float temp = GetCPUTemperature();
    if (temp < 0) {
        return -1;
    }
    *value = temp;
    return 0;
}

// get battery temperature
int CmcGetBatteryTemperature(double *value)
{
    uint8_t buf[2];
    uint8_t nSize = sizeof(buf);
    
    if (value == NULL)
        return -1;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    // 'TB0T' - sp78
    if (CmcReadSmcKey(SMCKEY_TB0T, buf, &nSize, FALSE) == -1)
        return -1;
    
    *value = CmcConvertSp78ToDouble(buf);
    if (*value > MAX_TEMP_V)
    {
        *value = 0;
        return -1;
    }
    
    // dont close now
    //CmcCloseSmc();
    return 0;
}

// get northbridge temperature
int CmcGetNBridgeTemperature(double *value)
{
    uint8_t buf[2];
    uint8_t nSize = sizeof(buf);
    
    if (value == NULL)
        return -1;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    int count = 0;
    int max_count = sizeof(g_nbKey) / sizeof(uint32_t);
    while (YES)
    {
        nSize = sizeof(buf);
        if (CmcReadSmcKey(g_nbKey[g_nbKeyIndex%max_count], buf, &nSize, FALSE) == -1)
        {
            g_nbKeyIndex++;
            count++;
        }
        else
        {
            *value = CmcConvertSp78ToDouble(buf);
            // unnormal value
            if (*value > MAX_TEMP_V || *value <= 0)
            {
                g_nbKeyIndex++;
                count++;
            }
            else
            {
                return 0;
            }
        }
        
        if (count >= max_count)
            return -1;
    }
}

