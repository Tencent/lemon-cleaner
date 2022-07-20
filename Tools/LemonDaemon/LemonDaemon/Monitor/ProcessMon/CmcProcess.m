/*
 *  CmcProcess.m
 *  Untitled_3
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */
#include "CmcProcess.h"
#include <Security/Security.h>
#include <mach/thread_info.h>
#include <mach/task.h>
#include <mach/thread_act.h>
#include <time.h>
#include <sys/sysctl.h>
#include <mach/mach_traps.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include <mach/mach_vm.h>
#include <libproc.h>
#include <pwd.h>

#define TIME_VALUE_TO_UINT64(a) ((unsigned long long)((a)->seconds) * 1000000ULL + (a)->microseconds)
#define TIMEVAL_TO_UINT64(a) ((unsigned long long)((a)->tv_sec) * 1000000ULL + (a)->tv_usec)

void McGetProcessAllInfo(struct kinfo_proc *kinfo, int start, int length, ProcessInfo_t *proc)
{
    // prepare memory for argument
    kern_return_t kret;
    
    for(int i = start; i < length; i++)
    {
        pid_t infoPid = kinfo[i].kp_proc.p_pid;
   
        // init structure
        memset(&proc[i], 0, sizeof(ProcessInfo_t));
        proc[i].pid = kinfo[i].kp_proc.p_pid;
        proc[i].ppid = kinfo[i].kp_eproc.e_ppid;
        proc[i].uid = kinfo[i].kp_eproc.e_ucred.cr_uid;
        // get user name
        struct passwd *uidInfo = getpwuid(proc[i].uid);
        if (uidInfo != NULL)
            strncpy(proc[i].pUserName, uidInfo->pw_name, sizeof(proc[i].pUserName) - 1);
        else
            strcpy(proc[i].pUserName, "N/A");
        // flag -> P_LP64
        proc[i].p_flag = kinfo[i].kp_proc.p_flag;
        
        //NSLog(@"[%d] Name: %s", infoPid, kinfo[i].kp_proc.p_comm);
        
        // get execute path
        char exe_path[MAXPATHLEN] = {0};
        if (proc_pidpath(infoPid, exe_path, sizeof(exe_path)) == 0)
        {
            //NSLog(@"[ERR] get pid %d path fail", infoPid);
            proc[i].pExecutePath[0] = '\0';
        }
        else
        {
            strlcpy(proc[i].pExecutePath, exe_path, sizeof(proc[i].pExecutePath));
        }
        
        //get proc_name
        char exe_name[100] = {0};
        if (proc_name(infoPid, exe_name, sizeof(exe_name)) == 0) {
            proc[i].pExeName[0]= '\0';
        }
        else
        {
            strlcpy(proc[i].pExeName, exe_name, sizeof(proc[i].pExeName));
        }
        
        // get task info
        mach_port_t task;
        struct task_basic_info_64 ti;
        mach_msg_type_number_t count = TASK_BASIC_INFO_64_COUNT;
        
        kret = task_for_pid(mach_task_self(), infoPid, &task);
        if (kret != KERN_SUCCESS)
        {
            //McLog(MCLOG_ERR, @"[%s] pid[%d] task_for_pid get task error: %s",
            //      __FUNCTION__, infoPid, strerror(errno));
            continue;
        }
        
        kret = task_info(task, TASK_BASIC_INFO_64, (task_info_t)&ti, &count);
        if (kret != KERN_SUCCESS)
        {
            //McLog(MCLOG_ERR, @"[%s] pid[%d] task_info get task info error: %s", 
            //      __FUNCTION__, infoPid, strerror(errno));
        }
        else
        {   
            // get thread info
            thread_act_port_array_t threadList;
            mach_msg_type_number_t threadCount;
            
            kret = task_threads(task, &threadList, &threadCount);
            if (kret != KERN_SUCCESS)
            {
                //McLog(MCLOG_ERR, @"[%s] pid[%d] task_threads get threadinfo error: %s",
                //      __FUNCTION__, infoPid, strerror(errno));
            }
            else
            {
                for (int j = 0; j < threadCount; j++)
                {
                    thread_basic_info_data_t info;
                    mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
                    
                    kret = thread_info(threadList[j], THREAD_BASIC_INFO, (thread_info_t)&info, &count);
                    if (kret == KERN_SUCCESS && !(info.flags & TH_FLAGS_IDLE))
                    {
                        proc[i].cpu_time += TIME_VALUE_TO_UINT64(&info.user_time);
                        proc[i].cpu_time += TIME_VALUE_TO_UINT64(&info.system_time);
                    }
                    
                    // release port
                    mach_port_deallocate(mach_task_self(), threadList[j]);
                }
                
                proc[i].cpu_time += TIME_VALUE_TO_UINT64(&ti.user_time);
                proc[i].cpu_time += TIME_VALUE_TO_UINT64(&ti.system_time);
                
                struct timeval cur_time;
                gettimeofday(&cur_time, NULL);
                proc[i].current_time = TIMEVAL_TO_UINT64(&cur_time);
                
                proc[i].threadCount = threadCount;
                proc[i].resident_size = ti.resident_size;
                proc[i].virtual_size = ti.virtual_size;
                
                // release memory
                mach_vm_deallocate(mach_task_self(),
                                   (mach_vm_address_t)(uintptr_t)threadList, 
                                   threadCount * sizeof(*threadList));
            }
        }
        
        // release port
        mach_port_deallocate(mach_task_self(), task);
    }
}

