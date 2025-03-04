//
//  NSDate+LMCalendar.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "NSDate+LMCalendar.h"

@implementation NSDate (LMCalendar)

- (BOOL)lm_isSameDayAsDate:(NSDate *)date {
    if (!date) return NO;

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components1 = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self];
    NSDateComponents *components2 = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];

    return (components1.year == components2.year) &&
           (components1.month == components2.month) &&
           (components1.day == components2.day);
}

@end
