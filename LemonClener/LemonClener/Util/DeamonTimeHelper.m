//
//  DeamonTimeHelper.m
//  UserDataReport
//

//  Copyright © 2017年 com.yirgalb.jing. All rights reserved.
//

#import "DeamonTimeHelper.h"

static NSString *timeFile = @"timeFile.txt";
static NSString *todayStartTimeFile = @"todayStartTimeFile.txt";

@implementation DeamonTimeHelper

//本次启动时间 是否与今天启动时间是同一天
+(BOOL)isTodayStartTime:(long) todayStartTime isOneDayWithStartTime:(long) nowStartTime{
    NSDate *todayStartDate = [NSDate dateWithTimeIntervalSince1970:todayStartTime];
    NSDate *nowStatrtDate = [NSDate dateWithTimeIntervalSince1970:nowStartTime];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *todayComponets = [calendar components:unitFlags fromDate:todayStartDate];
    NSDateComponents *nowComponets = [calendar components:unitFlags fromDate:nowStatrtDate];
    return [todayComponets year] == [nowComponets year] &&
           [todayComponets month] == [nowComponets month] &&
           [todayComponets day] == [nowComponets day];
}

//比对是否是这个月
+(BOOL)isOneMonth:(NSTimeInterval)timeInterval month:(NSString *)month{
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@%@", month, @"12:00:00"];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    
    return [self isOneMonthBase:timeInterval compare:targetInterval];
}

//通过两个interval来对比是不是一个月
+(BOOL)isOneMonthBase:(NSTimeInterval) baseInterval compare:(NSTimeInterval) compareInterval{
    NSDate *todayStartDate = [NSDate dateWithTimeIntervalSince1970:baseInterval];
    NSDate *nowStatrtDate = [NSDate dateWithTimeIntervalSince1970:compareInterval];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *todayComponets = [calendar components:unitFlags fromDate:todayStartDate];
    NSDateComponents *nowComponets = [calendar components:unitFlags fromDate:nowStatrtDate];
    return [todayComponets year] == [nowComponets year] &&
    [todayComponets month] == [nowComponets month];
}

+(NSInteger)getDayWeek{
    NSTimeInterval nowStartTime = [[NSDate date] timeIntervalSince1970];
    NSInteger weekNum = [self getDayWeekByInterval:nowStartTime];
    return weekNum;
}

//通过时间戳来获取今天是周几
+(NSInteger)getDayWeekByInterval:(NSTimeInterval) timeInterval{
    NSDate *nowStatrtDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitWeekday;
    NSDateComponents *nowComponets = [calendar components:unitFlags fromDate:nowStatrtDate];
    NSInteger dayStr;
    NSInteger week = [nowComponets weekday];
    switch (week) {
        case 1:{
            dayStr = 7;
        }
            break;
            
        case 2:{
            dayStr = 1;
        }
            break;
            
        case 3:{
            dayStr = 2;
        }
            break;
            
        case 4:{
            dayStr = 3;
        }
            break;
            
        case 5:{
            dayStr = 4;
        }
            break;
            
        case 6:{
            dayStr = 5;
        }
            break;
            
        case 7:{
            dayStr = 6;
        }
            break;
            
        default:
            dayStr = 0;
            break;
    }
    
    return dayStr;
}

