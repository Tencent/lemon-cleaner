//
//  QMNetworkSpeedFormatter.m
//  LemonMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMNetworkSpeedFormatter.h"
#import "NSString+Extension.h"

@implementation QMNetworkSpeedFormatter
- (NSString *)stringForObjectValue:(NSNumber *)obj
{
    NSString *ret = [NSString stringFromNetSpeed:[obj longLongValue]/1000.0];
    return ret;
}
@end
