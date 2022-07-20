/*
 *  CmcDisk.c
 *  TestFunction
 *
 *  Created by developer on 11-1-25.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <sys/param.h>
#include <sys/mount.h>
#include <errno.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOBlockStorageDriver.h>
#include <CoreFoundation/CFBundle.h>
#include "CmcDisk.h"
#include "McLogUtil.h"

#define kIOBlockStorageDriver   "IOBlockStorageDriver"

// get file system stat where 'path' is mounted
// return in bytes
int CmcGetFsStat(const char *path, uint64_t *freeBytes, uint64_t *totalBytes)
{
    struct statfs stat = {0};
    
    if (freeBytes == NULL || totalBytes == NULL)
        return -1;
    
    // get file system info
    if (statfs(path, &stat) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get fs stat fail: %d", __FUNCTION__, errno);
        return -1;
    }
    
    *freeBytes = stat.f_bfree * stat.f_bsize;
    *totalBytes = stat.f_blocks * stat.f_bsize;
    return 0;
}

int CmcGetFsStatByFM(NSString *path, uint64_t *freeBytes, uint64_t *totalBytes)
{
    
    NSError *error = nil;
    NSDictionary* fileAttributes =[[NSFileManager defaultManager] attributesOfFileSystemForPath:path error:&error];
    unsigned long long freeSize = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
    unsigned long long totalSize = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];
    
    *freeBytes = freeSize;
    *totalBytes = totalSize;
    if(error != nil){
        NSLog(@"CmcGetFsStatByFM freesize is %llu, total size is %llu ,error is %@", freeSize, totalSize, (error == nil)? @"nil": error );
        return -1;
    }
    return 0;
}

/*
 {
 DAAppearanceTime = "320033960.293127";
 DABusName = PMP;
 DABusPath = "IODeviceTree:/PCI0@0/SATA@B/PRT0@0/PMP@0";
 DADeviceInternal = 1;
 DADeviceModel = "FUJITSU MJA2160BH FFS G1                ";
 DADevicePath = "IOService:/AppleACPIPlatformExpert/PCI0@0/AppleACPIPCI/SATA@B/AppleMCP79AHCI/PRT0@0/IOAHCIDevice@0/AppleAHCIDiskDriver/IOAHCIBlockStorageDevice";
 DADeviceProtocol = SATA;
 DADeviceRevision = 0081001D;
 DADeviceUnit = 0;
 DAMediaBSDMajor = 14;
 DAMediaBSDMinor = 2;
 DAMediaBSDName = disk0s2;
 DAMediaBSDUnit = 0;
 DAMediaBlockSize = 512;
 DAMediaContent = "48465300-0000-11AA-AA11-00306543ECAC";
 DAMediaEjectable = 0;
 DAMediaIcon =     {
 CFBundleIdentifier = "com.apple.iokit.IOStorageFamily";
 IOBundleResourceFile = "Internal.icns";
 };
 DAMediaKind = IOMedia;
 DAMediaLeaf = 1;
 DAMediaName = Customer;
 DAMediaPath = "IODeviceTree:/PCI0@0/SATA@B/PRT0@0/PMP@0/@0:2";
 DAMediaRemovable = 0;
 DAMediaSize = 159697911808;
 DAMediaUUID = "<CFUUID 0x1005048b0> 00004B78-7FBE-0000-0604-000054130000";
 DAMediaWhole = 0;
 DAMediaWritable = 1;
 DAVolumeKind = hfs;
 DAVolumeMountable = 1;
 DAVolumeName = "Macintosh HD";
 DAVolumeNetwork = 0;
 DAVolumePath = "file://localhost/";
 DAVolumeUUID = "<CFUUID 0x100504440> 6F704A33-B205-30F5-97CE-1B6C27318EAF";
 }
 */
