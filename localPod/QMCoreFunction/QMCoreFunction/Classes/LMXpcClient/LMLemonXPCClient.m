//
//  LMLemonXPCClient.m
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMLemonXPCClient.h"
#import "LMXpcClientManager.h"

@implementation LMLemonXPCClient

// Replace the API of this protocol with an API appropriate to the service you are vending.
- (void)sendDataToLemon:(NSData *)paramData withReply:(void (^)(NSData *))replyData{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[LMXpcClientManager sharedInstance].delegate respondsToSelector:@selector(receiveData:)]) {
            [[LMXpcClientManager sharedInstance].delegate receiveData:paramData];
        }
    });
}
- (void)sendDictionaryToLemon:(NSDictionary *)paramDic withReply:(void (^)(NSDictionary *))replyDic{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[LMXpcClientManager sharedInstance].delegate respondsToSelector:@selector(receiveDictionary:)]) {
            [[LMXpcClientManager sharedInstance].delegate receiveDictionary:paramDic];
        }
    });
}

@end
