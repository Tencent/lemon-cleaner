//
//  CmcNetSocket.m
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcNetSocket.h"
#include <errno.h>
#include <netdb.h>
#include <libproc.h>
#include <arpa/inet.h>

int process_socket(int pid, int fd, socket_info *out_sk_info)
{
    struct socket_fdinfo sk_info;
    
    if (out_sk_info == NULL)
        return -1;
    
    // get socket info
    if (proc_pidfdinfo(pid, fd, PROC_PIDFDSOCKETINFO, &sk_info, sizeof(sk_info)) <= 0)
    {
        NSLog(@"[err] get sock info fail with pid: %d, error: %s", pid, strerror(errno));
        return -1;
    }
    
//    char local_addr[128] = {0};
//    unsigned short lport;
//    char remote_addr[128] = {0};
//    unsigned short fport;
//    struct servent *port_srv;
    switch (sk_info.psi.soi_family)
    {
        case AF_INET:
            // IPv4
            
            // TCP
            // only care about established connection
            if (sk_info.psi.soi_kind == SOCKINFO_TCP
                && TSI_S_ESTABLISHED == sk_info.psi.soi_proto.pri_tcp.tcpsi_state)
            {
//                struct in_addr fip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_faddr.ina_46.i46a_addr4;
//                struct hostent *fhp;
//                struct in_addr lip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4;
//                struct hostent *lhp;
//                
//                // get ip and port
//                strcpy(local_addr, inet_ntoa(lip));
//                strcpy(remote_addr, inet_ntoa(fip));
//                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
//                fport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_fport);
//                
//                NSLog(@"    IPv4-TCP %s:%d -> %s:%d", local_addr, lport, remote_addr, fport);
//                
//                // host name
//                fhp = gethostbyaddr((void *)&fip, sizeof(fip), AF_INET);
//                lhp = gethostbyaddr((void *)&lip, sizeof(lip), AF_INET);
//                if (lhp != NULL && fhp != NULL)
//                {
//                    port_srv = getservbyport(htons(fport), "tcp");
//                    if (port_srv != NULL)
//                        NSLog(@"             %s:%d -> %s:%s", lhp->h_name, lport, fhp->h_name, port_srv->s_name);
//                    else
//                        NSLog(@"             %s:%d -> %s:%d", lhp->h_name, lport, fhp->h_name, fport);
//                }
                
                out_sk_info->soi_family = sk_info.psi.soi_family;
                memcpy(&out_sk_info->skinfo, 
                       &sk_info.psi.soi_proto.pri_tcp, 
                       sizeof(struct tcp_sockinfo));
                return 0;
            }
            
            // UDP
            if (sk_info.psi.soi_kind == SOCKINFO_IN)
            {
//                struct in_addr lip = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4;
//                struct hostent *lhp;
//                
//                strcpy(local_addr, inet_ntoa(lip));
//                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
//                
//                if (strcmp(local_addr, "0.0.0.0") == 0)
//                    strcpy(local_addr, "*");
//                
//                NSLog(@"    IPv4-UDP %s:%d", local_addr, lport);
//                
//                lhp = gethostbyaddr((void *)&lip, sizeof(lip), AF_INET);
//                if (lhp != NULL)
//                {   
//                    port_srv = getservbyport(htons(lport), "udp");
//                    if (port_srv != NULL)
//                        NSLog(@"             %s:%s", lhp->h_name, port_srv->s_name);
//                    else
//                        NSLog(@"             %s:%d", lhp->h_name, lport);
//                }
            }
            break;
            
        case AF_INET6:
            // IPv6
            
            // TCP
            // only care about established connection
            if (sk_info.psi.soi_kind == SOCKINFO_TCP
                && TSI_S_ESTABLISHED == sk_info.psi.soi_proto.pri_tcp.tcpsi_state)
            {
//                inet_ntop(AF_INET6, 
//                          (void *)&(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_6),
//                          local_addr,
//                          sizeof(local_addr));
//                inet_ntop(AF_INET6,
//                          (void *)&(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_faddr.ina_6),
//                          remote_addr,
//                          sizeof(remote_addr));
//                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
//                fport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_fport);
//                
//                NSLog(@"    IPv6-TCP %s:%d -> %s:%d", local_addr, lport, remote_addr, fport);
//                
//                // host name
//                char fhostname[200] = {0};
//                struct sockaddr_in6 fsa;
//                fsa.sin6_len = sizeof(fsa);
//                fsa.sin6_family = AF_INET6;
//                fsa.sin6_port = fport;
//                fsa.sin6_addr = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_faddr.ina_6;
//                
//                char lhostname[200] = {0};
//                struct sockaddr_in6 lsa;
//                lsa.sin6_len = sizeof(lsa);
//                lsa.sin6_family = AF_INET6;
//                lsa.sin6_port = lport;
//                lsa.sin6_addr = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_6;
//                
//                if (getnameinfo((struct sockaddr *)&fsa, sizeof(fsa),
//                                fhostname, sizeof(fhostname),
//                                NULL, 0,
//                                0) == 0
//                    && getnameinfo((struct sockaddr *)&lsa, sizeof(lsa),
//                                   lhostname, sizeof(lhostname),
//                                   NULL, 0,
//                                   0) == 0)
//                {
//                    port_srv = getservbyport(htons(fport), "tcp");
//                    if (port_srv != NULL)
//                        NSLog(@"             %s:%d -> %s:%s", lhostname, lport, fhostname, port_srv->s_name);
//                    else
//                        NSLog(@"             %s:%d -> %s:%d", lhostname, lport, fhostname, fport);
//                }
                
                out_sk_info->soi_family = sk_info.psi.soi_family;
                memcpy(&out_sk_info->skinfo, 
                       &sk_info.psi.soi_proto.pri_tcp, 
                       sizeof(struct tcp_sockinfo));
                return 0;
            }
            
            // UDP
            if (sk_info.psi.soi_kind == SOCKINFO_IN)
            {
//                inet_ntop(AF_INET6, 
//                          (void *)&(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_6),
//                          local_addr,
//                          sizeof(local_addr));
//                lport = ntohs(sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
//                
//                if (strcmp(local_addr, "::") == 0)
//                    strcpy(local_addr, "*");
//                
//                NSLog(@"    IPv6-UDP %s:%d", local_addr, lport);
//                
//                char lhostname[200] = {0};
//                struct sockaddr_in6 lsa;
//                lsa.sin6_len = sizeof(lsa);
//                lsa.sin6_family = AF_INET6;
//                lsa.sin6_port = lport;
//                lsa.sin6_addr = sk_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_6;
//                if (getnameinfo((struct sockaddr *)&lsa, sizeof(lsa),
//                                lhostname, sizeof(lhostname),
//                                NULL, 0,
//                                0) == 0)
//                {
//                    if (strcmp(lhostname, "::") == 0)
//                        strcpy(lhostname, "*");
//                    
//                    port_srv = getservbyport(htons(lport), "udp");
//                    if (port_srv != NULL)
//                        NSLog(@"             %s:%s", lhostname, port_srv->s_name);
//                    else
//                        NSLog(@"             %s:%d", lhostname, lport);
//                }
            }
            break;
        default:
            break;
    }
    
    return -1;
}

