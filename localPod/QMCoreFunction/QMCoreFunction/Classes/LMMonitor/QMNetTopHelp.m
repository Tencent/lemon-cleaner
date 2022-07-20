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