// use pid to order data
void McGetProcessInfoByPid(struct kinfo_proc * kinfo,
                           ProcessInfo_t * proc,
                           int count,
                           size_t size,
                           BOOL isReverse)
{
    int length = (int)(size / sizeof(struct kinfo_proc));
    // order 
    if(isReverse)
    {
        for(int i = 0;i < length;i++)      
        {
            for(int j = 0;j < length - 1 - i;j++)
            {
                if(kinfo[j].kp_proc.p_pid < kinfo[j + 1].kp_proc.p_pid)
                {
                    struct kinfo_proc temp = kinfo[j];   
                    kinfo[j] = kinfo[j + 1];   
                    kinfo[j + 1] = temp;
                }
            }
        }
    }
    else
    {
        for(int i = 0;i < length;i++)      
        {
            for(int j = 0;j < length - 1 - i;j++)
            {
                if(kinfo[j].kp_proc.p_pid > kinfo[j + 1].kp_proc.p_pid)
                {
                    struct kinfo_proc temp = kinfo[j];   
                    kinfo[j] = kinfo[j + 1];   
                    kinfo[j + 1] = temp;
                }
            }
        }
    }
    // get process info
    McGetProcessAllInfo(kinfo,0,count,proc);
}

// use cpu usage order data
//void McGetProcessInfoByCPUUsage(struct kinfo_proc * kinfo,
//                                ProcessInfo_t * proc,
//                                int count,
//                                size_t size,
//                                BOOL isReverse)
//{
//    int length = size / sizeof(struct kinfo_proc);
//    ProcessInfo_t _proc[length];
//    // get process info
//    McGetProcessAllInfo(kinfo, 0, length, _proc);
//    // order
//    for(int i = 0;i < length;i++)
//    {
//        for(int j = 0;j < length - 1 - i;j++)
//        {
//            if(_proc[j].cpuUsage > _proc[j + 1].cpuUsage)
//            {
//                ProcessInfo_t temp = _proc[j];
//                _proc[j] = _proc[j + 1];
//                _proc[j + 1] = temp;
//            }
//        }
//    }
//    if(isReverse)
//    {
//        for(int i = 0; i < count; i++)
//            proc[i] = _proc[length - 1 - i];
//    }
//    else
//    {
//        for(int i = 0; i < count; i++)
//            proc[i] = _proc[i];
//    }
//}

// use resident memeory order data
void McGetProcessInfoByResident(struct kinfo_proc * kinfo,
                                ProcessInfo_t * proc,
                                int count,
                                size_t size,
                                BOOL isReverse)
{
    int length = (int)(size / sizeof(struct kinfo_proc));
    ProcessInfo_t _proc[length];
    // get process info
    McGetProcessAllInfo(kinfo, 0, length, _proc);
    // order
    for(int i = 0;i < length;i++)      
    {
        for(int j = 0;j < length - 1 - i;j++)
        {
            if(_proc[j].resident_size > _proc[j + 1].resident_size)
            {
                ProcessInfo_t temp = _proc[j];   
                _proc[j] = _proc[j + 1];   
                _proc[j + 1] = temp;
            }
        }
    }
    
    if(isReverse)
    {
        for(int i = 0; i < count; i++)
            proc[i] = _proc[length - 1 - i];
    }
    else
    {
        for(int i = 0; i < count; i++)
            proc[i] = _proc[i];
    }
    
}

