//
//  LMDaemonXPCService.m
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMDaemonXPCService.h"
#import "LMXPCFunction.h"

@implementation LMDaemonXPCService 

//build
- (void)buildXPCConnectChannel{
    NSLog(@"Lemon daemon buildXPCConnectChannel success");
}

// reply with on data, just return value
- (void)sendDataToDaemon:(NSData *)paramData withReply:(void (^)(NSData *))replyData{
    NSLog(@"sendDataToDaemon begin");
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)[paramData bytes];
    
    if (pcmd->cmd_magic == MCCMD_STAT_PORT_INFO)
    {
        dispatch_block_t block = ^{
            mc_pipe_result *ppresult = NULL;
            [LMXPCFunction cmdForStatPort:pcmd result:&ppresult];
            if (ppresult != NULL) {
                NSData *rdata = [NSData dataWithBytes:(void*)ppresult length:ppresult->size];
                replyData(rdata);
                NSLog(@"rdata: %lu", (unsigned long)rdata.length);
                free(ppresult);
            } else {
                NSLog(@"%s %d ppresult is NULL", __FUNCTION__, pcmd->cmd_magic);
                replyData([NSData data]);
            }
        };
        block();
        //dispatch_async(dispatch_get_global_queue(0, 0), block);
    } else {
        mc_pipe_result *ppresult = NULL;
        [LMXPCFunction cmdDispather:pcmd result:&ppresult];
        if (ppresult != NULL) {
            NSData *rdata = [NSData dataWithBytes:(void*)ppresult length:ppresult->size];
            replyData(rdata);
            free(ppresult);
        } else {
            NSLog(@"%s %d ppresult is NULL", __FUNCTION__, pcmd->cmd_magic);
            replyData([NSData data]);
        }
    }
    
    //NSLog(@"sendDataToDaemon end");
//
//    int total_size;
//    int fun_ret;
//    mc_pipe_result *presult;
//    switch (pcmd->cmd_magic)
//    {
//        case MCCMD_CHANGE_NETWORK_INFO:
//        {
//            NSLog(@"[info] MCCMD_PURGE_MEMORY cmd");
//            fun_ret = system("purge");
//            ppresult = [LMXPCFunction cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
//        }
//            break;
//        case MCCMD_UNINSTALL_PLIST:
//        {
//            NSLog(@"[info] MCCMD_UNINSTALL_PLIST cmd");
//
//            op_file_path *plist_param = (op_file_path *)(pcmd + 1);
//            NSString* plist = [NSString stringWithUTF8String:plist_param->szPlist];
//            NSFileManager *fileMgr = [NSFileManager defaultManager];
//            fun_ret = -1;
//            if ([fileMgr fileExistsAtPath:plist]) {
//                fun_ret = system([[NSString stringWithFormat:@"launchctl unload %@", plist] UTF8String]);
//            }
//            ppresult = [LMXPCFunction cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
//        }
//            break;
//    }
//    NSData *rdata = [NSData dataWithBytes:(void*)ppresult length:ppresult->size];
//    replyData(rdata);
}

@end
