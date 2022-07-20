/*
 *  CmcProcessor.h
 *  TestFunction
 *
 *  Created by developer on 11-1-13.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get cpu load average
// return -1 indicates error
int CmcGetLoadavg(double average[3]);

// get process count
// return -1 indicates fail
int CmcGetProcessCount();

// get thread count
// return -1 indicates fail
int CmcGetThreadCount();

// get cpu count
// return -1 indicates fail
int CmcGetCpuCount();

// get cpu ticks, caller should alloc enough space for cpu_ticks
// index from 0 - 3 -> "user", "system", "idle", "nice"
// CPU_STATE_MAX - 4
// return -1 indicates fail
int CmcGetCpuTicks(unsigned int *cpu_ticks);

// get cpu brand name
int CmcGetCpuBrandString(char *name_str, size_t len);
