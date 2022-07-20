/*
 *  CmcMemory.m
 *  TestFunction
 *
 *  Created by developer on 11-3-7.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <errno.h>
#include <mach/mach.h>
#include "CmcMemory.h"
#include "McLogUtil.h"

// get stolen memory size
uint64_t CmcGetStolenMemorySize() 
{
	static int mib_reserved[CTL_MAXNAME];
	static int mib_unusable[CTL_MAXNAME];
	static int mib_other[CTL_MAXNAME];
	static size_t mib_reserved_len = 0;
	static size_t mib_unusable_len = 0;
	static size_t mib_other_len = 0;
	int r;
    
    uint64_t stolen_size = 0;
	
	if (0 == mib_reserved_len) 
    {
		mib_reserved_len = CTL_MAXNAME;
		r = sysctlnametomib("machdep.memmap.Reserved", 
                            mib_reserved,
                            &mib_reserved_len);
		if (-1 == r)
        {
			mib_reserved_len = 0;
            return 0;
        }
        
		mib_unusable_len = CTL_MAXNAME;
		r = sysctlnametomib("machdep.memmap.Unusable", 
                            mib_unusable,
                            &mib_unusable_len);	
		if (-1 == r)
        {
			mib_reserved_len = 0;
			return 0;
		}
        
		mib_other_len = CTL_MAXNAME;
		r = sysctlnametomib("machdep.memmap.Other",
                            mib_other,
                            &mib_other_len);
		if (-1 == r) 
        {
			mib_reserved_len = 0;
			return 0;
		}
	}		
    
	if(mib_reserved_len > 0 && mib_unusable_len > 0 && mib_other_len > 0) 
    {
		uint64_t reserved = 0, unusable = 0, other = 0;
		size_t reserved_len;
		size_t unusable_len;
		size_t other_len;
		
		reserved_len = sizeof(reserved);
		unusable_len = sizeof(unusable);
		other_len = sizeof(other);
        
		if (-1 == sysctl(mib_reserved, mib_reserved_len, &reserved, 
                         &reserved_len, NULL, 0)) 
        {
			return 0;
		}
        
		if (-1 == sysctl(mib_unusable, mib_unusable_len, &unusable,
                         &unusable_len, NULL, 0))
        {
			return 0;
		}
        
		if (-1 == sysctl(mib_other, mib_other_len, &other,
                         &other_len, NULL, 0))
        {
			return 0;
		}
        
		if(reserved_len == sizeof(reserved) 
		   && unusable_len == sizeof(unusable) 
		   && other_len == sizeof(other)) 
        {
            stolen_size = reserved + unusable + other;
            return stolen_size;
            //			uint64_t stolen = reserved + unusable + other;	
            //			uint64_t mb128 = 128 * 1024 * 1024ULL;
            //            
            //			if(stolen >= mb128) 
            //            {
            //				tsamp->pages_stolen = round_down_wired(stolen) / tsamp->pagesize;
            //			}
		}
	}
    return 0;
}

// totoal memory
uint64_t g_totalmem = 0;

// get physical memory information
// index from 0 - 3: free / inactive / active / wired
// index from 0 - 1: pagein / pageout
int CmcGetPhysMemoryInfo(uint64_t mem_info[5], uint64_t mem_inout[2])
{
    kern_return_t kr;
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t count = sizeof(vm_stat) / sizeof(natural_t);
    
    if (mem_info == NULL)
        return -1;
    
    // get total memory
    if (g_totalmem == 0)
    {
        uint64_t totalmem = 0;
        size_t size = sizeof(totalmem);
        int mib[] = {CTL_HW, HW_MEMSIZE};
        if (sysctl(mib, 2, &totalmem, &size, NULL, 0) == 0)
        {
            g_totalmem = totalmem;
        }
    }
    
    // get page size
    kr = host_page_size(mach_host_self(), &pagesize);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] get page size fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    // get vm info
    kr = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &count);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] get host statics fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    mem_info[0] = vm_stat.free_count * pagesize;
    mem_info[1] = vm_stat.inactive_count * pagesize;
    mem_info[2] = vm_stat.active_count * pagesize;
    if (g_totalmem == 0)
        mem_info[3] = vm_stat.wire_count * pagesize + CmcGetStolenMemorySize();
    else
        mem_info[3] = g_totalmem - mem_info[0] - mem_info[1] - mem_info[2];
    
    uint64_t cacheTotal = 0;
    {
        @try {
            NSString *shellString = @"vm_stat";
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/bin/sh"];
            
            NSArray *arguments = [NSArray arrayWithObjects:@"-c", shellString,nil];
            [task setArguments:arguments];
            
            NSPipe *pipe = [NSPipe pipe];
            [task setStandardOutput:pipe];
            NSFileHandle *fileHandle = [pipe fileHandleForReading];
            [task launch];
            
            NSData *data = [fileHandle readDataToEndOfFile];
            [task waitUntilExit];
            int status = [task terminationStatus];
            if (status == 0) {
                //NSLog(@"%s, Task succeeded.", __FUNCTION__);
            } else {
                [task terminate];
                NSLog(@"%s, Task failed.", __FUNCTION__);
            }
            [fileHandle closeFile];
            
            NSString *outputStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //NSLog(@"outputStr: %@", outputStr);
            NSArray* array = [outputStr componentsSeparatedByString:@"\n"];
            NSError* error;
            for (int i=0; i<[array count]; i++) {
                NSString* item = [array objectAtIndex:i];
                //NSLog(@"item: %@", item);
                
                NSRegularExpression* regexStr = [NSRegularExpression regularExpressionWithPattern:@"\\w*\\s\\w*:" options:0 error:&error];
                NSArray* checkArray = [regexStr matchesInString:item options:0 range:NSMakeRange(0, [item length])];
                if (checkArray.count == 0) {
                    continue;
                }
                NSTextCheckingResult* firstCheck = [checkArray objectAtIndex:0];
                if (firstCheck) {
                    NSString* firstString = [item substringWithRange:firstCheck.range];
                    //File-backed pages:
                    //Pages purgeable:
                    if ([firstString containsString:@"backed pages:"] ||
                        [firstString containsString:@"Pages purgeable:"]) {
                        NSRegularExpression* regexNumber = [NSRegularExpression regularExpressionWithPattern:@"\\d+" options:0 error:&error];
                        NSTextCheckingResult* checkNumber = [regexNumber firstMatchInString:item options:0 range:NSMakeRange(0, [item length])];
                        if (checkNumber) {
                            long long cachedSize = [[item substringWithRange:checkNumber.range] longLongValue];
                            cacheTotal += cachedSize;
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            
        }
    }
    //mem_info[4]为可使用的内存
    if (cacheTotal > 0) {
        //加一个pagesize保持和竞品一致?
        mem_info[4] = cacheTotal*pagesize+mem_info[0]+pagesize;
    } else {
        mem_info[4] = mem_info[0];
    }
    uint64_t totalRam = (mem_info[0] + mem_info[1] + mem_info[2] + mem_info[3]);
    //兼容处理异常情况：
    if (totalRam < mem_info[4]) {
        NSLog(@"CmcGetPhysMemoryInfo内存异常，totalRam: %llu, mem_info[4]:%llu", totalRam, mem_info[4]);
        if (totalRam < mem_info[0]) {
            mem_info[4] = totalRam / 2;
        } else {
            mem_info[4] = mem_info[0];
        }
    }
    
    // for test
    uint64_t pagein = vm_stat.pageins * pagesize;
    uint64_t pageout = vm_stat.pageouts * pagesize;
    mem_inout[0] = pagein;
    mem_inout[1] = pageout;
    //McLog(MCLOG_INFO, @"[%s] pagein %3.2f GB pageout %3.2f GB", __FUNCTION__, 
    //      (double)pagein / (1024*1024*1024), (double)pageout / (1024*1024*1024));
    
    return 0;
}

// get memory type and speed
// type - <"DDR3", "DDR3"> speed - <"1067 MHz", "1067 MHz">
int CmcGetMemoryType(char *mem_type, size_t type_size,
                     char *mem_speed, size_t speed_size)
{
    kern_return_t           kr;
    io_registry_entry_t     root;
    io_iterator_t           dev_iter;
    io_object_t             device;
    io_name_t               class_name;
    io_name_t               entry_name;
    CFMutableDictionaryRef  properties;
    CFDataRef               types;
    CFDataRef               speeds;
    
    root = IORegistryGetRootEntry(kIOMasterPortDefault);
    kr = IORegistryEntryCreateIterator(root, kIODeviceTreePlane, kIORegistryIterateRecursively, &dev_iter);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] create device iterator fail: %d", __FUNCTION__, kr);
        IOObjectRelease(root);
        return -1;
    }
    
    // find "memory" device
    while ((device = IOIteratorNext(dev_iter)) != 0)
    {
        // name = "IOService"
        kr = IOObjectGetClass(device, class_name);
        if (kr != KERN_SUCCESS || strcmp(class_name, kIOServiceClass) != 0)
        {
            IOObjectRelease(device);
            continue;
        }
        
        // entry name = "memory"
        kr = IORegistryEntryGetName(device, entry_name);
        if (kr != KERN_SUCCESS || strcmp(entry_name, "memory") != 0)
        {
            IOObjectRelease(device);
            continue;
        }
        
        // copy property dictionary
        kr = IORegistryEntryCreateCFProperties(device,
                                               &properties, 
                                               kCFAllocatorDefault,
                                               kNilOptions);
        if (kr == KERN_SUCCESS)
        {
            //NSLog(@"%@", (NSMutableDictionary *)properties);
            // get dimm-speeds / dimm-types
            // "1067 MHz", "1067 MHz" / "DDR3", "DDR3"
            // "dimm-speeds" = <31303637 204d487a 00313036 37204d48 7a00>;
            // "dimm-types" = <44445233 00444452 3300>;
            speeds = CFDictionaryGetValue(properties, CFSTR("dimm-speeds"));
            types = CFDictionaryGetValue(properties, CFSTR("dimm-types"));
            if (speeds != NULL && types != NULL)
            {
                // get the first string
                strncpy(mem_speed, (char *)CFDataGetBytePtr(speeds), speed_size - 1);
                strncpy(mem_type, (char *)CFDataGetBytePtr(types), type_size - 1);
                
                CFRelease(properties);
                IOObjectRelease(device);
                IOObjectRelease(dev_iter);
                IOObjectRelease(root);
                return 0;
            }
            
            CFRelease(properties);
        }
        
        IOObjectRelease(device);
        break;
    }
    
    IOObjectRelease(dev_iter);
    IOObjectRelease(root);
    return -1;
}
