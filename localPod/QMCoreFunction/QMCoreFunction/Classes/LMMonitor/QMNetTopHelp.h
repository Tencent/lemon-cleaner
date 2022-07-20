//
//  QMProcessSocket.h
//  NetMonDemo
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <arpa/inet.h>

#define kUpNetKey @"UP"
#define kDownNetKey @"DOWN"

//根据socket信息生成特征字条串的Key(类型+源IP+源端口+目的IP+目的端口)
NSString *make_socket_key(int type,const struct in_addr *srcIp, u_short srcPort,const struct in_addr *dstIp, u_short dstPort);

//返回所有进程的socket信息 key-pid value-sockets(up and down)
NSDictionary *processSocketInfo(void);

