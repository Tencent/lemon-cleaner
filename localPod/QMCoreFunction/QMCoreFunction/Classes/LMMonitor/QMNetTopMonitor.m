//
//  QMNetTop.m
//  NetMonDemo
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMNetTopMonitor.h"
#import "McCoreFunction.h"
#import <pcap.h>

/*
 
 cd /dev/
 ls -l bpf*
 sudo chmod 644 bpf*
 
 */

/* Ethernet addresses are 6 bytes */
#define ETHER_ADDR_LEN    6
/* ethernet headers are always exactly 14 bytes */
#define SIZE_ETHERNET 14
/* Ethernet header */
struct sniff_ethernet {
    u_char ether_dhost[ETHER_ADDR_LEN]; /* Destination host address */
    u_char ether_shost[ETHER_ADDR_LEN]; /* Source host address */
    u_short ether_type; /* IP? ARP? RARP? etc */
};

/* IP header */
struct sniff_ip {
    u_char ip_vhl;        /* version << 4 | header length >> 2 */
    u_char ip_tos;        /* type of service */
    u_short ip_len;        /* total length */
    u_short ip_id;        /* identification */
    u_short ip_off;        /* fragment offset field */
#define IP_RF 0x8000        /* reserved fragment flag */
#define IP_DF 0x4000        /* dont fragment flag */
#define IP_MF 0x2000        /* more fragments flag */
#define IP_OFFMASK 0x1fff    /* mask for fragmenting bits */
    u_char ip_ttl;        /* time to live */
    u_char ip_p;        /* protocol */
    u_short ip_sum;        /* checksum */
    struct in_addr ip_src,ip_dst; /* source and dest address */
};
#define IP_HL(ip)        (((ip)->ip_vhl) & 0x0f)
#define IP_V(ip)        (((ip)->ip_vhl) >> 4)

/* TCP header */
typedef u_int tcp_seq;

struct sniff_tcp {
    u_short th_sport;    /* source port */
    u_short th_dport;    /* destination port */
    tcp_seq th_seq;        /* sequence number */
    tcp_seq th_ack;        /* acknowledgement number */
    u_char th_offx2;    /* data offset, rsvd */
#define TH_OFF(th)    (((th)->th_offx2 & 0xf0) >> 4)
    u_char th_flags;
#define TH_FIN 0x01
#define TH_SYN 0x02
#define TH_RST 0x04
#define TH_PUSH 0x08
#define TH_ACK 0x10
#define TH_URG 0x20
#define TH_ECE 0x40
#define TH_CWR 0x80
#define TH_FLAGS (TH_FIN|TH_SYN|TH_RST|TH_ACK|TH_URG|TH_ECE|TH_CWR)
    u_short th_win;        /* window */
    u_short th_sum;        /* checksum */
    u_short th_urp;        /* urgent pointer */
};

struct sniff_udp {
    u_short th_sport;    /* source port */
    u_short th_dport;    /* destination port */
    u_short th_length;    /* length */
    u_short th_sum;        /* checksum */
};

// 记录监控状态
static BOOL g_monitor_start = NO;
// 记录时间差(用于记算上下行的速率)
static CFAbsoluteTime g_lasttime = 0;
// 数据读写锁(用于锁定g_networkData)
static NSRecursiveLock *g_network_lock = NULL;
// key - socket连接字符串 object - 该socket上的流量（字节）
static NSMutableDictionary *g_networkData = NULL;
// 记录上一次的g_networkData(与新数据作差之后便可算速率)
static NSDictionary *g_old_networkData = NULL;
// 数据包捕获描述字(用于结束时关闭捕获)
static NSMutableArray *g_networkHandles = NULL;
// 用于记录外部请求流量信息的时间,当超过k_QUERY_TIMEOUT便暂停抓包
static time_t g_query_time = 0;
#define k_QUERY_TIMEOUT 10L

@implementation QMNetTopMonitor
// 添加新的数据包信息
void add_packetlen_networkdata(NSString *strSocketKey, u_short packetLen)
{
    if (!strSocketKey || packetLen==0)
        return;
    
    [g_network_lock lock];
    uint64_t totalLen = [g_networkData[strSocketKey] unsignedLongLongValue];
    totalLen += packetLen;
    [g_networkData setObject:@(totalLen) forKey:strSocketKey];
    [g_network_lock unlock];
}

