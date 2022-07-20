//
//  NSFileManager+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager(FileSize)

- (uint64_t)fileSizeAtPath:(NSString *)filePath;
- (uint64_t)diskSizeAtPath:(NSString *)filePath;

@end
