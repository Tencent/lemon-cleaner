//
//  QMNetworkClock.h
//  TestGetTime
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMNetworkClock : NSObject
{
    NSDate * _netTimeDate;
    
    NSDate * _nextDate;
    NSTimer * _loopTimer;
}

+ (QMNetworkClock *)sharedInstance;
- (NSDate *) networkTime;

@end
