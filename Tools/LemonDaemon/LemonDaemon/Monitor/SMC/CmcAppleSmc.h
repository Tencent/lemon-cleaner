/*
 *  CmcAppleSmc.h
 *  TestFunction
 *
 *  Created by developer on 11-1-17.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// open connection
int CmcOpenSmc();

// close SMC connection
void CmcCloseSmc();

// write SMC key value
int CmcWriteSmcKey(uint32_t key, const uint8_t *input_buf, uint8_t buf_size);

// read SMC key value
// key          4 bytes key registed by apple smc
int CmcReadSmcKey(uint32_t key, uint8_t *out_buf, uint8_t *buf_size, boolean_t check_size);

// check SMC key value
// key          4 bytes key registed by apple smc
int CmcCheckSmcKey(uint32_t key, uint8_t *buf_size, uint32_t* buf_type);

// swap byte
void CmcSwapBytes(uint8_t *data, uint32_t size);

// convert ui16
uint16_t CmcConvertUi16(uint8_t *data);

// convert ui32
uint32_t CmcConvertUi32(uint8_t *data);

// convert float to fpe2
void CmcConvertFloatToFpe2(float value, uint8_t *out_data, uint32_t size);

// convert fpe2 to float
float CmcConvertFpe2ToFloat(uint8_t *data, uint32_t size, int e);

// convert sp78 to double
double CmcConvertSp78ToDouble(uint8_t *data);

// print all keys
void CmcPrintAllSmcKeys(void);

io_connect_t GetSmcConnect(void);