// 当捕获到网络数据包时
void pcap_ethernet_handler(u_char *args,
                           const struct pcap_pkthdr *header,
                           const u_char *packet)
{
    @autoreleasepool
    {
        //外部超过一定时间未访问流量信息,暂时停止捕获包
        if (time(NULL) - g_query_time > k_QUERY_TIMEOUT)
            return;
        
        const struct sniff_ethernet *ethernet;  // The ethernet header
        const struct sniff_ip *ip;              // The IP header
        const struct sniff_tcp *tcp;            // The TCP header
        const struct sniff_udp *udp;            // The UDP header
        u_int size_ip;
        u_int size_tcp;
        u_short src_port;
        u_short dst_port;
        
        ethernet = (struct sniff_ethernet*)packet;
        
        //只关心IP包
        if (ethernet->ether_type != 0x8)
            return;
        
        ip = (struct sniff_ip*)(packet + SIZE_ETHERNET);
        size_ip = IP_HL(ip)*4;
        
        //长度有问题
        if (size_ip < 20 || header->len < SIZE_ETHERNET + size_ip)
            return;
        
        //目前只关心TCP和UDP的数据
        char szPackType[10] = {0};
        NSString *strKey;
        u_short packLen = ntohs(ip->ip_len) + SIZE_ETHERNET;
        switch(ip->ip_p)
        {
            case IPPROTO_TCP:
                tcp = (struct sniff_tcp*)(packet + SIZE_ETHERNET + size_ip);
                size_tcp = TH_OFF(tcp)*4;
                if (size_tcp < 20 || header->len < SIZE_ETHERNET + size_ip + size_tcp)
                {
                    return;
                }
                strcpy(szPackType, "TCP");
                // 获取端口
                src_port = ntohs(tcp->th_sport);
                dst_port = ntohs(tcp->th_dport);
                
                // key - 类型+源IP+源端口+目的IP+目的端口
                strKey = make_socket_key(ip->ip_p, &ip->ip_src, src_port, &ip->ip_dst, dst_port);
                add_packetlen_networkdata(strKey, packLen);
                
                break;
                
            case IPPROTO_UDP:
                udp = (struct sniff_udp*)(packet + SIZE_ETHERNET + size_ip);
                if (header->len < SIZE_ETHERNET + size_ip + 16)
                {
                    return;
                }
                strcpy(szPackType, "UDP");
                // 获取端口
                src_port = ntohs(udp->th_sport);
                dst_port = ntohs(udp->th_dport);
                
                // key - 类型+源IP+源端口+目的IP+目的端口
                // UDP协议只需要本地地址，这里简单处理，不判断哪个是本地，都加入列表
                strKey = make_socket_key(ip->ip_p, &ip->ip_src, src_port, NULL, 0);
                add_packetlen_networkdata(strKey, packLen);
                strKey = make_socket_key(ip->ip_p, NULL, 0, &ip->ip_dst, dst_port);
                add_packetlen_networkdata(strKey, packLen);
                
                break;
                
            case IPPROTO_ICMP:
            case IPPROTO_IP:
            default:
                return;
        }
        
        char srcIp[20];
        char dstIp[20];
        strcpy(srcIp, inet_ntoa(ip->ip_src));
        strcpy(dstIp, inet_ntoa(ip->ip_dst));
    }
}

#pragma mark - 外部接口

+ (void)startMonitor
{
    @synchronized(self)
    {
        if (g_monitor_start)
            return;
        g_monitor_start = YES;
        
        if (!g_network_lock)
        {
            g_network_lock = [[NSRecursiveLock alloc] init];
        }
        g_networkHandles = [[NSMutableArray alloc] init];
        g_networkData = [[NSMutableDictionary alloc] init];
        
        //设置这几个文件的权限才可抓包
        [[McCoreFunction shareCoreFuction] changeNetworkInfo];
        
        //获取网络设备列表
        char err_buf[PCAP_ERRBUF_SIZE];
        pcap_if_t *all_devices;
        if (pcap_findalldevs(&all_devices, err_buf) != 0)
        {
            printf("%s fail:%s \n",__func__,err_buf);
            return;
        }
        
        //获得用于捕获网络数据包的数据包捕获描述字。
        for (pcap_if_t *device = all_devices; device != NULL; device = device->next)
        {
            char *dev_name = device->name;
            int timeout = 1000;             //1s
            int promiscuous = 0;            //only care about data from/to this host
            int mac_hdr_size = 78;          //只要获取头部的数据就够了
            
            pcap_t *handle = pcap_open_live(dev_name, mac_hdr_size, promiscuous, timeout, err_buf);
            if (handle == NULL) {
                [[McCoreFunction shareCoreFuction] changeNetworkInfo];
                handle = pcap_open_live(dev_name, mac_hdr_size, promiscuous, timeout, err_buf);
                if (handle == NULL) {
                    continue;
                }
            }
            
            /*
             目前只支持以太网
             DLT_EN10MB    Ethernet
             DLT_IEEE802   802.5 Token Ring
             DLT_PPP       Point-to-point Protocol
             DLT_RAW       raw packet
             DLT_LINUX_SLL cooked sockets
             */
            int linkType = pcap_datalink(handle);
            if (linkType != DLT_EN10MB) {
                pcap_close(handle);
                continue;
            }
            
            [g_networkHandles addObject:[NSValue valueWithPointer:handle]];
            
            //启动线程捕获网络数据包
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                pcap_loop(handle, -1, pcap_ethernet_handler, NULL);
                
            });
        }
        pcap_freealldevs(all_devices);
    }
}

