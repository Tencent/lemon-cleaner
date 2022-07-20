//
//  LMLemonXPCProtocol.h
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McPipeStruct.h"

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@protocol LMLemonXPCProtocol <NSObject>

// Replace the API of this protocol with an API appropriate to the service you are vending.
- (void)sendDataToLemon:(NSData *)paramData withReply:(void (^)(NSData *))replyData;
- (void)sendDictionaryToLemon:(NSDictionary *)paramDic withReply:(void (^)(NSDictionary *))replyDic;

@end