// use virtual memeory order data
void McGetProcessInfoByVirtual(struct kinfo_proc * kinfo, 
                               ProcessInfo_t * proc, 
                               int count,
                               size_t size,
                               BOOL isReverse)
{
    int length = (int)(size / sizeof(struct kinfo_proc));
    ProcessInfo_t _proc[length];
    // get process info
    McGetProcessAllInfo(kinfo, 0, length, _proc);
    // order
    for(int i = 0;i < length;i++)      
    {
        for(int j = 0;j < length - 1 - i;j++)
        {
            if(_proc[j].virtual_size > _proc[j + 1].virtual_size)
            {
                ProcessInfo_t temp = _proc[j];   
                _proc[j] = _proc[j + 1];   
                _proc[j + 1] = temp;
            }
        }
    }
    
    if(isReverse)
    {
        for(int i = 0; i < count; i++)
            proc[i] = _proc[length - 1 - i];
    }
    else
    {
        for(int i = 0; i < count; i++)
            proc[i] = _proc[i];
    }
    
}

int CmcGetProcessInfo(ORDER_TYPE orderType, int count, BOOL isReverse, ProcessInfo_t **pproc)
{
    if (pproc == NULL) 
        return -1;
    
    // get process list
    struct kinfo_proc * kinfo;
    int mib[3];
    kern_return_t kret;
    size_t size = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;
    
    kret = sysctl(mib, 3, NULL, &size, NULL, 0);
    if(kret != KERN_SUCCESS)
        return -1;
    
    // make sure for enough memory
    size *= 2;
    kinfo = malloc(size);
    kret = sysctl(mib, 3, kinfo, &size, NULL, 0);
    if(kret != KERN_SUCCESS)
    {
        free(kinfo);
        return -1;
    }
    
    // if count = 0 -> get all process list
    int total_count = (int)(size / sizeof(struct kinfo_proc));
    if (count != 0)
        total_count = count;
    
    //McLog(MCLOG_INFO, @"[%s] ready to get process count: %d", __FUNCTION__, total_count);
    
    ProcessInfo_t *proc = malloc(sizeof(ProcessInfo_t) * total_count);
    switch (orderType)
    {
        case McprocNone:
            McGetProcessAllInfo(kinfo, 0, total_count, proc);
            break;
        case McprocPid:
            McGetProcessInfoByPid(kinfo, proc, total_count, size, isReverse);
            break;
        case McprocCPU:
            McGetProcessAllInfo(kinfo, 0, total_count, proc);
            //McGetProcessInfoByCPUUsage(kinfo, proc, total_count, size, isReverse);
            break;
        case McprocResident:
            McGetProcessInfoByResident(kinfo, proc, total_count, size, isReverse);
            break;
        case McprocVirtual:
            McGetProcessInfoByVirtual(kinfo, proc, total_count, size, isReverse);
            break;
        default:
            break;
    }
    free(kinfo);
    
    *pproc = proc;
    return total_count;
}

// fail: -1 64bit: 1 32bit: 0
int CmcCheckProcess64bit(pid_t pid)
{
    // get process list
    struct kinfo_proc *kinfo;
    int mib[4];
    kern_return_t kret;
    size_t size = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = pid;
    
    kret = sysctl(mib, 4, NULL, &size, NULL, 0);
    if(kret != KERN_SUCCESS)
        return -1;
    
    // make sure for enough memory
    size *= 2;
    kinfo = malloc(size);
    kret = sysctl(mib, 4, kinfo, &size, NULL, 0);
    if(kret != KERN_SUCCESS)
    {
        free(kinfo);
        return -1;
    }
    
    if (size / sizeof(struct kinfo_proc) == 0)
    {
        free(kinfo);
        return -1;
    }

    int ret = 0;
    if (kinfo[0].kp_proc.p_flag & P_LP64)
        ret = 1;
    
    free(kinfo);
    return ret;
}

// fail: -1 64bit: 1 32bit: 0
int IsHardware64bitCapable()
{
    int buf;
    size_t len;
    // hw.cpu64bit_capable or hw.optional.x86_64
    if (sysctlbyname("hw.cpu64bit_capable", &buf, &len, NULL, 0) == 0)
    {
        if (buf >= 1)
            return 1;
        else
            return 0;
    }
    
    return -1;
}
