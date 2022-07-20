//
//  QMNetworkClock.m
//  TestGetTime
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "QMNetworkClock.h"
#import "AsyncUdpSocket.h"
#include <sys/time.h>
#import <CFNetwork/CFNetwork.h>
#import <arpa/inet.h>

struct ntpTimestamp {
	uint64_t    fullSeconds;
	uint64_t    partSeconds;
};

#define uSec2Frac(x)    ( 4294*(x) + ( (1981*(x))>>11 ) )
#define Frac2uSec(x)    ( ((x) >> 12) - 759 * ( ( ((x) >> 10) + 32768 ) >> 16 ) )
#define JAN_1970        0x83aa7e80      /* 1970 - 1900 in seconds 2,208,988,800 | First day UNIX  */
// 1 Jan 1972 : 2,272,060,800 | First day UTC

#define kTimeOut        1

@interface QMNetworkClock()
{
    AsyncUdpSocket * socket;
    struct ntpTimestamp ntpClientSendTime, ntpServerSendTime;
    
    BOOL end;
}
@end

@implementation QMNetworkClock

static struct ntpTimestamp NTP_1970 = {JAN_1970, 0};

static double ntpDiffSeconds(struct ntpTimestamp * start, struct ntpTimestamp * stop) {
	uint64_t        a;
	uint64_t        b;
	a = stop->fullSeconds - start->fullSeconds;
	if (stop->partSeconds >= start->partSeconds) {
		b = stop->partSeconds - start->partSeconds;
	} else {
		b = start->partSeconds - stop->partSeconds;
		b = ~b;
		a -= 1;
	}
    
	return a + b / 4294967296.0;
}

- (NSDate *)dateFromNetworkTime:(struct ntpTimestamp *) networkTime {
    return [NSDate dateWithTimeIntervalSince1970:ntpDiffSeconds(&NTP_1970, networkTime)];
}

- (NSData *) createPacket {
	uint32_t        wireData[12];
    
	memset(wireData, 0, sizeof wireData);
	wireData[0] = htonl((0 << 30) |                                         // no Leap Indicator
                        (3 << 27) |                                         // NTP v3
                        (3 << 24) |                                         // mode = client sending
                        (0 << 16) |                                         // stratum (n/a)
                        (4 << 8) |                                         // polling rate (16 secs)
                        (-6 & 0xff));                                       // precision (~15 mSecs)
	wireData[1] = htonl(1<<16);
	wireData[2] = htonl(1<<16);
    struct timeval  now;
	gettimeofday(&now, NULL);
    
	ntpClientSendTime.fullSeconds = now.tv_sec + JAN_1970;
	ntpClientSendTime.partSeconds = uSec2Frac(now.tv_usec);
    
    wireData[10] = htonl(now.tv_sec + JAN_1970);                            // Transmit Timestamp
	wireData[11] = htonl(uSec2Frac(now.tv_usec));
    
    
    return [NSData dataWithBytes:wireData length:48];
}

- (id)init
{
    if (self = [super init])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self getNetWorkTime];
        });
    }
    return self;
}


+ (QMNetworkClock *)sharedInstance
{
    static QMNetworkClock * networkClock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkClock = [[QMNetworkClock alloc] init];
        
    });
    return networkClock;
}

- (NSInteger)dayBetweenDate:(NSDate *)fromDateTime toDate:(NSDate *)toDateTime
{
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
        return 0;
    return [difference day];
}

- (void)loopRefreshTimeDate
{
    if (_loopTimer)
    {
        [_loopTimer invalidate];
        _loopTimer = nil;
    }
    // 计算当前一天后时间
    NSCalendar * calendar = [NSCalendar currentCalendar];
    [calendar setLocale:[NSLocale currentLocale]];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    NSDate * nextDate = [calendar dateByAddingComponents:components toDate:_netTimeDate options:0];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&nextDate interval:NULL forDate:nextDate];
    _nextDate = nextDate;
    
    
    NSDateComponents * diffSecond = [calendar components:NSSecondCalendarUnit
                                                fromDate:_netTimeDate
                                                  toDate:_nextDate
                                                 options:0];
    
    _loopTimer = [NSTimer scheduledTimerWithTimeInterval:diffSecond.second
                                                  target:self
                                                selector:@selector(refreshTimeDate)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)refreshTimeDate
{
    _netTimeDate = _nextDate;
    // 继续更新
    [self loopRefreshTimeDate];
}

- (void)getNetWorkTime
{
    // 请求网络时间
    end = NO;
    _netTimeDate = nil;
    socket = [[AsyncUdpSocket alloc] initIPv4];
    [socket setDelegate:self];
    [socket receiveWithTimeout:kTimeOut tag:0];
    
    [socket sendData:[self createPacket] toHost:@"time.asia.apple.com" port:123L withTimeout:kTimeOut tag:0];
    
    
    NSRunLoop *curLoop = [NSRunLoop currentRunLoop];
    while (YES)
    {
        if (end || _netTimeDate)
            break;
        [curLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
        [NSThread sleepForTimeInterval:0.1];
    }
    // 结果
    if (_netTimeDate)
    {
        // 更新本地时间
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loopRefreshTimeDate];
        });
    }
}

- (NSDate *)networkTime
{
    if (!end)
    {
        NSRunLoop *curLoop = [NSRunLoop currentRunLoop];
        while (YES)
        {
            if (end || _netTimeDate)
                break;
            [curLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
            [NSThread sleepForTimeInterval:0.1];
        }
    }
    if (_netTimeDate)
        return _netTimeDate;
    return [NSDate date];
}

#pragma mark-
#pragma mark delegate

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
}
- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    
}
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sender didReceiveData:(NSData *)data
            withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port {
    
    // 获取成功
    uint32_t    hostData[12];
    [data getBytes:hostData length:48];
    
    ntpServerSendTime.fullSeconds = ntohl(hostData[10]);
    ntpServerSendTime.partSeconds = ntohl(hostData[11]);
    _netTimeDate = [self dateFromNetworkTime:&ntpServerSendTime];
    
    end = YES;
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    end = YES;
}

/**
 * Called when the socket is closed.
 * A socket is only closed if you explicitly call one of the close methods.
 **/
- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
    end = YES;
}

@end
