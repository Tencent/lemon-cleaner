/*
 *  Cmcfsdata.c
 *  McDaemon
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include "Cmcfsmonitor.h"
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <stdlib.h>
#include <mach/mach_time.h>

#define MAX_CACHE_FSEVENT       (1024 * 20)
// monitor event
kfs_result_Data *g_fsMonData = NULL;
int     g_start = 0;
int     g_end = 0;
int     g_count = 0;
// mutex
pthread_mutex_t g_mutex;
int g_mutexinit = 0;

// init mutex
void CmcFsmonInit()
{
    if (g_fsMonData == NULL)
        g_fsMonData = malloc(MAX_CACHE_FSEVENT * sizeof(kfs_result_Data));
    
    if (g_mutexinit == 0)
    {
        pthread_mutex_init(&g_mutex, NULL);
        g_mutexinit = 1;
    }
}

// check time and delete old events
//void CmcFsmonTimeCheck()
//{
//    static mach_timebase_info_data_t sTimebaseInfo = {0};
//    if (sTimebaseInfo.denom == 0)
//        mach_timebase_info(&sTimebaseInfo);
//    
//    // get current time
//    uint64_t nanoSecond = mach_absolute_time() * sTimebaseInfo.numer / sTimebaseInfo.denom;
//    float milliSecond = nanoSecond / (1000 * 1000);
//}

// add monitor data
void CmcAddFsmonData(kfs_result_Data *data)
{    
    // lock
    pthread_mutex_lock(&g_mutex);
    
    //CmcFsmonTimeCheck();
    
    if (g_start == g_end)
    {
        if (g_count != 0)
        {
            //printf("[warn] fsmonitor event is full pos:%d[%d]\n", g_start, g_count);
            // maybe full, move start pointer
            g_start = (g_start + 1) % MAX_CACHE_FSEVENT;
            g_count--;
        }
    }
    
    // record
    memcpy(&g_fsMonData[g_end], data, sizeof(kfs_result_Data));
    g_end = (g_end + 1) % MAX_CACHE_FSEVENT;
    g_count++;
    
    // unlock
    pthread_mutex_unlock(&g_mutex);
}

// read monitor data
int CmcGetFsmonData(unsigned int pos, kfs_result_Data outdata[], int count)
{
    if (g_count == 0 || outdata == NULL)
        return 0;
    
    // lock
    pthread_mutex_lock(&g_mutex);
    
    int start = -1;
    if (pos != 0)
    {
        for (int i = 0; i < g_count; i++)
        {
            if (pos < g_fsMonData[(g_start + i) % MAX_CACHE_FSEVENT].index)
            {
                start = i;
                break;
            }
        }
        if (start == -1)
        {
            // no new items
            
            // unlock
            pthread_mutex_unlock(&g_mutex);
            return 0;
        }
    }
    else
    {
        // pos == 0 -> get the last 50 records
        if (g_count < 50)
            start = 0;
        else
            start = g_count - 50;
    }
    
    if (g_count - start < count)
        count = g_count - start;
    
    for (int i = 0; i < count; i++)
    {
        memcpy(&outdata[i], 
               &g_fsMonData[(g_start + start + i) % MAX_CACHE_FSEVENT], 
               sizeof(kfs_result_Data));
    }
    
    // unlock
    pthread_mutex_unlock(&g_mutex);
    
    //printf("start:%d end:%d count:%d return:%d\n", g_start, g_end, g_count, count);
    return count;
}
