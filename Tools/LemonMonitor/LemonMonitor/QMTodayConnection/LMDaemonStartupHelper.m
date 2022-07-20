//
//  LMDaemonStartupHelper.m
//  Lemon
//
//  Created by klkgogo on 2018/12/14.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMDaemonStartupHelper.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <unistd.h>
#import <stdlib.h>
#import "SocketCommunicationKeyWord.h"
#import <QMCoreFunction/McCoreFunction.h>

#define STARTUP_LISTEN_SOCKT          @"/var/run/com.tencent.Lemon.socket"

@implementation LMDaemonStartupHelper


+ (int)startDaemon{
    NSLog(@"%s", __FUNCTION__);
    
    int ret = 0;

    int sockfd;
    if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
        NSLog(@"socket create error,%s",strerror(errno));
        return -1;
    }
    NSLog(@"socket created");
    
    struct sockaddr_un address;
    address.sun_family = AF_UNIX;
    strcpy(address.sun_path, "/var/run/com.klk.socket");
    if (connect(sockfd, (struct sockaddr *)&address, sizeof(address)) == -1) {
        NSLog(@"socket connect error, %s", strerror(errno));
        return -1;
    }
    NSLog(@"socket connected");
    //
    char buf[1000];
    ssize_t count;
    ret = -1;
    while (1) {
        if ((count = read (sockfd, &buf, sizeof(buf))) == -1) { /*接收消息*/
            perror ("read");
            NSLog(@"socket read error:%s", strerror(errno));
            ret = -1;
            break;
        }

        NSString *receiveStr = [[NSString stringWithUTF8String:buf] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSLog(@"receive string %@", receiveStr);
        
        NSPredicate *predicateSuccessed = [NSPredicate predicateWithFormat:@"self ENDSWITH %@", KEY_WORD_START_SUCCESSED];
        BOOL isSuccessed = [predicateSuccessed evaluateWithObject:receiveStr];
        if (isSuccessed) {
            NSLog(@"daemon start success");
            ret = 1;
            break;
        }
        
        NSPredicate *predicateFailed= [NSPredicate predicateWithFormat:@"self ENDSWITH %@", KEY_WORD_START_FAILED];
        BOOL isFailed = [predicateFailed evaluateWithObject:receiveStr];
        if (isFailed) {
            NSLog(@"daemon start failed");
            ret = -1;
            break;
        }
        usleep(200 * 1000);
    }
    close(sockfd);
    
    return ret;
}

+ (int) notiflyDaemonClientExit {
    return [[McCoreFunction shareCoreFuction] notiflyClientExit];
}
@end
