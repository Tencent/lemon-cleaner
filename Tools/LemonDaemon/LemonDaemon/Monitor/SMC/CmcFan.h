/*
 *  CmcFan.h
 *  TestFunction
 *
 *  Created by developer on 11-1-18.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get fan count
int CmcGetFanCount();

// set fan min speed
int CmcSetMinFanSpeed(int nIndex, float fMinSpeed);

// get min/max fan speed
float CmcGetMinFanSpeed(int nIndex);
float CmcGetMaxFanSpeed(int nIndex);

// get fan ids
int CmcGetFanIds(int nCount, char fanIds[][20]);

// get fan speeds
int CmcGetFanSpeeds(int nCount, double *fSpeeds);
