//
//  QMDuplicateFiles.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDuplicateFiles.h"
#import "QMDuplicateFileScanManager.h"
#import "McDuplicateFilesDelegate.h"


@interface QMDuplicateFiles : NSObject<QMFileScanManagerDelegate>


- (void)start:(id <McDuplicateFilesDelegate>)scanDelegate
         path:(NSArray *)path
 excludeArray:(NSArray *)array;

- (void)stopScan;

@end
