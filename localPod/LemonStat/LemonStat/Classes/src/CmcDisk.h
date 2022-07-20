/*
 *  CmcDisk.h
 *  TestFunction
 *
 *  Created by developer on 11-1-25.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get file system stat where 'path' is mounted
// return in bytes
int CmcGetFsStat(const char *path, uint64_t *freeBytes, uint64_t *totalBytes);

int CmcGetFsStatByFM(NSString *path, uint64_t *freeBytes, uint64_t *totalBytes);

// get disk description where 'path' is mounted
// path - "/" to get the internal hard disk
// also may return icon path for the disk
int CmcGetDiskDescr(const char *path,
                    char *device_name,
                    char *volum_name,
                    char *icns_path,
                    char *kind_name,
                    int name_size,
                    Boolean *ejectable,
                    Boolean *internal,
                    Boolean *network,
                    Boolean *writeable);

// get disk read and write bytes information
// this function return total bytes information include all storage device
int CmcGetDiskReadWriteBytes(uint64_t *readBytes, uint64_t *writeBytes);
