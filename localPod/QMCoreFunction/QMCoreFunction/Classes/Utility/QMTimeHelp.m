//
//  QMTimeHelp.m
//  QMBigOldFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMTimeHelp.h"

@implementation QMTimeHelp

+ (NSInteger)daysBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
    if (!fromDateTime || !toDateTime)
        return 0;
    NSDate *fromDate = fromDateTime;
    NSDate *toDate = toDateTime;
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    // rand hour
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents * difference = [calendar components:NSDayCalendarUnit
                                                fromDate:fromDate
                                                  toDate:toDate
                                                 options:0];
    if (difference == nil)
        return ([toDate timeIntervalSince1970] - [fromDate timeIntervalSince1970]) / (60.0 * 60 * 24);
    return [difference day];
}

+ (NSInteger)weeksBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
    if (!fromDateTime || !toDateTime)
        return 0;
    NSDate *fromDate = fromDateTime;
    NSDate *toDate = toDateTime;
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    // rand hour
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents * difference = [calendar components:NSWeekCalendarUnit
                                                fromDate:fromDate
                                                  toDate:toDate
                                                 options:0];
    if (difference == nil)
        return ([toDate timeIntervalSince1970] - [fromDate timeIntervalSince1970]) / (60.0 * 60 * 24 * 7);
    return [difference week];
}

+ (NSInteger)mothsBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
    if (!fromDateTime || !toDateTime)
        return 0;
    NSDate *fromDate = fromDateTime;
    NSDate *toDate = toDateTime;
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    // rand hour
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents * difference = [calendar components:NSMonthCalendarUnit
                                                fromDate:fromDate
                                                  toDate:toDate
                                                 options:0];
    if (difference == nil)
        return ([toDate timeIntervalSince1970] - [fromDate timeIntervalSince1970]) / (60.0 * 60 * 24 * 30);
    return [difference month];
}

+ (NSInteger)yearsBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
    if (!fromDateTime || !toDateTime)
        return 0;
    NSDate *fromDate = fromDateTime;
    NSDate *toDate = toDateTime;
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    // rand hour
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents * difference = [calendar components:NSYearCalendarUnit
                                                fromDate:fromDate
                                                  toDate:toDate
                                                 options:0];
    if (difference == nil)
        return ([toDate timeIntervalSince1970] - [fromDate timeIntervalSince1970]) / (60.0 * 60 * 24 * 365);
    return [difference year];
}


+ (NSDateComponents *)dateBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
    if (!fromDateTime || !toDateTime)
        return nil;
    NSDate *fromDate = fromDateTime;
    NSDate *toDate = toDateTime;
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    // rand hour
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents * difference = [calendar components:NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit
                                                fromDate:fromDate
                                                  toDate:toDate
                                                 options:0];
    if (difference == nil)
    {
        NSInteger offset = ([toDate timeIntervalSince1970] - [fromDate timeIntervalSince1970]) / (60.0 * 60 * 24);;
        difference = [[NSDateComponents alloc] init];
        difference.year = offset / 365;
        if (difference.year == 0)
            difference.month = offset / 30;
        if (difference.month == 0)
            difference.week = offset / 7;
    }
    return difference;
}

@end
