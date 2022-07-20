//
//  LemonBizManager.h
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LemonBizManager : NSObject

@property (nonatomic, weak) NSXPCConnection *lemonCennection;
@property (nonatomic, weak) NSXPCConnection *monitorCennection;

+ (LemonBizManager *)shareInstance;

@end
