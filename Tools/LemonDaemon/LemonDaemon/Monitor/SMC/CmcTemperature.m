/*
 *  CmcTemperature.c
 *  TestFunction
 *
 */

#include <stdint.h>
#include "CmcAppleSmc.h"
#include "CmcAppleSmc2.h"
#include "CmcTemperature.h"
#import "McCpuInfoSMC.h"

#define MAX_TEMP_V      110.0f

// H - heatsink D - diode

// temperature key definition
// cpu

// TCGc: GPU Intel Graphics
// TC0c: 未知
// TC0D: CPU diode CPU核心区域温度
// TC0E: CPU diode virtual 物理CPU虚拟化，代表虚拟CPU的核心温度。-- Lemon未使用
// TC0F: CPU diode filtered 经过处理的CPU核心区域温度，更稳定和可靠。-- Lemon未使用
// TC0H: CPU heatsink CPU散热器温度
// TC0P: CPU proximity CPU周围温度传感器
// TCAD: CPU package cpu外壳温度
uint32_t g_cpuKey[] = {'TC0P', 'TCGc', 'TC0D', 'TC0H', 'TC0c', 'TCAD'};

/// 初代M1芯片的Mac没有SMC。下列传感器并不能准确反应CPU的温度
UInt32Char_t cpuTempKeyM1_Early[] = {"Tc0a","Tc0b","Tc0x","Tc0z","Tc7a","Tc7b","Tc7x","Tc7z","Tc8a","Tc8b","Tc9a","Tc9b","Tc9x","Tc9z"};
// 传感器含义见三方开发者维护的列表
// https://github.com/exelban/stats/blob/master/Modules/Sensors/values.swift
UInt32Char_t cpuTempKeyM1[] = {"Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b", "Tg05", "Tg0D", "Tg0L", "Tg0T"}; // 后4个为GPU
UInt32Char_t cpuTempKeyM2[] = {"Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0X", "Tp0b", "Tp0f", "Tp0j", "Tg0f", "Tg0j"}; // 后2个为GPU
UInt32Char_t cpuTempKeyM3[] = {"Te05", "Te0L", "Te0P", "Te0S", "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E", "Tf14", "Tf18", "Tf19", "Tf1A", "Tf24", "Tf28", "Tf29", "Tf2A"}; // 后8个为GPU
int g_cpuKeyIndex = 0;

// battery
#define SMCKEY_TB0T     'TB0T'

// northbridge
uint32_t g_nbKey[] = {'TN0P', 'TM0P', 'Tm0P', 'TG0P', 'TN0D', 'TN0H', 'TG0H'};
int g_nbKeyIndex = 0;

// get cpu temperature for apple silicon
float GetCPUTemperature(void) {
    
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
    
    size_t key_size;
    McCpuType cupType = [McCpuInfoSMC getCpuType];
    switch (cupType) {
        case McCpuTypeM1:
            key_size = ARRAY_SIZE(cpuTempKeyM1_Early);
            break;
        case McCpuTypeM1Pro:
        case McCpuTypeM1Max:
        case McCpuTypeM1Ultra:
            key_size = ARRAY_SIZE(cpuTempKeyM1);
            break;
        case McCpuTypeM2:
        case McCpuTypeM2Pro:
        case McCpuTypeM2Max:
        case McCpuTypeM2Ultra:
            key_size = ARRAY_SIZE(cpuTempKeyM2);
            break;
        case McCpuTypeM3:
        case McCpuTypeM3Pro:
        case McCpuTypeM3Max:
        case McCpuTypeM3Ultra:
            key_size = ARRAY_SIZE(cpuTempKeyM3);
            break;
        default:
            return -1;
    }
    
    UInt32Char_t cpuTempKey[key_size];
    switch (cupType) {
        case McCpuTypeM1:
            memcpy(cpuTempKey, cpuTempKeyM1_Early, sizeof(cpuTempKeyM1_Early));
            break;
        case McCpuTypeM1Pro:
        case McCpuTypeM1Max:
        case McCpuTypeM1Ultra:
            memcpy(cpuTempKey, cpuTempKeyM1, sizeof(cpuTempKeyM1));
            break;
        case McCpuTypeM2:
        case McCpuTypeM2Pro:
        case McCpuTypeM2Max:
        case McCpuTypeM2Ultra:
            memcpy(cpuTempKey, cpuTempKeyM2, sizeof(cpuTempKeyM2));
            break;
        case McCpuTypeM3:
        case McCpuTypeM3Pro:
        case McCpuTypeM3Max:
        case McCpuTypeM3Ultra:
            memcpy(cpuTempKey, cpuTempKeyM3, sizeof(cpuTempKeyM3));
            break;
        default:
            return -1;
    }
    
    
    float temp = 0;
    size_t valid_count = 0;
    for (int i = 0; i < key_size; i++) {
        UInt32Char_t key;
        strcpy(key, cpuTempKey[i]);
        SMCVal_t val;
        io_connect_t conn = GetSmcConnect();
        int ret = SMCReadKey2(key, &val, conn);
        if (ret == kIOReturnSuccess) {
            float result = parseSMCVal(val);
            if (result > 0 && result < MAX_TEMP_V) {
                temp += result;
                valid_count++;
            }
        }
    }
    if (temp != 0 && valid_count != 0) {
        return temp / valid_count;
    }
    return -1;
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