+(NSTimeInterval)getTodayLateTimeInterval:(NSString *)lateTimeString{
    NSTimeInterval sec = [[NSDate date] timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    NSDateFormatter *ymdDf = [[NSDateFormatter alloc] init];
    [ymdDf setDateFormat:@"yyyy/MM/dd "];
    NSString *nowTimeString = [ymdDf stringFromDate:currentDate];
    //NSLog(@"-------current date is = %@--------", nowTimeString);
    
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@%@", nowTimeString, lateTimeString];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    //NSLog(@"-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//获取今天日期的字符串 不包含时间
+(NSString *)getDateStr{
    NSTimeInterval sec = [[NSDate date] timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    NSDateFormatter *ymdDf = [[NSDateFormatter alloc] init];
    [ymdDf setDateFormat:@"yyyy/MM/dd"];
    NSString *nowTimeString = [ymdDf stringFromDate:currentDate];
    // NSLog(@"-------current date is = %@--------", nowTimeString);
    
    return nowTimeString;
}

+(NSString *)getDataStrByInterval:(NSTimeInterval) timeInterval{
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
    
    NSDateFormatter *ymdDf = [[NSDateFormatter alloc] init];
    [ymdDf setDateFormat:@"yyyy/MM/dd"];
    NSString *nowTimeString = [ymdDf stringFromDate:currentDate];
    // NSLog(@"-------current date is = %@--------", nowTimeString);
    
    return nowTimeString;
}

//获取没有年只有月日的日期字符串
+(NSString *)getDataStrNoYearByInterval:(NSTimeInterval) timeInterval{
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
    
    NSDateFormatter *ymdDf = [[NSDateFormatter alloc] init];
    [ymdDf setDateFormat:@"MM/dd"];
    NSString *nowTimeString = [ymdDf stringFromDate:currentDate];
    // NSLog(@"-------current date is = %@--------", nowTimeString);
    
    return nowTimeString;
}

//获取今天晚上十二点的时间戳 24：00
+(NSTimeInterval)getTwelveTimerIntervalWithDateStr:(NSString *)dateStr{
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    NSString *identifier = [[NSLocale currentLocale] localeIdentifier];
    if (identifier == nil) {
        identifier = @"zh_CN";
    }
    [allDf setLocale:[[NSLocale alloc] initWithLocaleIdentifier:identifier]];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@ 23:59:59", dateStr];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    //NSLog(@"-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//获取今天0点最早的时间戳
+(NSTimeInterval)get0diantimeInterval:(NSString *)dateStr{
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    NSString *identifier = [[NSLocale currentLocale] localeIdentifier];
    if (identifier == nil) {
        identifier = @"zh_CN";
    }
    [allDf setLocale:[[NSLocale alloc] initWithLocaleIdentifier:identifier]];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@ 00:00:00", dateStr];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    //NSLog(@"-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//获取一个月最早时间
+(NSTimeInterval)getTheEarlyTimeIntervalThisMonth:(NSTimeInterval) timeInterval{
    NSDate *nowStatrtDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *nowComponets = [calendar components:unitFlags fromDate:nowStatrtDate];
    NSString *targetString;
    if ([nowComponets month] < 10) {
        targetString = [NSString stringWithFormat:@"%ld/0%ld/01 00:00:00", (long)[nowComponets year], (long)[nowComponets month]];
    }else{
        targetString = [NSString stringWithFormat:@"%ld/%ld/01 00:00:00", (long)[nowComponets year], (long)[nowComponets month]];
    }
    
    NSLog(@"这个月最早的字符串是  －－－－－－ %@", targetString);
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSDate *targetDate = [allDf dateFromString:targetString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    return targetInterval;
}

//获取下个月最早的时间
+(NSTimeInterval)getTheNextEarlyTimeIntervalThisMonth:(NSTimeInterval) timeInterval{
    NSDate *nowStatrtDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *nowComponets = [calendar components:unitFlags fromDate:nowStatrtDate];
    NSString *targetString;
    if ([nowComponets month] < 12) {
        if ([nowComponets month] < 10) {
            targetString = [NSString stringWithFormat:@"%ld/0%ld/01 00:00:00", (long)[nowComponets year], (long)[nowComponets month] + 1];
        }else{
            targetString = [NSString stringWithFormat:@"%ld/%ld/01 00:00:00", (long)[nowComponets year], (long)[nowComponets month] + 1];
        }
    }else{
        targetString = [NSString stringWithFormat:@"%ld/01/01 00:00:00", (long)[nowComponets year] + 1];
    }
    
    NSLog(@"这个月最早的字符串是  －－－－－－ %@", targetString);
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSDate *targetDate = [allDf dateFromString:targetString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    return targetInterval;
}

//version 2.1  add----------
//将配置的总时间转化成字符串
+(NSString *)changeIntegetToHMSString:(NSInteger) hmsInteger{
    NSInteger hour = hmsInteger / 3600;
    NSInteger min = (hmsInteger - hour * 3600) / 60;
    
    NSString *hourString = nil;
    if (hour == 0) {
        hourString = [NSString stringWithFormat:@"00"];
    }else if (hour < 10) {
        hourString = [NSString stringWithFormat:@"0%ld", hour];
    }else{
        hourString = [NSString stringWithFormat:@"%ld", hour];
    }
    NSString *minString = nil;
    if (min == 0) {
        minString = [NSString stringWithFormat:@"00"];
    }else if(min < 10){
        minString = [NSString stringWithFormat:@"0%ld", min];
    }else{
        minString = [NSString stringWithFormat:@"%ld", min];
    }
    
    NSString *hmsString = [NSString stringWithFormat:@"%@:%@:00", hourString, minString];
    
    return hmsString;
}

//获取上周日晚上十二点的时间戳 24：00
+(NSTimeInterval)getLastWeekTwelveTimerInterval{
    NSInteger week = [self getDayWeek];
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval taregetTimeInterval = nowTimeInterval - week * 24 * 3600;
    NSString *dateStr = [self getDataStrByInterval:taregetTimeInterval];
    
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@ 23:59:59", dateStr];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    NSLog(@"getLastWeekTwelveTimerIntervalWithDateStr-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//获取上周一0点最早的时间戳
+(NSTimeInterval)getLastWeek0diantimeInterval{
    NSInteger week = [self getDayWeek];
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval taregetTimeInterval = nowTimeInterval - ((week - 1) + 7) * 24 * 3600;
    NSString *dateStr = [self getDataStrByInterval:taregetTimeInterval];
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@ 00:00:00", dateStr];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    NSLog(@"getLastWeek0diantimeInterval-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//通过时间戳获取当周的周一
+(NSTimeInterval)getMondayIntervalByTimeInterval:(NSTimeInterval) timeInterval{
    NSInteger weekNums = [self getDayWeekByInterval:timeInterval];
    NSTimeInterval mondayTimeInterval = timeInterval - ((weekNums - 1) * 24 * 3600);
    return mondayTimeInterval;
}

//通过时间戳获取当周的周日
+(NSTimeInterval)getSundayIntervalByTimeInterval:(NSTimeInterval) timeInterval{
    NSInteger weekNums = [self getDayWeekByInterval:timeInterval];
    NSTimeInterval mondayTimeInterval = timeInterval + ((7 - weekNums) * 24 * 3600);
    return mondayTimeInterval;
}

//获取本周是否在同一个月 传入当周周一的任意时刻时间戳
+(BOOL)getThisWeekDayIsInOneMonthByTimeInterval:(NSTimeInterval) timeInterval{
    NSTimeInterval sundayTimeInterval = [self getSundayIntervalByTimeInterval:timeInterval];
    BOOL isOneMonth = [self isOneMonthBase:sundayTimeInterval compare:timeInterval];
    
    return isOneMonth;
}

//判断传入时间戳所在周周日是不是在今天同一个月
+(BOOL)getWeekSundayInNowMonthByTimeInterval:(NSTimeInterval) timeInterval{
    NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval sundayTimeInterval = [self getSundayIntervalByTimeInterval:timeInterval];
    BOOL isOneMonth = [self isOneMonthBase:nowInterval compare:sundayTimeInterval];
    
    return isOneMonth;
}

//获取当天晚上八点的时间戳
+(NSTimeInterval)getToday8ClockTimeInterval{
    NSString *dateStr = [DeamonTimeHelper getDateStr];
    NSDateFormatter *allDf = [[NSDateFormatter alloc] init];
    [allDf setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *targetTimeString = [NSString stringWithFormat:@"%@ 20:00:00", dateStr];
    NSDate *targetDate = [allDf dateFromString:targetTimeString];
    NSTimeInterval targetInterval = [targetDate timeIntervalSince1970];
    //NSLog(@"-----tagetInterval is = %f------", targetInterval);
    
    return targetInterval;
}

//获取明天的时间戳 当前时间加上一天的时间戳
+(NSTimeInterval)getTomorowTimeInterval{
    NSTimeInterval todayTimeInterval = [[NSDate date] timeIntervalSince1970];
    return todayTimeInterval + 24 * 60 * 60;
}

@end
