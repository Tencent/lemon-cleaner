/*
 *  CmcSmartQuery.c
 *  TestFunction
 *
 *  Created by developer on 11-1-20.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOReturn.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <IOKit/storage/IOStorageProtocolCharacteristics.h>
#include "CmcSmartQuery.h"

// default sector size
#define kATADefaultSectorSize   512

// This constant comes from the SMART specification.  Only 30 values are allowed in any of the structures.
#define kSMARTAttributeCount    30

// The following attribute is optionally supported and is generally considered
// to be vendor-specific, although it appears that the majority of vendors
// do implement it.  For this sample code, this information was obtained from
// WikiPedia: <en.wikipedia.org/wiki/S.M.A.R.T.>
#define kWindowSMARTsDriveTempAttribute                     0xC2

// __attribute__ ((packed)) 的作用就是告诉编译器取消
// 结构在编译过程中的优化对齐,按照实际占用字节数进行对齐

typedef struct IOATASmartAttribute
{
    UInt8           attributeId;
    UInt16          flag;  
    UInt8           current;
    UInt8           worst;
    UInt8           rawvalue[6];
    UInt8           reserv;
}  __attribute__ ((packed)) IOATASmartAttribute;

typedef struct IOATASmartVendorSpecificData
{
    UInt16                  revisonNumber;
    IOATASmartAttribute     vendorAttributes [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificData;

/* Vendor attribute of SMART Threshold */
typedef struct IOATASmartThresholdAttribute
{
    UInt8           attributeId;
    UInt8           ThresholdValue;
    UInt8           Reserved[10];
} __attribute__ ((packed)) IOATASmartThresholdAttribute;

typedef struct IOATASmartVendorSpecificDataThresholds
{
    UInt16                          revisonNumber;
    IOATASmartThresholdAttribute    ThresholdEntries [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificDataThresholds;


// get device object
// pobjects         output buffer for objects
// maxcount         max object count can be stored in output buffer
// return device count, -1 indicates fail
int CmcGetSmartDevice(io_object_t *pobjects, int maxcount)
{
    kern_return_t       kr;
    CFDictionaryRef     searchDic;
    CFDictionaryRef     subDic;
    const void          *keys[1];
    const void          *values[1];
    io_iterator_t       iterator;
    io_object_t         tempobj;
    int                 count;
    
    if (pobjects == NULL || maxcount == 0)
        return -1;
    
    // search
    //  <dict>
    //      <key>IOPropertyMatch</key>
    //      <dict>
    //          <key>SMART Capable</key>
    //          <true/>
    //      </dict>
    // </dict>
    keys[0] = (void *)CFSTR(kIOPropertySMARTCapableKey);
    values[0] = (void *)kCFBooleanTrue;
    subDic = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
    keys[0] = (void *)CFSTR(kIOPropertyMatchKey);
    values[0] = (void *)subDic;
    searchDic = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1, NULL, NULL);
    
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, searchDic, &iterator);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] search SMART device fail: %d", __FUNCTION__, kr);
        
        CFRelease(subDic);
        return -1;
    }
    CFRelease(subDic);
    
    // enumerate
    count = 0;
    while ((tempobj = IOIteratorNext(iterator)) != 0)
    {
        pobjects[count] = tempobj;
        count++;
        if (count >= maxcount)
            break;
    }
    IOObjectRelease(iterator);
    
    return count;
}

