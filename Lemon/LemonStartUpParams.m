//
//  LemonStartUpParams.m
//  Lemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LemonStartUpParams.h"

NSString const *kMonitorRuning = @"kMonitorRuning";
@implementation LemonStartUpParams
+ (LemonStartUpParams*)sharedInstance
{
    static LemonStartUpParams *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LemonStartUpParams alloc] init];
    });
    return instance;
}
- (id)init{
    self = [super init];
    if (self) {
        _paramsCmd = 0;
        _paramsExtra = [[NSMutableDictionary alloc] init];
    }
    return self;
}
@end