+ (void)stopMonitor
{
    @synchronized(self)
    {
        if (!g_monitor_start)
            return;
        g_monitor_start = NO;
        
        for (NSValue *pointerValue in g_networkHandles)
        {
            pcap_t *handle = [pointerValue pointerValue];
            pcap_breakloop(handle);
            pcap_close(handle);
        }
        
        g_lasttime = 0;
        g_networkData = nil;
        g_networkHandles = nil;
        g_old_networkData = nil;
    }
}

+ (NSDictionary *)flowSpeed
{
    @synchronized(self)
    {
        // 取一次数据计一次时间,
        g_query_time = time(NULL);
        
        // 如果还没有开启抓包监控
        if (!g_monitor_start)
        {
            [self startMonitor];
        }
        
        // 如果没有历史数据就先复制一份
        if (g_lasttime == 0 || [g_old_networkData count] == 0)
        {
            g_lasttime = CFAbsoluteTimeGetCurrent();
            [g_network_lock lock];
            g_old_networkData = [g_networkData copy];
            [g_network_lock unlock];
            return nil;
        }
        
        // 计算网速
        NSDictionary *socketInfo = processSocketInfo();
        CFAbsoluteTime endtime = CFAbsoluteTimeGetCurrent();
        NSMutableArray *aliveSockets = [NSMutableArray array];
        NSMutableDictionary *speedResult = [NSMutableDictionary dictionaryWithCapacity:10];
        
        [g_network_lock lock];
        NSDictionary *networkData = [g_networkData copy];
        for (NSNumber *pidKey in socketInfo)
        {
            NSDictionary *fdsInfo = [socketInfo objectForKey:pidKey];
            NSArray *upSockets = fdsInfo[kUpNetKey];
            NSArray *downSockets = fdsInfo[kDownNetKey];
            
            if (upSockets) [aliveSockets addObjectsFromArray:upSockets];
            if (downSockets) [aliveSockets addObjectsFromArray:downSockets];
            
            //计算上行总量
            uint64_t total_up_len = 0;
            uint64_t total_up_old = 0;
            for (NSString *socketKey in upSockets)
            {
                total_up_old += [[g_old_networkData objectForKey:socketKey] longLongValue];
                total_up_len += [[networkData objectForKey:socketKey] longLongValue];
            }
            
            //计算下行总量
            uint64_t total_down_len = 0;
            uint64_t total_down_old = 0;
            for (NSString *socketKey in downSockets)
            {
                total_down_old += [[g_old_networkData objectForKey:socketKey] longLongValue];
                total_down_len += [[networkData objectForKey:socketKey] longLongValue];
            }
            
            //计算上下行速度
            CFAbsoluteTime duration = endtime - g_lasttime;
            double upSpeed = (total_up_len - total_up_old)/duration;
            double downSpeed = (total_down_len - total_down_old)/duration;
            if (upSpeed == 0 && downSpeed == 0)
                continue;
            
            [speedResult setObject:@{kUpNetKey: @(upSpeed), kDownNetKey: @(downSpeed)} forKey:pidKey];
        }
        
        //清理已经不存在的Socket
        for (NSString *socketKey in networkData)
        {
            if (![aliveSockets containsObject:socketKey])
            {
                [g_networkData removeObjectForKey:socketKey];
            }
        }
        [g_network_lock unlock];
        
        // 将当前的设置为上一次的数据
        g_old_networkData = networkData;
        g_lasttime = endtime;
        
        return speedResult;
    }
}

@end