// use SMART interface to get data
int CmcReadSmartDataFromInterface(IOATASMARTInterface **smartInterface, ATASMARTData *smartData)
{
    kern_return_t           kr;
    int                     ret = 0;
    
    kr = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, true);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] SMARTEnableDisableOperations fail: %d", __FUNCTION__, kr);
        return -1;
    }
    kr = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, true);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] SMARTEnableDisableAutosave fail: %d", __FUNCTION__, kr);
        
        (*smartInterface)->SMARTEnableDisableOperations(smartInterface, false);
        return -1;
    }
    kr = (*smartInterface)->SMARTExecuteOffLineImmediate(smartInterface, false);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] SMARTExecuteOffLineImmediate fail: %d", __FUNCTION__, kr);
        ret = -1;
        goto out;
    }
    kr = (*smartInterface)->SMARTReadData(smartInterface, smartData);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] SMARTReadData fail: %d", __FUNCTION__, kr);
        ret = -1;
        goto out;
    }
    kr = (*smartInterface)->SMARTValidateReadData(smartInterface, smartData);
    if (kr != kIOReturnSuccess)
    {
       //McLog(MCLOG_ERR, @"[%s] SMARTValidateReadData fail: %d", __FUNCTION__, kr);
        ret = -1;
        goto out;
    }
    
out:
    (*smartInterface)->SMARTEnableDisableOperations(smartInterface, false);
    (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, false);
    return ret;
}