// get disk description where 'path' is mounted
// path - "/" to get the internal hard disk
// also may return icon path for the disk
int CmcGetDiskDescr(const char *path,
                    char *device_name,
                    char *volum_name,
                    char *icns_path,
                    char *kind_name,
                    int name_size,
                    Boolean *ejectable,
                    Boolean *internal,
                    Boolean *network,
                    Boolean *writeable)
{
    DASessionRef    session;
    DADiskRef       disk;
    CFURLRef        pathUrl;
    CFDictionaryRef diskDic;
    CFStringRef     deviceName;
    CFStringRef     volName;
    CFStringRef     bundleId;
    CFStringRef     resourceFile;
    CFStringRef     kindName;
    CFBooleanRef    boolValue;
    
    // create disk session
    session = DASessionCreate(kCFAllocatorDefault);
    if (session == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] create da session fail", __FUNCTION__);
        return -1;
    }
    
    // create disk object and get description dictionary
    // bsd name like "/dev/disk0s1"
    // use "diskutil list" to check
    //disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, stat.f_mntfromname);
    
    // directly use path
    pathUrl = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (const UInt8 *)path, strlen(path), YES);
    disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, pathUrl);
    if (disk == NULL)
    {
        //McLog(MCLOG_ERR, @"[%s] create disk fail", __FUNCTION__);
        
        CFRelease(pathUrl);
        CFRelease(session);
        return -1;
    }
    diskDic = DADiskCopyDescription(disk);
    if (diskDic == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] copy disk description fail", __FUNCTION__);
        
        CFRelease(pathUrl);
        CFRelease(session);
        CFRelease(disk);
        return -1;
    }
    
    //NSLog(@"Disk Info:\n%@", diskDic);
    
    // kDADiskDescriptionDeviceModelKey - FUJITSU ...
    // kDADiskDescriptionVolumeNameKey - Macintosh HD
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionDeviceModelKey, (const void **)&deviceName))
    {
        if (!CFStringGetCString(deviceName, device_name, name_size, kCFStringEncodingUTF8))
        {
            McLog(MCLOG_ERR, @"[%s] convert disk device name string fail", __FUNCTION__);
        }
        else
        {
            // delete all the blanks at the end
            while (device_name[strlen(device_name) - 1] == ' ')
                device_name[strlen(device_name) - 1] = '\0';
        }
        
    }
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionVolumeNameKey, (const void **)&volName))
    {
        if (!CFStringGetCString(volName, volum_name, name_size, kCFStringEncodingUTF8))
        {
            McLog(MCLOG_ERR, @"[%s] convert disk volume name string fail", __FUNCTION__);
        }
    }
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionVolumeKindKey, (const void **)&kindName))
    {
        if (!CFStringGetCString(kindName, kind_name, name_size, kCFStringEncodingUTF8))
        {
            McLog(MCLOG_ERR, @"[%s] convert volume kind name string fail", __FUNCTION__);
        }
    }
    
    CFDictionaryRef iconDic;
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionMediaIconKey, (const void **)&iconDic))
    {
        //NSLog(@"Media Icon: %@", (NSDictionary *)iconDic);
        if (CFDictionaryGetValueIfPresent(iconDic, CFSTR("CFBundleIdentifier"), (const void **)&bundleId)
            && CFDictionaryGetValueIfPresent(iconDic, CFSTR("IOBundleResourceFile"), (const void **)&resourceFile))
        {
            // com.apple.iokit.IOStorageFamily - IOStorageFamily
            CFRange range = CFStringFind(bundleId, CFSTR("."), kCFCompareBackwards);
            range.location++;
            range.length = CFStringGetLength(bundleId) - range.location;
            CFStringRef bundleName = CFStringCreateWithSubstring(kCFAllocatorDefault, bundleId, range);
            // fix directory to "/System/Library/Extensions/%s.kext/Contents/Resources/%s"
            CFStringRef path = CFStringCreateWithFormat(kCFAllocatorDefault,
                                                        NULL,
                                                        CFSTR("/System/Library/Extensions/%@.kext/Contents/Resources/%@"),
                                                        bundleName,
                                                        resourceFile);
            CFStringGetCString(path, icns_path, name_size, kCFStringEncodingUTF8);
            CFRelease(bundleName);
            CFRelease(path);
        }
    }
    
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionMediaEjectableKey, (const void **)&boolValue))
        *ejectable = CFBooleanGetValue(boolValue);
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionDeviceInternalKey, (const void **)&boolValue))
        *internal = CFBooleanGetValue(boolValue);
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionVolumeNetworkKey, (const void **)&boolValue))
        *network = CFBooleanGetValue(boolValue);
    if (CFDictionaryGetValueIfPresent(diskDic, kDADiskDescriptionMediaWritableKey, (const void **)&boolValue))
        *writeable = CFBooleanGetValue(boolValue);
    
    // if DAMediaRemovable = 1 not set to internal
    boolValue = CFDictionaryGetValue(diskDic, kDADiskDescriptionMediaRemovableKey);
    if (boolValue != NULL && CFBooleanGetValue(boolValue))
        *internal = false;
    
    CFRelease(pathUrl);
    CFRelease(diskDic);
    CFRelease(session);
    CFRelease(disk);
    return 0;
}

