//
//  LMMonitorXPCClient.m
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMMonitorXPCClient.h"
#import "LMXpcClientManager.h"

@implementation LMMonitorXPCClient

// Replace the API of this protocol with an API appropriate to the service you are vending.
- (void)sendDataToMonitor:(NSData *)paramData withReply:(void (^)(NSData *))replyData{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[LMXpcClientManager sharedInstance].delegate respondsToSelector:@selector(receiveData:)]) {
            [[LMXpcClientManager sharedInstance].delegate receiveData:paramData];
        }
    });
}
- (void)sendDictionaryToMonitor:(NSDictionary *)paramDic withReply:(void (^)(NSDictionary *))replyDic{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[LMXpcClientManager sharedInstance].delegate respondsToSelector:@selector(receiveDictionary:)]) {
            [[LMXpcClientManager sharedInstance].delegate receiveDictionary:paramDic];
        }
    });
}

@end
