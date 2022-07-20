//
//  QMDuplicateHelp.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

// In bytes
#define kDefaultChunkSize   4096
#define kAutoreleasCount    5000
#define kSearchControlSize  1024*1024
#define kBundlePrefix       @"F:"


CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, size_t chunkSize, int max_time);

NSString *FileMD5HashWithPath(NSString *filePath, int dataSize);


CFStringRef FileMD5HashWithData(NSData *fileData, int dataSize);
