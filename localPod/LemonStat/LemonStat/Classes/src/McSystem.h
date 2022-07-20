/*
 *  McSystem.h
 *  TestFunction
 *
 *  Created by developer on 11-1-12.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get passed time in nanoseconds
uint64_t McGetAbsoluteNanosec();

// get system boot time via sysctl
// return seconds, -1 indicates error
long McGetBootTime();

// get machine serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int McGetMachineSerial(char *serial_buf, int buf_size);

// get machine model, UTF8 encoding
// model_buf        output buffer
// buf_size         size in bytes
int McGetMachineModel(char *model_buf, int buf_size);
