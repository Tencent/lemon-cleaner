//
//  NSDate+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSDate+Extension.h"
#import "QMNetworkClock.h"

@implementation NSDate(Extension)

+ (NSDate *)networkTime
{
    return [[QMNetworkClock sharedInstance] networkTime];
}
@end
