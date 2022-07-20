//
//  CmcProcInfo.m
//  ProcessInfo
//

//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <libproc.h>
#import <pwd.h>
#import "CmcProcInfo.h"

#define TIMEVAL_TO_UINT64(a) ((unsigned long long)((a)->tv_sec) * 1000000ULL + (a)->tv_usec)

int CmcFillAllProcInfo(ProcessInfo_t ** pInfo_t)
{
    // get all pid list
    int pid_size = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (pid_size <= 0)
    {
        NSLog(@"[err] get pid count fail: %s", strerror(errno));
        return -1;
    }
    
    pid_size *= 2;
    int *pid_array = malloc(pid_size);
    pid_size = proc_listpids(PROC_ALL_PIDS, 0, pid_array, pid_size);
    if (pid_size < 0)
    {
        free(pid_array);
        NSLog(@"[err] get pid list fail: %s", strerror(errno));
        return -1;
    }
    
    // loop all processes
    int pid;
	struct proc_taskallinfo task_info;
    int process_count = pid_size/sizeof(int);
    int ret_count = 0;
    
    ProcessInfo_t *proc = malloc(sizeof(ProcessInfo_t) * process_count);
    
    for (int i = 0; i < process_count; i++)
    {
        memset(&proc[ret_count], 0, sizeof(ProcessInfo_t));
        
        if ((pid = pid_array[i]) <= 0)
            continue;
        
        //NSLog(@"[info] ready to get info of %d", pid);
        
        if (proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &task_info, sizeof(task_info)) <= 0)
        {
            if (errno != ESRCH)
            {
                // root process
                //NSLog(@"[err] get pid %d info fail: %s", pid, strerror(errno));
            }
            continue;
        }
        
        uint64_t cpu_time = (task_info.ptinfo.pti_total_user + task_info.ptinfo.pti_total_system)/1000;
        proc[ret_count].pid = pid;
        proc[ret_count].ppid = task_info.pbsd.pbi_ppid;
        proc[ret_count].uid = task_info.pbsd.pbi_uid;
        if (task_info.pbsd.pbi_flags & PROC_FLAG_LP64)
            proc[ret_count].p_flag |= MCPROC_LP64;
        proc[ret_count].resident_size = task_info.ptinfo.pti_resident_size;
        proc[ret_count].virtual_size = task_info.ptinfo.pti_virtual_size;
        proc[ret_count].threadCount = task_info.ptinfo.pti_threadnum;
        proc[ret_count].cpu_time = cpu_time;
        
        // get current time
        struct timeval cur_time;
        gettimeofday(&cur_time, NULL);
        proc[ret_count].current_time = TIMEVAL_TO_UINT64(&cur_time);
        
        struct passwd *uidInfo = getpwuid(task_info.pbsd.pbi_uid);
        if (uidInfo != NULL)
            memcpy(proc[ret_count].pUserName, uidInfo->pw_name, strlen(uidInfo->pw_name));        
        else
            strcpy(proc[ret_count].pUserName, "N/A");
        
        char exe_path[MAXPATHLEN] = {0};
        if (proc_pidpath(pid, exe_path, sizeof(exe_path)) == 0)
        {
            // get path fail
        }
        else
        {
            strncpy(proc[i].pExecutePath, exe_path, sizeof(proc[i].pExecutePath) - 1);
        }
        
//        NSLog(@"pid %d path %s user %s thread: %d",
//              proc[ret_count].pid, proc[ret_count].pExecutePath,
//              proc[ret_count].pUserName, proc[ret_count].threadCount);
        
        ret_count++;
    }
    
    free(pid_array);
    *pInfo_t = proc;

    return ret_count;
}
