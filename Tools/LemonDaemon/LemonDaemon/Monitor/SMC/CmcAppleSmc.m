/*
 *  CmcAppleSmc.c
 *  TestFunction
 *
 *  Created by developer on 11-1-17.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <string.h>
#include <IOKit/IOKitLib.h>
#include "CmcAppleSmc.h"

#define kAppleSMC   "AppleSMC"

// definitions collected from IOPMLibPrivate.c (for 10.6.6)*********************************

// Todo: verify kSMCKeyNotFound
enum {
    kSMCKeyNotFound = 0x84,
    kSMCKeyNotReadable = 0x85
};

/* Do not modify - defined by AppleSMC.kext */
enum {
    kSMCSuccess    = 0,
    kSMCError    = 1
};
enum {
    kSMCUserClientOpen  = 0,
    kSMCUserClientClose = 1,
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCWriteKey        = 6,
    kSMCGetKeyCount     = 7,
    kSMCGetKeyFromIndex = 8,
    kSMCGetKeyInfo      = 9
};
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCVersion
{
    unsigned char    major;
    unsigned char    minor;
    unsigned char    build;
    unsigned char    reserved;
    unsigned short   release;
    
} SMCVersion;
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCPLimitData
{
    uint16_t    version;
    uint16_t    length;
    uint32_t    cpuPLimit;
    uint32_t    gpuPLimit;
    uint32_t    memPLimit;
    
} SMCPLimitData;
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCKeyInfoData
{
    IOByteCount         dataSize;
    uint32_t            dataType;
    uint8_t             dataAttributes;
    
} SMCKeyInfoData;
/* Do not modify - defined by AppleSMC.kext */
typedef struct {
    uint32_t            key;
    SMCVersion          vers;
    SMCPLimitData       pLimitData;
    SMCKeyInfoData      keyInfo;
    uint8_t             result;
    uint8_t             status;
    uint8_t             data8;
    uint32_t            data32;
    uint8_t             bytes[32];
}  SMCParamStruct;

//******************************************************************************************

// connection to SMC service
io_connect_t g_connect = 0;

// open connection
int CmcOpenSmc()
{
    CFMutableDictionaryRef matchDictionary;
    kern_return_t kr;
    io_iterator_t iterator;
    io_object_t device;
 
    if (g_connect != 0)
    {
        //McLog(MCLOG_WARN, @"[%s] SMC connection already exists", __FUNCTION__);
        return 0;
    }
    
    // get service object
    matchDictionary = IOServiceMatching(kAppleSMC);
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchDictionary, &iterator);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] get SMC matching service fail: %d", __FUNCTION__, kr);
        return -1;
    }
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0)
    {
       //McLog(MCLOG_ERR, @"[%s] no SMC service exists", __FUNCTION__);
        return -1;
    }
    
    // open service
    kr = IOServiceOpen(device, mach_task_self(), 0, &g_connect);
    IOObjectRelease(device);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] open SMC service fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    return 0;
}

// close SMC connection
void CmcCloseSmc()
{
    if (g_connect != 0)
    {
        IOServiceClose(g_connect);
        g_connect = 0;
    }
}

io_connect_t GetSmcConnect(){
    CmcOpenSmc();
    return g_connect;
}

// call through SMC connection
kern_return_t CmcCallSmc(int selector, SMCParamStruct *inputStruct, SMCParamStruct *outputStruct)
{
    size_t inputSize = sizeof(SMCParamStruct);
    size_t outputSize = sizeof(SMCParamStruct);
    return IOConnectCallStructMethod(g_connect,
                                     selector,
                                     inputStruct,
                                     inputSize,
                                     outputStruct,
                                     &outputSize);
}

