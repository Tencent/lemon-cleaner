//
//  QMProcessWatcher.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMProcessWatcher : NSObject

+ (void)waitProcessExit:(pid_t)pid;
+ (void)waitProcessesExit:(NSArray *)processes;

- (void)watchProcess:(pid_t)pid;
- (void)watchProcesses:(NSArray *)process;
- (void)waitUntilExit;

@end