io_object_t g_blockDrivers[50] = {0};
int         g_nDriverCount = 0;

// get all available block drivers
void CmcGetAllBlockDrivers()
{
    CFMutableDictionaryRef      matchDictionary;
    io_iterator_t               iterator;
    kern_return_t               kr;
    io_object_t                 driver;
    
    if (g_nDriverCount > 0)
        return;
    
    // Get the list of all drive objects
    matchDictionary = IOServiceMatching(kIOBlockStorageDriver);
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchDictionary, &iterator);
    if (kr != kIOReturnSuccess)
    {
        McLog(MCLOG_ERR, @"[%s] find block storage driver fail: %d", __FUNCTION__, kr);
        return;
    }
    while ((driver = IOIteratorNext(iterator)) != 0)
    {
        g_blockDrivers[g_nDriverCount] = driver;
        g_nDriverCount++;
        if (g_nDriverCount >= sizeof(g_blockDrivers)/sizeof(io_object_t))
            break;
    }
    IOObjectRelease(iterator);
}

// release all block drivers
void CmcReleaseAllBlockDrivers()
{
    for (int i = 0; i < g_nDriverCount; i++)
    {
        if (g_blockDrivers[i] != 0)
            IOObjectRelease(g_blockDrivers[i]);
    }
    g_nDriverCount = 0;
}

// get disk read and write bytes information
// this function return total bytes information include all storage device
int CmcGetDiskReadWriteBytes(uint64_t *readBytes, uint64_t *writeBytes)
{
    kern_return_t               kr;
    io_object_t                 driver;
    CFDictionaryRef             properties;
    CFDictionaryRef             statistics;
    CFNumberRef                 number;
    UInt64                      value;
    
    if (readBytes == NULL || writeBytes == NULL)
        return -1;
    
    // init to zero
    *readBytes = 0;
    *writeBytes = 0;
    
    CmcGetAllBlockDrivers();
    
    for (int i = 0; i < g_nDriverCount; i++)
    {
        driver = g_blockDrivers[i];
        number = NULL;
        properties = NULL;
        statistics = NULL;
        value = 0;
        
        if (driver == 0)
            continue;
        
        // Obtain the properties for this drive object
        kr = IORegistryEntryCreateCFProperties(driver,
                                               (CFMutableDictionaryRef *)&properties,
                                               kCFAllocatorDefault,
                                               kNilOptions);
        if (kr != kIOReturnSuccess)
        {
            McLog(MCLOG_ERR, @"[%s] get driver properties fail: %d", __FUNCTION__, kr);
            
            // the disk disappear
            IOObjectRelease(driver);
            g_blockDrivers[i] = 0;
            return -1;
        }
        
        if (properties != NULL)
        {
            // Obtain the statistics from the drive properties
            statistics = CFDictionaryGetValue(properties,
                                              CFSTR(kIOBlockStorageDriverStatisticsKey));
            if (statistics != NULL)
            {
                // Get bytes read
                number = CFDictionaryGetValue(statistics,
                                              CFSTR(kIOBlockStorageDriverStatisticsBytesReadKey));
                if (number != NULL)
                {
                    CFNumberGetValue(number, kCFNumberSInt64Type, &value);
                    *readBytes += value;
                }
                
                // Get bytes written
                number = CFDictionaryGetValue(statistics,
                                              CFSTR(kIOBlockStorageDriverStatisticsBytesWrittenKey));
                if (number != NULL)
                {
                    CFNumberGetValue(number, kCFNumberSInt64Type, &value);
                    *writeBytes += value;
                }
            }
            
            CFRelease(properties);
        }
    }
    return 0;
}