// write SMC key value
int CmcWriteSmcKey(uint32_t key, const uint8_t *input_buf, uint8_t buf_size)
{
    SMCParamStruct inputStruct;
    SMCParamStruct outputStruct;
    kern_return_t kr;
    
    if (key == 0 || input_buf == NULL || buf_size == 0)
        return -1;
    
    bzero(&inputStruct, sizeof(SMCParamStruct));
    bzero(&outputStruct, sizeof(SMCParamStruct));
    
    // get key info first
    inputStruct.data8 = kSMCGetKeyInfo;
    inputStruct.key = key;
    
    kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
    if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
    {
        //McLog(MCLOG_ERR, @"[%s] SMC get key info fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    if (buf_size != outputStruct.keyInfo.dataSize)
    {
        // size check
        return -1;
    }
    
    // write
    inputStruct.data8 = kSMCWriteKey;
    inputStruct.key = key;
    inputStruct.keyInfo.dataSize = buf_size;
    memcpy(inputStruct.bytes, input_buf, buf_size);
    
    bzero(&outputStruct, sizeof(SMCParamStruct));
    kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
    if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
    {
        return -1;
    }
    
    return 0;
}


// read SMC key value
// key          4 bytes key registed by apple smc
int CmcReadSmcKey(uint32_t key, uint8_t *out_buf, uint8_t *buf_size, boolean_t check_size)
{
    SMCParamStruct inputStruct;
    SMCParamStruct outputStruct;
    kern_return_t kr;
    
    if (key == 0 || out_buf == NULL || buf_size == NULL)
        return -1;
    
    // first to determine data size
    if (check_size)
    {
        bzero(&inputStruct, sizeof(SMCParamStruct));
        bzero(&outputStruct, sizeof(SMCParamStruct));
        inputStruct.data8 = kSMCGetKeyInfo;
        inputStruct.key = key;
        
        kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
        if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
        {
            //McLog(MCLOG_ERR, @"[%s] SMC get key info fail: %d", __FUNCTION__, kr);
            return -1;
        }
        
        // check size
        if (*buf_size < outputStruct.keyInfo.dataSize)
        {
//           //McLog(MCLOG_ERR,
//                  @"[%s] SMC get key buffer too small: %d should: %d",
//                  __FUNCTION__,
//                  *buf_size,
//                  outputStruct.keyInfo.dataSize);
            
            *buf_size = outputStruct.keyInfo.dataSize;
            return -1;
        }
        
        // set size
        *buf_size = outputStruct.keyInfo.dataSize;
    }
    
    // get key value
    bzero(out_buf, *buf_size);
    bzero(&inputStruct, sizeof(SMCParamStruct));
    bzero(&outputStruct, sizeof(SMCParamStruct));
    inputStruct.data8 = kSMCReadKey;
    inputStruct.key = key;
    inputStruct.keyInfo.dataSize = *buf_size;
    
    kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
    if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
    {
        //McLog(MCLOG_ERR, @"[%s] SMC get key value fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    // set size
    *buf_size = inputStruct.keyInfo.dataSize;
    memcpy(out_buf, outputStruct.bytes, *buf_size);
    return 0;
}

// check size and type
int CmcCheckSmcKey(uint32_t key, uint8_t *buf_size, uint32_t* buf_type)
{
    SMCParamStruct inputStruct;
    SMCParamStruct outputStruct;
    kern_return_t kr;
    
    bzero(&inputStruct, sizeof(SMCParamStruct));
    bzero(&outputStruct, sizeof(SMCParamStruct));
    inputStruct.data8 = kSMCGetKeyInfo;
    inputStruct.key = key;
    
    kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
    if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
    {
        return -1;
    }
    
    // set size
    *buf_size = outputStruct.keyInfo.dataSize;
    
    // set type
    *buf_type = outputStruct.keyInfo.dataType;
    char ctype[5]= {0};
    __sprintf_chk(ctype, 0, 5, "%c%c%c%c", outputStruct.keyInfo.dataType>>24, outputStruct.keyInfo.dataType>>16, outputStruct.keyInfo.dataType>>8, outputStruct.keyInfo.dataType);
    NSLog(@"CmcReadSmcKey:size=%d,type=%s", *buf_size, ctype);
    
    return 0;
}

// swap byte
void CmcSwapBytes(uint8_t *data, uint32_t size)
{
    uint8_t temp;
    uint32_t i;
    
    for (i = 0; i < size / 2; i++)
    {
        temp = data[i];
        data[i] = data[size - i - 1];
        data[size - i - 1] = temp;
    }
}

// convert ui16
uint16_t CmcConvertUi16(uint8_t *data)
{
    return (data[1] + data[0] * 256);
}

// convert ui32
uint32_t CmcConvertUi32(uint8_t *data)
{
    return (data[3] + data[2] * 256 + data[1] * 256 * 256 + data[0] * 256 * 256 * 256);
}

// convert float to fpe2
void CmcConvertFloatToFpe2(float value, uint8_t *out_data, uint32_t size)
{
    // assume that e = 2
    if (size != 2)
        return;
    
    int nValue = (int)value;
    // 1000000
    out_data[0] = nValue / 64;
    out_data[1] = (nValue % 64) * 4;
}

// convert fpe2 to float
float CmcConvertFpe2ToFloat(uint8_t *data, uint32_t size, int e)
{
    float total = 0;
    uint32_t i;
    
    for (i = 0; i < size; i++)
    {
        if (i == (size - 1))
            total += (data[i] & 0xff) >> e;
        else
            total += data[i] << (size - 1 - i) * (8 - e);
    }
    
    return total;
}

// convert sp78 to double
double CmcConvertSp78ToDouble(uint8_t *data)
{
    return ((data[0] * 256 + data[1]) >> 2) / 64.0;
}

// print all keys
void CmcPrintAllSmcKeys()
{
    uint32_t keyCount;
    uint32_t tempKey;
    uint32_t i;
    uint32_t j;
    uint8_t nSize;
    SMCParamStruct inputStruct;
    SMCParamStruct outputStruct;
    kern_return_t kr;
    char szKeyName[5] = {0};
    char szKeyType[5] = {0};
    bool printinfo = true;
    
    if (CmcOpenSmc() == -1)
        return;
    
    // get total key count
    nSize = sizeof(keyCount);
    if (CmcReadSmcKey('#KEY', (uint8_t *)&keyCount, &nSize, FALSE) == -1)
        return;
    
    CmcSwapBytes((uint8_t *)&keyCount, sizeof(uint32_t));
    printf("Total key: %d\n", keyCount);
    
    // enum all key value and type
    for (i = 0; i < keyCount; i++)
    {
        // get key name
        bzero(&inputStruct, sizeof(SMCParamStruct));
        bzero(&outputStruct, sizeof(SMCParamStruct));
        inputStruct.data8 = kSMCGetKeyFromIndex;
        inputStruct.data32 = i;
        
        kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
        if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
        {
            printf("SMC get index key [%d] fail: %d\n", i, kr);
            return;
        }
        
        tempKey = outputStruct.key;
        *(uint32_t *)szKeyName = CmcConvertUi32((uint8_t *)&outputStruct.key);
        printf("[%03d] Key: %s ", i, szKeyName);
        
        // get key info data size
        bzero(&inputStruct, sizeof(SMCParamStruct));
        bzero(&outputStruct, sizeof(SMCParamStruct));
        inputStruct.data8 = kSMCGetKeyInfo;
        inputStruct.key = tempKey;
        
        kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
        if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
        {
            printf("SMC get index key [%d] info fail: %d\n", i, kr);
            return;
        }
        
        *(uint32_t *)szKeyType = CmcConvertUi32((uint8_t *)&outputStruct.keyInfo.dataType);
        printf("Size: %d Type: %s ", (int)outputStruct.keyInfo.dataSize, szKeyType);
        
        // get key value
        inputStruct.data8 = kSMCReadKey;
        inputStruct.key = tempKey;
        inputStruct.keyInfo.dataSize = outputStruct.keyInfo.dataSize;
        bzero(&outputStruct, sizeof(SMCParamStruct));
        
        kr = CmcCallSmc(kSMCHandleYPCEvent, &inputStruct, &outputStruct);
        if (kr != kIOReturnSuccess || outputStruct.result != kSMCSuccess)
        {
            printf("SMC get index key [%d] value fail: %d\n", i, kr);
            continue;
        }
        
        // print data
        printinfo = true;
        if (strcmp(szKeyType, "sp78") == 0)
        {
            printf("Value: %f ", CmcConvertSp78ToDouble(outputStruct.bytes));
            printinfo = false;
        }
        if (strcmp(szKeyType, "fpe2") == 0)
        {
            printf("Vaule: %f ", CmcConvertFpe2ToFloat(outputStruct.bytes, 2, 2));
            printinfo = false;
        }
        if (strcmp(szKeyType, "ui8") == 0)
        {
            printf("Vaule: %d ", outputStruct.bytes[0]);
            printinfo = false;
        }
        if (strcmp(szKeyType, "ui16") == 0)
        {
            printf("Vaule: %d ", CmcConvertUi16(outputStruct.bytes));
            printinfo = false;
        }
        if (strcmp(szKeyType, "ui32") == 0)
        {
            printf("Vaule: %d ", CmcConvertUi32(outputStruct.bytes));
            printinfo = false;
        }
        
        if (printinfo)
        {
            printf("Data: ");
            for (j = 0; j < inputStruct.keyInfo.dataSize; j++)
            {
                printf("%02x ", outputStruct.bytes[j]);
            }
        }
        printf("\n");
    }
    
    
    //CmcCloseSmc();
}

