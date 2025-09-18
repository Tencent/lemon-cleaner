//
//  QMProcessSocket.m
//  NetMonDemo
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMNetTopHelp.h"
#import <libproc.h>

NSString *make_socket_key(int type,
                          const struct in_addr *srcIp, u_short srcPort,
                          const struct in_addr *dstIp, u_short dstPort)
{
    if (srcIp == NULL && dstIp == NULL)
        return nil;
    
    if (srcIp != NULL && dstIp != NULL)
    {
        return [NSString stringWithFormat:@"%d:%d:%d:%d:%d", type, srcIp->s_addr, srcPort, dstIp->s_addr, dstPort];
    }
    else if (dstIp == NULL)
    {
        return [NSString stringWithFormat:@"%d:%d:%d:-:-", type, srcIp->s_addr, srcPort];
    }
    else
    {
        return [NSString stringWithFormat:@"%d:-:-:%d:%d", type, dstIp->s_addr, dstPort];
    }
}

NSDictionary* process_socket(int pid, int fd)
{
    struct socket_fdinfo sk_info;
    
    // get socket info
    if (proc_pidfdinfo(pid, fd, PROC_PIDFDSOCKETINFO, &sk_info, sizeof(sk_info)) <= 0)
    {
        NSLog(@"[err] get sock info fail with pid: %d, error: %s", pid, strerror(errno));
        return nil;
    }
    
    NSDictionary *fdInfo = nil;
    
    char local_addr[128] = {0};
    char remote_addr[128] = {0};
    unsigned short lport;
    unsigned short fport;
    switch (sk_info.psi.soi_family)
    {
        case AF_INET:
            // IPv4
            
            // TCP
            if (sk_info.psi.soi_kind == SOCKINFO_TCP)
            {
                struct in_addr fip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_faddr.ina_46.i46a_addr4;
                struct in_addr lip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4;
                
                // get ip and port
                strcpy(local_addr, inet_ntoa(lip));
                strcpy(remote_addr, inet_ntoa(fip));
                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
                fport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_fport);
                
                // 可以区分上传下载
                NSString *upSocketKey = make_socket_key(IPPROTO_TCP, &lip, lport, &fip, fport);
                NSString *downSocketKey = make_socket_key(IPPROTO_TCP, &fip, fport, &lip, lport);
                fdInfo = @{kUpNetKey: upSocketKey, kDownNetKey: downSocketKey};
            }
            
            // UDP
            if (sk_info.psi.soi_kind == SOCKINFO_IN)
            {
                struct in_addr lip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4;
                //struct hostent *lhp;
                
                strcpy(local_addr, inet_ntoa(lip));
                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
                
                if (strcmp(local_addr, "0.0.0.0") == 0)
                    strcpy(local_addr, "*");
                
                // UDP是无连接的，只能获取本地端口
                // 可以区分上传下载
                NSString *upSocketKey = make_socket_key(IPPROTO_UDP, &lip, lport, NULL, 0);
                NSString *downSocketKey = make_socket_key(IPPROTO_UDP, NULL, 0, &lip, lport);
                fdInfo = @{kUpNetKey: upSocketKey, kDownNetKey: downSocketKey};
            }
            break;
        default:
            break;
    }
    
    return fdInfo;
}

NSDictionary* process_fds(int pid, int fd_count)
{
    int nsize = fd_count * sizeof(struct proc_fdinfo);
    struct proc_fdinfo *fdinfo_array = malloc(nsize);
    
    // get all fd
    nsize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fdinfo_array, nsize);
    if (nsize <= 0)
    {
        if (errno != ESRCH)
        {
            //NSLog(@"[err] get process fds info fail: %s", strerror(errno));
        }
        free(fdinfo_array);
        return nil;
    }
    
    // loop with all file description
    NSMutableArray *socketUpArray = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *socketDownArray = [NSMutableArray arrayWithCapacity:10];
    NSDictionary *socketInfo = @{kUpNetKey: socketUpArray, kDownNetKey: socketDownArray};
    
    struct proc_fdinfo *fdinfo;
    int loopCount = nsize/sizeof(struct proc_fdinfo);
    
    for (int i = 0; i < loopCount; i++)
    {
        fdinfo = &fdinfo_array[i];
        switch (fdinfo->proc_fdtype)
        {
            case PROX_FDTYPE_SOCKET:
            {
                NSDictionary *fdInfo = process_socket(pid, fdinfo->proc_fd);
                
                NSString *upSocketKey = fdInfo[kUpNetKey];
                if (upSocketKey && ![socketUpArray containsObject:upSocketKey])
                {
                    [socketUpArray addObject:upSocketKey];
                }
                
                NSString *downSocketKey = fdInfo[kDownNetKey];
                if (downSocketKey && ![socketDownArray containsObject:downSocketKey])
                {
                    [socketDownArray addObject:downSocketKey];
                }
                
                break;
            }
            default:
                break;
        }
    }
    
    free(fdinfo_array);
    return socketInfo;
}

