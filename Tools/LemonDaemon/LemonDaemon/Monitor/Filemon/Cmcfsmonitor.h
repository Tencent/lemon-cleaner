/*
 *  Cmcfsmonitor.h
 *  SCEvents
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include "McPipeCmdStruct.h"

// init mutex
void CmcFsmonInit();

// add monitor data
void CmcAddFsmonData(kfs_result_Data *data);

// read monitor data
int CmcGetFsmonData(unsigned int pos, kfs_result_Data outdata[], int count);
