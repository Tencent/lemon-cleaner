/*
 *  CmcSystem.h
 *  TestFunction
 *
 *  Created by developer on 11-1-12.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get passed time in nanoseconds
uint64_t CmcGetAbsoluteNanosec();

// get system boot time via sysctl
// return seconds, -1 indicates error
long CmcGetBootTime();

// get machine serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int CmcGetMachineSerial(char *serial_buf, int buf_size);

// get machine model, UTF8 encoding
// model_buf        output buffer
// buf_size         size in bytes
int CmcGetMachineModel(char *model_buf, int buf_size);

// get os version
int CmcGetOSVersion(int *pMajor, int *pMinor, int *pBugfix);

// get default os language
int CmcGetDefalutLanguage(char *lang_buf, int buf_size);

// get current application version
// 2.1.34 -> 2.1.34.0
int CmcGetCurrentAppVersion(char *version, int version_size, char *buildver, int buildver_size);

// convert version
uint64_t CmcConvertAppVersion(char *version);

// if internet is available
bool CmcInternetAvailable();

// get supply ID
int CmcGetSupplyID(unsigned int *sup_id);

// register bundle callback(return value must be retain)
int CmcRegisterBundleCallBack( void*(*bundleCopyCallback)(void) );

// app store version
void setLMReportAppStoreVersion(bool isAppstore);
bool isLMReportAppStoreVersion(void);
