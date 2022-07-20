/*
 *  McSystem.m
 *  TestFunction
 *
 *  Created by developer on 11-1-12.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <string.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <errno.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <IOKit/IOKitLib.h>
#include "McSystem.h"
#include "McLogUtil.h"

#define kIOPlatformExpertDevice     "IOPlatformExpertDevice"
#define kIOPlatformModelKey         "model"

// get passed time in nanoseconds
uint64_t McGetAbsoluteNanosec()
{
    static mach_timebase_info_data_t sTimebaseInfo = {0};
    if (sTimebaseInfo.denom == 0)
        mach_timebase_info(&sTimebaseInfo);
    
    uint64_t nanoSecond = mach_absolute_time() * sTimebaseInfo.numer;
    if (sTimebaseInfo.denom != 0) {
        nanoSecond = nanoSecond / sTimebaseInfo.denom;
    }
    return nanoSecond;
}

// get system boot time via sysctl
// return seconds, -1 indicates error
long McGetBootTime()
{
    // get boot time
    struct timeval boot_time;
    size_t buf_size = sizeof(boot_time);
    int boot_time_names[] = {CTL_KERN, KERN_BOOTTIME};
    
    if (sysctl(boot_time_names, 2, &boot_time, &buf_size, NULL, 0) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get boot time fail: %d", __FUNCTION__, errno);
        return -1;
    }
    
    return boot_time.tv_sec;
}

// get machine serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int McGetMachineSerial(char *serial_buf, int buf_size)
{
    io_service_t platform;
    CFStringRef serial;
    
    // get IOPlatformExpertDevice service object
    platform = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                           IOServiceMatching(kIOPlatformExpertDevice));
    if (platform == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get platform expert device sevice fail", __FUNCTION__);
        return -1;
    }
    
    // get serial value
    serial = IORegistryEntryCreateCFProperty(platform, 
                                             CFSTR(kIOPlatformSerialNumberKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (serial == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get serial value fail", __FUNCTION__);
        
        IOObjectRelease(platform);
        return -1;
    }
    IOObjectRelease(platform);
    
    // output serial to buffer
    if (!CFStringGetCString(serial, serial_buf, buf_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert serial string fail", __FUNCTION__);
        
        CFRelease(serial);
        return -1;
    }
    
    CFRelease(serial);
    return 0;
}

// get machine model, UTF8 encoding
// model_buf        output buffer
// buf_size         size in bytes
int McGetMachineModel(char *model_buf, int buf_size)
{
    io_service_t platform;
    CFDataRef model;
    CFIndex modelSize;
    
    // get IOPlatformExpertDevice service object
    platform = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                           IOServiceMatching(kIOPlatformExpertDevice));
    if (platform == 0)
    {
        McLog(MCLOG_ERR, @"[%s] get platform expert device sevice fail", __FUNCTION__);
        return -1;
    }
    
    // get model value
    model = IORegistryEntryCreateCFProperty(platform, 
                                            CFSTR(kIOPlatformModelKey), 
                                            kCFAllocatorDefault, 
                                            kNilOptions);
    if (model == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get model value fail", __FUNCTION__);
        
        IOObjectRelease(platform);
        return -1;
    }
    IOObjectRelease (platform);
    
    // check output buffer size
    modelSize = CFDataGetLength(model);
    if (modelSize > buf_size - 1)
    {
        McLog(MCLOG_ERR, @"[%s] ouput buffer too small", __FUNCTION__);
        
        CFRelease(model);
        return -1;
    }
    // output model name to buffer
    memcpy(model_buf, CFDataGetBytePtr(model), CFDataGetLength(model));
    model_buf[CFDataGetLength(model) - 1] = '\0';
    
    CFRelease(model);
    return 0;
}
