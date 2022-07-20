/*
 *  CmcProcessor.c
 *  TestFunction
 *
 *  Created by developer on 11-1-13.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <errno.h>
#include <mach/mach.h>
#include "CmcProcessor.h"
#include "McLogUtil.h"

// get cpu load average
// return -1 indicates error
int CmcGetLoadavg(double average[3])
{
    // get loadavg
    struct loadavg avg;
    size_t buf_size = sizeof(avg);
    int loadavg_names[] = {CTL_VM, VM_LOADAVG};
    
    if (average == NULL)
        return -1;
    
    if (sysctl(loadavg_names, 2, &avg, &buf_size, NULL, 0) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get cpu loadavg fail: %d", __FUNCTION__, errno);
        return -1;
    }
    
    for (int i = 0; i < 3; i++)
    {
        average[i] = (double)avg.ldavg[i] / (double)avg.fscale;
    }
    return 0;
}

// get processor set information
int CmcGetProcessSetInfo(struct processor_set_load_info *ploadinfo)
{
    kern_return_t kr;
    processor_set_name_t processor_default_set;
    mach_msg_type_number_t info_count;
    
    if (ploadinfo == NULL)
        return -1;
    
    kr = processor_set_default(mach_host_self(), &processor_default_set);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] get default processor set name fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    info_count = sizeof(struct processor_set_load_info);
    kr = processor_set_statistics(processor_default_set, 
                                  PROCESSOR_SET_LOAD_INFO,
                                  (processor_set_info_t)ploadinfo,
                                  &info_count);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] get processor set info fail: %d", __FUNCTION__, kr);
        return -1;
    }
    return 0;
}

// get process count
// return -1 indicates fail
int CmcGetProcessCount()
{
    struct processor_set_load_info load_info;
    if (CmcGetProcessSetInfo(&load_info) == -1)
        return -1;
    
    return load_info.task_count;
}

// get thread count
// return -1 indicates fail
int CmcGetThreadCount()
{
    struct processor_set_load_info load_info;
    if (CmcGetProcessSetInfo(&load_info) == -1)
        return -1;
    
    return load_info.thread_count;
}

// get cpu count
// return -1 indicates fail
int CmcGetCpuCount()
{
    int ncpu_count;
    size_t buf_size = sizeof(ncpu_count);
    int ncpu_names[] = {CTL_HW, HW_NCPU};
    
    if (sysctl(ncpu_names, 2, &ncpu_count, &buf_size, NULL, 0) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get cpu count fail: %d", __FUNCTION__, errno);
        return -1;
    }
    return ncpu_count;
}

// get cpu ticks, caller should alloc enough space for cpu_ticks
// index from 0 - 3 -> "user", "system", "idle", "nice"
// CPU_STATE_MAX - 4
// return -1 indicates fail
int CmcGetCpuTicks(unsigned int *cpu_ticks)
{
    kern_return_t kr;
    natural_t cpu_count;
    processor_info_array_t info_array;
    mach_msg_type_number_t info_count;
    processor_cpu_load_info_data_t *cpu_info;
    
    if (cpu_ticks == NULL)
        return -1;
    
    kr = host_processor_info(mach_host_self(), 
                             PROCESSOR_CPU_LOAD_INFO, 
                             &cpu_count,
                             &info_array,
                             &info_count);
    if (kr != KERN_SUCCESS)
    {
        McLog(MCLOG_ERR, @"[%s] get processor info fail: %d", __FUNCTION__, kr);
        return -1;
    }

    // calculate
    cpu_info = (processor_cpu_load_info_data_t *)info_array;
    for (int cpu_index = 0; cpu_index < cpu_count; cpu_index++)
    {
        for (int i = 0; i < CPU_STATE_MAX; i++)
        {
            cpu_ticks[cpu_index * CPU_STATE_MAX + i] = cpu_info[cpu_index].cpu_ticks[i];
        }
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)info_array, info_count * sizeof(int));
    return 0;
}

// get cpu brand name
int CmcGetCpuBrandString(char *name_str, size_t len)
{
    if (name_str == NULL || len < 10)
        return -1;
    
    if (sysctlbyname("machdep.cpu.brand_string", name_str, &len, NULL, 0) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get cpu brand string fail: %d", __FUNCTION__, errno);
        return -1;
    }
    
    return 0;
}

