//
//  DeamonTimeHelper.h
//  UserDataReport
//

//  Copyright © 2017年 com.yirgalb.jing. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ONE_DAY_TIME_INTERVAL 24 * 3600

@interface DeamonTimeHelper : NSObject

//本次启动时间 是否与今天启动时间是同一天
+(BOOL)isTodayStartTime:(long) todayStartTime isOneDayWithStartTime:(long) nowStartTime;

//比对是否是这个月(传递这个月任意一天的时间  如2017/09/09)
+(BOOL)isOneMonth:(NSTimeInterval)timeInterval month:(NSString *)month;

//通过两个interval来对比是不是一个月
+(BOOL)isOneMonthBase:(NSTimeInterval) baseInterval compare:(NSTimeInterval) compareInterval;

//获取当前是周几
+(NSInteger)getDayWeek;

//通过时间戳来获取今天是周几
+(NSInteger)getDayWeekByInterval:(NSTimeInterval) timeInterval;

//获取当天最晚时间的的时间戳
+(NSTimeInterval)getTodayLateTimeInterval:(NSString *)lateTimeString;

//获取今天日期的字符串 不包含时间
+(NSString *)getDateStr;

+(NSString *)getDataStrByInterval:(NSTimeInterval) timeInterval;

//获取没有年只有月日的日期字符串
+(NSString *)getDataStrNoYearByInterval:(NSTimeInterval) timeInterval;

//获取今天晚上十二点的时间戳 24：00
+(NSTimeInterval)getTwelveTimerIntervalWithDateStr:(NSString *)dateStr;

//获取今天0点最早的时间戳
+(NSTimeInterval)get0diantimeInterval:(NSString *)dateStr;

//获取一个月最早时间
+(NSTimeInterval)getTheEarlyTimeIntervalThisMonth:(NSTimeInterval) timeInterval;

//获取下个月最早的时间
+(NSTimeInterval)getTheNextEarlyTimeIntervalThisMonth:(NSTimeInterval) timeInterval;

//将配置的总时间转化成字符串
+(NSString *)changeIntegetToHMSString:(NSInteger) hmsInteger;

//获取上周日晚上十二点的时间戳 24：00
+(NSTimeInterval)getLastWeekTwelveTimerInterval;

//获取上周一0点最早的时间戳
+(NSTimeInterval)getLastWeek0diantimeInterval;

//通过时间戳获取当周的周一
+(NSTimeInterval)getMondayIntervalByTimeInterval:(NSTimeInterval) timeInterval;

//通过时间戳获取当周的周日
+(NSTimeInterval)getSundayIntervalByTimeInterval:(NSTimeInterval) timeInterval;

//获取本周是否在同一个月 传入当周周一的任意时刻时间戳
+(BOOL)getThisWeekDayIsInOneMonthByTimeInterval:(NSTimeInterval) timeInterval;

//判断传入时间戳所在周周日是不是和今天是同一个月
+(BOOL)getWeekSundayInNowMonthByTimeInterval:(NSTimeInterval) timeInterval;

//获取当天晚上八点的时间戳
+(NSTimeInterval)getToday8ClockTimeInterval;

//获取明天的时间戳 当前时间加上一天的时间戳
+(NSTimeInterval)getTomorowTimeInterval;

@end
