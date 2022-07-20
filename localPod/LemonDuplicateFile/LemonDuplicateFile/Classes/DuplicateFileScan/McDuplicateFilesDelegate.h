//
//  McDuplicateFilesDelegate.h
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol McDuplicateFilesDelegate <NSObject>

- (BOOL)progressRate:(float)value progressStr:(NSString *)path;

- (void)duplicateFileSearchEnd;

- (void)addDuplicateFileRecord:(NSArray *)pathArray totalSize:(uint64_t)size;

- (BOOL)cancelScan;

@end