NSDictionary *processSocketInfo(void)
{
    int pid_size = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (pid_size <= 0)
    {
        NSLog(@"[err] get pid count fail: %s", strerror(errno));
        return nil;
    }
    
    pid_size *= 2;
    int *pid_array = malloc(pid_size);
    pid_size = proc_listpids(PROC_ALL_PIDS, 0, pid_array, pid_size);
    if (pid_size < 0)
    {
        free(pid_array);
        NSLog(@"[err] get pid list fail: %s", strerror(errno));
        return nil;
    }
    
    NSMutableDictionary *socketDictionary = [[NSMutableDictionary alloc] initWithCapacity:pid_size];
    
    // loop all processes
    int pid;
	struct proc_taskallinfo task_info;
    int process_count = pid_size/sizeof(int);
    
    for (int i = 0; i < process_count; i++)
    {
        if ((pid = pid_array[i]) <= 0)
            continue;
        
        if (proc_pidinfo(pid, PROC_PIDTASKALLINFO, 9, &task_info, sizeof(task_info)) <= 0)
        {
            if (errno != ESRCH)
            {
                //NSLog(@"[err] get pid %d info fail: %s", pid, strerror(errno));
            }
            continue;
        }
        
        // get socket count
        uint32_t fds_count = task_info.pbsd.pbi_nfiles;
        if (fds_count == 0)
            continue;
        
        // get socket information
        NSDictionary *socketInfo = process_fds(pid, fds_count);
        if (socketInfo.count > 0)
        {
            [socketDictionary setObject:socketInfo forKey:[NSNumber numberWithInt:pid]];
        }
    }
    
    free(pid_array);
    return socketDictionary;
}

// 使用 nettop 命令行工具获取网络速度信息
NSDictionary *processNetInfoWithNetTop(void)
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/nettop";
    
    // 使用 nettop 获取实时网络速度: -P 按进程分组, -l 1 只运行一次, -J 指定输出列, -x 不显示表头
    task.arguments = @[@"-P", @"-l", @"1", @"-J", @"bytes_in,bytes_out", @"-x"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    NSFileHandle *file = pipe.fileHandleForReading;
    
    @try {
        [task launch];
        [task waitUntilExit];
        
        NSData *data = [file readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (task.terminationStatus == 0) {
            return parseNetTrafficWihtNetTopOutput(output);
        } else {
            NSLog(@"[QMNetTopHelp] nettop command failed with status: %d", task.terminationStatus);
            // 如果 nettop 失败，返回空字典
            return @{};
        }
    } @catch (NSException *exception) {
        NSLog(@"[QMNetTopHelp] Exception running nettop: %@", exception.reason);
        // 如果出现异常，返回空字典
        return @{};
    }
}

static NSInteger kUp_OFFSET_FROM_END = 1;
static NSInteger kDown_OFFSET_FROM_END = 2;
static NSInteger kPID_OFFSET_FROM_END = 3;

// 解析 nettop 输出，返回网络速度信息
NSDictionary *parseNetTrafficWihtNetTopOutput(NSString *nettopOutput)
{
    NSMutableDictionary *speedDictionary = [[NSMutableDictionary alloc] init];
    
    if (!nettopOutput || nettopOutput.length == 0) {
        return speedDictionary;
    }
    
    NSArray *lines = [nettopOutput componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedLine.length == 0) {
            continue;
        }
        
        // nettop 输出格式: ProcessName.PID bytes_in bytes_out
        NSArray *components = [trimmedLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
        NSMutableArray *filteredComponents = [NSMutableArray array];
        
        // 过滤空字符串
        for (NSString *component in components) {
            if (component.length > 0) {
                [filteredComponents addObject:component];
            }
        }
        
        if (filteredComponents.count >= 3) {
            NSInteger pidIndex = (filteredComponents.count - kPID_OFFSET_FROM_END);
            NSString *processNameWithPID = filteredComponents[pidIndex];
            // 解析进程名和PID (格式: ProcessName.PID)
            NSRange lastDotRange = [processNameWithPID rangeOfString:@"." options:NSBackwardsSearch];
            if (lastDotRange.location != NSNotFound) {
                NSString *pidString = [processNameWithPID substringFromIndex:lastDotRange.location + 1];
                int pid = [pidString intValue];
                if (pid > 0) {
                    NSInteger inIndex = (filteredComponents.count - kDown_OFFSET_FROM_END);
                    NSInteger outIndex = (filteredComponents.count - kUp_OFFSET_FROM_END);
                    uint64_t bytesIn = [filteredComponents[inIndex] longLongValue];   // 下行速度 (接收)
                    uint64_t bytesOut = [filteredComponents[outIndex] longLongValue];  // 上行速度 (发送)
                    
                    // 只有有网络活动的进程才添加到结果中
                    if (bytesIn > 0 || bytesOut > 0) {
                        NSDictionary *speedInfo = @{
                            kUpNetKey: @(bytesOut),    // UP = 上行 = 发送
                            kDownNetKey: @(bytesIn) // DOWN = 下行 = 接收
                        };
                        
                        speedDictionary[@(pid)] = speedInfo;
                    }
                }
            }
        }
    }
    
    return speedDictionary;
}
