/*
 *  CmcProcess.h
 *  Untitled_4
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#import "McPipeCmdStruct.h"

// if count = 0 -> get all process list
int CmcGetProcessInfo(ORDER_TYPE orderType, int count, BOOL isReverse, ProcessInfo_t **pproc);

// fail: -1 64bit: 1 32bit: 0
int CmcCheckProcess64bit(pid_t pid);

// fail: -1 64bit: 1 32bit: 0
int IsHardware64bitCapable();
