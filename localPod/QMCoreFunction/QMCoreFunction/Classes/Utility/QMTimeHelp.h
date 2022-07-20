//
//  QMTimeHelp.h
//  QMBigOldFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMTimeHelp : NSObject

+ (NSInteger)daysBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime;

+ (NSInteger)weeksBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime;

+ (NSInteger)mothsBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime;

+ (NSInteger)yearsBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime;

+ (NSDateComponents *)dateBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime;

@end
