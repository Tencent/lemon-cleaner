/*
 *  CmcFan.c
 *  TestFunction
 *
 *  Created by developer on 11-1-18.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <stdint.h>
#include "CmcAppleSmc.h"
#include "CmcAppleSmc2.h"
#include "CmcFan.h"

// key definition
#define SMCKEY_FNUM     "FNum"
#define SMCKEY_FDAC     "F%dAc"
#define SMCKEY_FID      "F%dID"
#define SMCKEY_FMIN     "F%dMn"
#define SMCKEY_FMAX     "F%dMx"

extern io_connect_t g_connect;

// get fan count
int CmcGetFanCount()
{
    uint32_t key = *(uint32_t *)SMCKEY_FNUM;
    uint8_t nCount;
    uint8_t nSize = sizeof(nCount);
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    // 'FNum' - ui8
    CmcSwapBytes((uint8_t *)&key, sizeof(key));
    int ret = CmcReadSmcKey(key, &nCount, &nSize, FALSE);
    //适配Apple silicon风扇获取
    if (ret == -1) {
        printf("smc read key[FNum] failed.");
        SMCVal_t val;
        kern_return_t result = SMCReadKey2(SMCKEY_FNUM, &val, g_connect);
        if (result != kIOReturnSuccess) {
            printf("smc read key2[FNum] failed.");
            return -1;
        }
        nCount = _strtoul((char *)val.bytes, val.dataSize, 10);
        printf("smc read key2[FNum] = %d",nCount);
        if (nCount < 0) {
            return -1;
        }
    }
    // dont close now
    //CmcCloseSmc();
    
    return nCount;
}

// set fan min speed
int CmcSetMinFanSpeed(int nIndex, float fMinSpeed)
{
    char szKey[5] = {0};
    uint32_t key;
    uint8_t speed[2];
    uint8_t nSize;
    float fMaxSpeed;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    // read max fan speed first
    snprintf(szKey, sizeof(szKey), SMCKEY_FMAX, nIndex);
    key = *(uint32_t *)szKey;
    nSize = sizeof(speed);
    
    CmcSwapBytes((uint8_t *)&key, sizeof(key));
    if (CmcReadSmcKey(key, (uint8_t *)&speed, &nSize, FALSE) == -1)
        return -1;
    
    // check max speed
    fMaxSpeed = CmcConvertFpe2ToFloat(speed, sizeof(speed), 2);
    if (fMinSpeed >= fMaxSpeed)
        return -1;
    
    // set min speed
    snprintf(szKey, sizeof(szKey), SMCKEY_FMIN, nIndex);
    key = *(uint32_t *)szKey;
    
    nSize = sizeof(speed);
    CmcConvertFloatToFpe2(fMinSpeed, speed, nSize);
    
    CmcSwapBytes((uint8_t *)&key, sizeof(key));
    if (CmcWriteSmcKey(key, (uint8_t *)&speed, nSize) == -1)
        return -1;
    
    return 0;
}

float CmcGetMinFanSpeed(int nIndex)
{
    char szKey[5] = {0};
    uint32_t key;
    uint8_t speed[2];
    uint8_t nSize;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    // read max fan speed first
    snprintf(szKey, sizeof(szKey), SMCKEY_FMIN, nIndex);
    key = *(uint32_t *)szKey;
    nSize = sizeof(speed);
    
    CmcSwapBytes((uint8_t *)&key, sizeof(key));
    if (CmcReadSmcKey(key, (uint8_t *)&speed, &nSize, FALSE) == -1)
        return -1;
    
    return CmcConvertFpe2ToFloat(speed, sizeof(speed), 2);
}

float CmcGetMaxFanSpeed(int nIndex)
{
    char szKey[5] = {0};
    uint32_t key;
    uint8_t speed[2];
    uint8_t nSize;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    // read max fan speed first
    snprintf(szKey, sizeof(szKey), SMCKEY_FMAX, nIndex);
    key = *(uint32_t *)szKey;
    nSize = sizeof(speed);
    
    CmcSwapBytes((uint8_t *)&key, sizeof(key));
    if (CmcReadSmcKey(key, (uint8_t *)&speed, &nSize, FALSE) == -1)
        return -1;
    
    return CmcConvertFpe2ToFloat(speed, sizeof(speed), 2);
}

// get fan ids
int CmcGetFanIds(int nCount, char fanIds[][20])
{
    char szKey[5] = {0};
    uint32_t key;
    uint8_t data[20];
    uint8_t nSize;
    int i;
    
    if (nCount == 0 || nCount > 9 || fanIds == NULL)
        return -1;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    for (i = 0; i < nCount; i++)
    {
        // get fan id
        snprintf(szKey, sizeof(szKey), SMCKEY_FID, i);
        key = *(uint32_t *)szKey;
        nSize = sizeof(data);
        
        CmcSwapBytes((uint8_t *)&key, sizeof(key));
        if (CmcReadSmcKey(key, (uint8_t *)data, &nSize, TRUE) == -1)
            return -1;
        
        memcpy(&fanIds[i], data + 4, nSize - 4);
        fanIds[i][nSize - 4] = '\0';
    }
    
    return 0;
}

// get fan speeds
// nCount
int CmcGetFanSpeeds(int nCount, double *fSpeeds)
{
    char szKey[5] = {0};
    int i;
    
    if (nCount == 0 || nCount > 9 || fSpeeds == NULL)
        return -1;
    
    if (CmcOpenSmc() == -1)
        return -1;
    
    for (i = 0; i < nCount; i++)
    {
        SMCVal_t val;
        snprintf(szKey, sizeof(szKey), SMCKEY_FDAC, i);
        if (SMCReadKey2(szKey, &val, g_connect) == 0)
        {
            fSpeeds[i] = parseSMCVal(val);
        }
        else
        {
            static int counts = 2;
            if (counts > 0)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SensorError" object:[NSString stringWithFormat:@"%s",val.dataType ] ];
                NSLog(@"CmcGetFanSpeeds Failed with dataType=%s", val.dataType);
                counts--;
            }
        }
    }
    
    // for test
    //speed[0] = 0;speed[1] = 0;
    //CmcConvertFloatToFpe2(fSpeeds[0], speed, 2);
    
    // dont close now
    //CmcCloseSmc();
    
    return 0;
}
