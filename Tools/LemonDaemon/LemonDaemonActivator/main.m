//
//  main.m
//  LemonDaemonActivator
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketCommunicationKeyWord.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <unistd.h>
#import <stdlib.h>
#import "LemonDaemonConst.h"

BOOL isSuccessStatement(NSString *str){
    BOOL ret = NO;
    NSPredicate *predicateSuccessed = [NSPredicate predicateWithFormat:@"self ENDSWITH %@", KEY_WORD_START_SUCCESSED];
    BOOL isSuccessed = [predicateSuccessed evaluateWithObject:str];
    if (isSuccessed) {
        NSLog(@"daemon start success");
        ret = YES;
    }
    return ret;
}

BOOL isFailStatement(NSString *str) {
    BOOL ret = NO;
    NSPredicate *predicateFailed= [NSPredicate predicateWithFormat:@"self ENDSWITH %@", KEY_WORD_START_FAILED];
    BOOL isFailed = [predicateFailed evaluateWithObject:str];
    if (isFailed) {
        NSLog(@"daemon start failed");
        ret = YES;
    }
    return ret;
}

// return: -1:socket创建失败
//         -2:connect失败
//         -3:read失败
//         -4:通过 "socket拉起起的Daemon" 无法正常唤醒 "最终Daemon".
//          1:拉活成功
//          0:拉活失败
int activeDaemon(void){
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
    strcpy(address.sun_path, "/var/run/com.tencent.Lemon.socket");
    ret = connect(sockfd, (struct sockaddr *)&address, sizeof(address));
    if ( ret == -1) {
        NSLog(@"socket connect error, %s", strerror(errno));
        return -2;
    }
    
    NSLog(@"socket connected");
    //
    char buf[1000];
    ssize_t count;
    
    ret = -4;
    // 卡死保护，最多读10次，如果读10次，都检测不到成功或失败标志，直接退出。
    int max_read_count = 10;
    while (1) {
        NSLog(@"max_read_count is %u", max_read_count);
        if ((count = read (sockfd, &buf, sizeof(buf))) == -1) { // read 是默认阻塞的(socket 默认是阻塞的) // -1是连接未建立 ,但Daemon断通过 NSLog传递的数据可能多次发送过来. 所以需要 read 多次.
            perror ("read");
            NSLog(@"socket read error:%s", strerror(errno));
            return -3;
        }
        BOOL isDetectedStatement = NO;
        BOOL isSuccess = NO;
        max_read_count--;
        NSArray<NSString *> *strArray = [[NSString stringWithUTF8String:buf] componentsSeparatedByString:@"\n"];
        for (NSString *str in strArray) {
            NSLog(@"%s, %@", __FUNCTION__, str);
            if (isSuccessStatement(str)) {
                isDetectedStatement = YES;
                isSuccess = YES;
                break;
            }
            
            if (isFailStatement(str)) {
                isDetectedStatement = YES;
                isSuccess = NO;
                break;
            }
        }
        
        if (isDetectedStatement || max_read_count <= 0) {
            NSLog(@"daemon start success: %d, loop time is %u", isSuccess, max_read_count);
            ret = isSuccess;
            break;
        }
    }
    return ret;
    
}

int main(int argc, const char * argv[]) {
    int ret = 0;
    @autoreleasepool {
        // insert code here...
        ret = activeDaemon();
    }
    return ret;
}