// get SMART data
// object       device handle
int CmcGetSmartData(io_object_t object, ATASMARTData *smartData)
{
    IOCFPlugInInterface     **pluginInterface = NULL;
    IOATASMARTInterface     **smartInterface = NULL;
    kern_return_t           kr;
    SInt32                  score;
    HRESULT                 hr;
    int                     ret;
    
    if (smartData == NULL)
        return -1;
    
    // get plugin interface
    kr = IOCreatePlugInInterfaceForService(object, 
                                           kIOATASMARTUserClientTypeID, 
                                           kIOCFPlugInInterfaceID, 
                                           &pluginInterface, 
                                           &score);
    if (kr != kIOReturnSuccess || pluginInterface == NULL)
    {
       //McLog(MCLOG_ERR, @"[%s] create plugin interface fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    // get smart interface
    hr = (*pluginInterface)->QueryInterface(pluginInterface,
                                            CFUUIDGetUUIDBytes(kIOATASMARTInterfaceID),
                                            (LPVOID *)&smartInterface);
    if (hr != S_OK || smartInterface == NULL)
    {
       //McLog(MCLOG_ERR, @"[%s] get SMART interface fail: %d", __FUNCTION__, hr);
        
        IODestroyPlugInInterface(pluginInterface);
        return -1;
    }
    
    // read SMART data
    bzero(smartData, sizeof(ATASMARTData));
    ret = CmcReadSmartDataFromInterface(smartInterface, smartData);

    // release
    (*smartInterface)->Release(smartInterface);
    IODestroyPlugInInterface(pluginInterface);
    
    return ret;
}

uint64_t    g_badEntryIds[10] = {0};
int         g_nBadCount = 0;


bool isExternelDevice(io_object_t ioObject) {
    // "Protocol Characteristics" = {"Physical Interconnect"="SATA","Physical Interconnect Location"="External"}
    CFTypeRef retDic = IORegistryEntryCreateCFProperty(ioObject,
                                                       CFSTR(kIOPropertyProtocolCharacteristicsKey),
                                                       kCFAllocatorDefault,
                                                       0);
    if (retDic != NULL && CFGetTypeID(retDic) == CFDictionaryGetTypeID())
    {
        CFDictionaryRef protocolChar = (CFDictionaryRef)retDic;
        //NSLog(@"%@", protocolChar);
        const CFTypeRef location = CFDictionaryGetValue(protocolChar, CFSTR(kIOPropertyPhysicalInterconnectLocationKey));
        if (location != NULL && CFGetTypeID(location) == CFStringGetTypeID())
        {
            CFStringRef locationName = (CFStringRef)location;
            // external ?
            if (CFStringCompare(locationName, CFSTR(kIOPropertyExternalKey), 0) == kCFCompareEqualTo)
            {
                CFRelease(retDic);
                IOObjectRelease(ioObject);
                return true;
            }
        }
    }
    if (retDic != NULL) CFRelease(retDic);
    return false;
}

// get hard disk temperature
// return count of temperature got

int CmcGetSmartDriverTemperature(uint8_t *hddTemp, int maxTempCount)
{
    io_object_t                     smartobj[10];
    int                             smartobj_count;
    //io_name_t                       objname = {0};
    kern_return_t                   kr;
    uint64_t                        entryId = 0;
    ATASMARTData                    smartData;
    int                             i;
    int                             attrIdx;
    int                             tempCount;
    IOATASmartAttribute             *curAttribute;
    IOATASmartVendorSpecificData    *smartVendorData;
    
    if (hddTemp == NULL || maxTempCount == 0)
        return -1;
    
    // get object first
    smartobj_count = CmcGetSmartDevice(smartobj, 10);
    if (smartobj_count <= 0)
        return -1;
    
    tempCount = 0;
    for (i = 0; i < smartobj_count; i++)
    {
        // for test, print name
//        kr = IORegistryEntryGetName(smartobj[i], objname);
//        if (kr == kIOReturnSuccess)
//        {
//           //McLog(MCLOG_INFO, @"[%s] find SMART device [%d]: %s", __FUNCTION__, i, objname);
//        }
        // get entry id
        kr = IORegistryEntryGetRegistryEntryID(smartobj[i], &entryId);
        if (kr == kIOReturnSuccess)
        {
            //McLog(MCLOG_INFO, @"[%s] find SMART device id [%d]: %d", __FUNCTION__, i, entryId);
        }
        else 
        {
            IOObjectRelease(smartobj[i]);
            continue;
        }
        
        int j;
        for (j = 0; j < g_nBadCount; j++)
        {
            if (g_badEntryIds[j] == entryId)
            {
                break;
            }
        }
        if (j < g_nBadCount)
        {
            //McLog(MCLOG_INFO, @"[%s] Bad device id [%d]: %d", __FUNCTION__, i, entryId);
            // bad entry id
            IOObjectRelease(smartobj[i]);
            continue;
        }
        
        if (isExternelDevice(smartobj[i])) {
            continue;
        }

        BOOL getTemperature = NO;
        // get data
        if (CmcGetSmartData(smartobj[i], &smartData) == 0)
        {
            // find temperature info
            smartVendorData = (IOATASmartVendorSpecificData *)&(smartData.vendorSpecific1);
            for (attrIdx = 0; attrIdx < kSMARTAttributeCount; attrIdx++)
            {
                curAttribute = &(smartVendorData->vendorAttributes[attrIdx]);
                if (curAttribute->attributeId == kWindowSMARTsDriveTempAttribute)
                {
//                    NSLog(@"attributeId: %x current: %x flag: %x rawvalue: %x-%x-%x-%x-%x-%x",
//                          curAttribute->attributeId, curAttribute->current,
//                          curAttribute->flag, curAttribute->rawvalue[0], curAttribute->rawvalue[1],
//                          curAttribute->rawvalue[2], curAttribute->rawvalue[3], curAttribute->rawvalue[4],
//                          curAttribute->rawvalue[5]);
                    // temperature is ok?
                    if (curAttribute->rawvalue[0] > 0 && curAttribute->rawvalue[0] < 120)
                    {
                        // record
                        if (tempCount < maxTempCount)
                        {
                            hddTemp[tempCount] = curAttribute->rawvalue[0];
                            tempCount++;
                        }
                        getTemperature = YES;
                    }
                    break;
                }
            }
        }
        
        if (!getTemperature)
        {
            // add to bad id, do not try to get temperature next time
            if (g_nBadCount < sizeof(g_badEntryIds)/sizeof(uint64_t))
            {
                g_badEntryIds[g_nBadCount] = entryId;
                g_nBadCount++;
            }
            else
            {
                g_badEntryIds[0] = entryId;
            }
        }
        
        IOObjectRelease(smartobj[i]);
    }
    
    return tempCount;
}
