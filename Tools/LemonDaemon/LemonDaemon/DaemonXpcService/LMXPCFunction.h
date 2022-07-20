//
//  LMXPCFunction.h
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McPipeStruct.h"

@interface LMXPCFunction : NSObject

+ (mc_pipe_result *)cmdSimpleReply:(int)ret magic:(int)magic;
+ (void)cmdDispather:(mc_pipe_cmd *)pcmd result:(mc_pipe_result **)ppresult;

+ (void)cmdForStatPort:(mc_pipe_cmd *)pcmd result:(mc_pipe_result **)ppresult;

@end
