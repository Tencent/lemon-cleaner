/*
 *  CmcMemory.h
 *  TestFunction
 *
 *  Created by developer on 11-3-7.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get physical memory information
// index from 0 - 3: free / inactive / active / wired
// 已废弃，后续观察
int CmcGetPhysMemoryInfo(uint64_t mem_info[5], uint64_t mem_inout[2]);

// index from 0 - 5: free / inactive / active / wired / 系统物理内存 / 可使用的
// index from 0 - 1: pagein / pageout
// CmcGetPhysMemoryInfo升级版，使用 vm_statistics64_data_t
int CmcGetPhysMemoryInfo2(uint64_t mem_info[6], uint64_t mem_inout[2]);

// get memory type and speed
// type - <"DDR3", "DDR3"> speed - <"1067 MHz", "1067 MHz">
int CmcGetMemoryType(char *mem_type, size_t type_size,
                     char *mem_speed, size_t speed_size);
