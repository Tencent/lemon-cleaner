//
//  QMSoftwareHelp.h
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMSoftwareHelp : NSObject

+ (NSString *)dateDistance:(NSDate *)date;
+ (NSString *)dateStringWithInterval:(NSTimeInterval)interval;

+ (NSString *)downloadTime:(uint64_t)downSize speed:(uint64_t)downSpeed;

+ (NSString *)getVersionOfBundlePath:(NSString *)bundlePath;

@end
