/*
 *  CmcTemperature.h
 *  TestFunction
 *
 *  Created by developer on 11-1-19.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get cpu temperature
int CmcGetCpuTemperature(double *value);

// get battery temperature
int CmcGetBatteryTemperature(double *value);

// get northbridge temperature
int CmcGetNBridgeTemperature(double *value);