int process_fds(int pid, int fd_count, socket_info *sk_info)
{
    int nsize = fd_count * sizeof(struct proc_fdinfo);
    struct proc_fdinfo *fdinfo_array = malloc(nsize);
    
    // get all fd
    nsize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fdinfo_array, nsize);
    if (nsize <= 0)
    {
        if (errno != ESRCH)
        {
            NSLog(@"[err] get process fds info fail: %s", strerror(errno));
        }
        free(fdinfo_array);
        return -1;
    }
    
    // loop with all file description
    struct proc_fdinfo *fdinfo;
    int sk_count = 0;
    for (int i = 0; i < nsize/sizeof(struct proc_fdinfo); i++)
    {
        fdinfo = &fdinfo_array[i];
        switch (fdinfo->proc_fdtype) 
        {
            case PROX_FDTYPE_SOCKET:
                if (process_socket(pid, fdinfo->proc_fd, &sk_info[sk_count]) == 0)
                {
                    sk_count++;
                }
                break;
            default:
                break;
        }
    }
    
    free(fdinfo_array);
    return sk_count;
}

int CmcGetProcessSocketsInfo(process_sockets_info *proc_sk_info_array[], int max_count)
{
    if (proc_sk_info_array == NULL)
        return -1;
    
    // get all pid list
    int pid_size = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (pid_size <= 0)
    {
        NSLog(@"[err] get pid count fail: %s", strerror(errno));
        return -1;
    }
    
    pid_size *= 2;
    int *pid_array = malloc(pid_size);
    pid_size = proc_listpids(PROC_ALL_PIDS, 0, pid_array, pid_size);
    if (pid_size < 0)
    {
        free(pid_array);
        NSLog(@"[err] get pid list fail: %s", strerror(errno));
        return -1;
    }
    
    // loop all processes
    int pid;
	struct proc_taskallinfo task_info;
    int process_count = pid_size/sizeof(int);
    int real_count = 0;
    for (int i = 0; i < process_count; i++)
    {
        if ((pid = pid_array[i]) <= 0)
            continue;
        
        // dont record self
        if (pid == getpid())
            continue;
        
        //NSLog(@"[info] ready to get info of %d", pid);
        
        if (proc_pidinfo(pid, PROC_PIDTASKALLINFO, 9, &task_info, sizeof(task_info)) <= 0)
        {
            if (errno != ESRCH)
            {
                NSLog(@"[err] get pid %d info fail: %s", pid, strerror(errno));
            }
            continue;
        }
        
        // Check for process or command exclusion ?
        
        
        if (task_info.pbsd.pbi_nfiles == 0)
            continue;
        
        // allocate max possible size
        process_sockets_info *proc_sk_info = malloc(sizeof(process_sockets_info) + (task_info.pbsd.pbi_nfiles - 1) * sizeof(socket_info));
        socket_info *sk_info = proc_sk_info->sockets;
        // get socket information
        int sk_count = process_fds(pid, task_info.pbsd.pbi_nfiles, sk_info);
        if (sk_count > 0 && sk_info != NULL)
        {
            proc_sk_info->pid = pid;
            proc_sk_info->count = sk_count;
            proc_sk_info->len = sizeof(process_sockets_info) + (sk_count - 1) * sizeof(socket_info);
            
            proc_sk_info_array[real_count++] = proc_sk_info;
            
            if (real_count >= max_count)
                break;
        }
        else
        {
            free(proc_sk_info);
        }
    }
    
    free(pid_array);
    return real_count;
}
