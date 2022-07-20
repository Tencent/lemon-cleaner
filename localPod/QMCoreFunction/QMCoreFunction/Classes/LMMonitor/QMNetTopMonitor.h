//
//  QMNetTopMonitor.h
//  NetMonDemo
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMNetTopHelp.h"

@interface QMNetTopMonitor : NSObject

+ (void)startMonitor;
+ (void)stopMonitor;

+ (NSDictionary *)flowSpeed;

@end
