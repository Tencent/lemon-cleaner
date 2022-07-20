/*
 *  CmcNetSysctl.c
 *  TestFunction
 *
 *  Created by developer on 11-1-22.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/route.h>
#include <net/if_types.h>
#include <errno.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include "CmcNetSysctl.h"
#include "McLogUtil.h"

#define kCFPreferencesNetworkConnect    "com.apple.networkConnect"

#define META_FALLBACK(expr, label, failure_expr) if (!(expr)) { \
    McLog(MCLOG_ERR, @"[%s]:%d %@ failed", __PRETTY_FUNCTION__, __LINE__, @#expr); \
    { failure_expr; }\
    goto label; \
}

// get network packets information
int CmcGetNetPacketsInfo(uint64_t *packets_recv,
                         uint64_t *packets_send,
                         uint64_t *bytes_recv,
                         uint64_t *bytes_send)
{
 	int mib[6];
    char *buf = NULL;
    char *limit;
    char *next;
	size_t len;
	struct if_msghdr *ifm;
    struct if_msghdr2 *if2m;
    
    if (packets_recv == NULL || packets_send == NULL
        || bytes_recv == NULL || bytes_send == NULL)
    {
        return -1;
    }
    
    // init to zero
    *packets_recv = 0;
    *packets_send = 0;
    *bytes_recv = 0;
    *bytes_send = 0;
    
    // info to get
    mib[0]	= CTL_NET;			// networking subsystem
	mib[1]	= PF_ROUTE;			// type of information
	mib[2]	= 0;				// protocol (IPPROTO_xxx)
	mib[3]	= 0;				// address family
	mib[4]	= NET_RT_IFLIST2;	// operation
	mib[5]	= 0;
    
    // get size first and alloc memory
    if (sysctl(mib, 6, NULL, &len, NULL, 0) == -1)
    {
        McLog(MCLOG_ERR, @"[%s] get iflist2 info size fail: %d", __FUNCTION__, errno);
        return -1;
    }
    buf = malloc(len);
	// get information
    if (sysctl(mib, 6, buf, &len, NULL, 0) == -1) 
    {
        McLog(MCLOG_ERR, @"[%s] get iflist2 info data fail: %d", __FUNCTION__, errno);
        
		free(buf);
		return -1;
	}
    
    // enumerate infomation
    limit = buf + len;
	for (next = buf; next < limit; ) 
    {
        ifm = (struct if_msghdr *)next;
		next += ifm->ifm_msglen;
        
        //NSLog(@"ifm_type - %x", ifm->ifm_type);
        if (ifm->ifm_type == RTM_IFINFO2) 
        {
			if2m = (struct if_msghdr2 *)ifm;
            
            //NSLog(@"ifm_data.ifi_type - %x", if2m->ifm_data.ifi_type);
            // Ethernet data only !!!
            // add PPP for 3G
			if (if2m->ifm_data.ifi_type == IFT_ETHER || if2m->ifm_data.ifi_type == IFT_PPP)
            {
                *packets_send += if2m->ifm_data.ifi_opackets;
                *packets_recv += if2m->ifm_data.ifi_ipackets;
                *bytes_send += if2m->ifm_data.ifi_obytes;
                *bytes_recv += if2m->ifm_data.ifi_ibytes;
            }
		} 
	}
    
    free(buf);
    return 0;
}


// get current network location name
int CmcGetNetLocation(char *location, int location_size)
{
#define EXIT_IF_FAIL(expr) META_FALLBACK(expr, failure,)
    SCPreferencesRef    netPref = NULL;
    SCNetworkSetRef     netSet = NULL;
    CFStringRef         netName = NULL;
    
    // copy current network set
    EXIT_IF_FAIL(netPref = SCPreferencesCreate(kCFAllocatorDefault, CFSTR("ISM"), NULL));
    
    EXIT_IF_FAIL(netSet = SCNetworkSetCopyCurrent(netPref));
    
    // get name
    EXIT_IF_FAIL(netName = SCNetworkSetGetName(netSet));
    EXIT_IF_FAIL(CFStringGetCString(netName, location, location_size, kCFStringEncodingUTF8));
    
    CFRelease(netSet);
    CFRelease(netPref);

    return 0;
    
failure:
    if (netSet) CFRelease(netSet);
    if (netPref) CFRelease(netPref);
    
    return -1;
#undef EXIT_IF_FAIL
}


void ReleaseCFObject(CFTypeRef cf)
{
    if (cf != NULL) {
        CFRelease(cf);
    }
}

// scutil
// get current net interface information
int CmcGetNetInterfaceInfo(char *name,
                           int name_size,
                           char *user_name,
                           int user_name_size,
                           char *ip,
                           int ip_size,
                           char *hardware,
                           int hardware_size,
                           char *ssid,
                           int ssid_size)
{
	SCDynamicStoreRef store = NULL;
	CFPropertyListRef propList = NULL;
    CFStringRef setupInterface = NULL;
    CFStringRef setupName = NULL;
    CFStringRef stateInterface = NULL;
    CFStringRef stateNameInterface = NULL;
    CFStringRef interfaceName;
    CFStringRef deviceName;
    CFStringRef interfaceService;
	CFArrayRef  ipAddrs;
    CFStringRef userDefName;
    CFStringRef hardwareName;
    CFStringRef ssidName;   // for wifi
    int ret = 0;
    // open the store
    store = SCDynamicStoreCreate(kCFAllocatorDefault, CFSTR("McPasterLib"), NULL, NULL);
	if (store == NULL) 
    {
        McLog(MCLOG_ERR, @"[%s] create dynamic store fail", __FUNCTION__);
        return -1;
    }
	propList = SCDynamicStoreCopyValue(store, CFSTR("State:/Network/Global/IPv4"));
    if (propList == NULL)
    {
        //McLog(MCLOG_ERR, @"[%s] get global ipv4 info fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    
    // get interface name:en1, service:D091AF51-BEC3-490C-B701-FA09B7C98B50
    interfaceName = CFDictionaryGetValue(propList, CFSTR("PrimaryInterface"));
    interfaceService = CFDictionaryGetValue(propList, CFSTR("PrimaryService"));
    if (interfaceName == NULL || interfaceService == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get interface info fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    
    // store in buffer
//    if (!CFStringGetCString(interfaceName, name, name_size, kCFStringEncodingUTF8))
//    {
//        McLog(MCLOG_ERR, @"[%s] convert service name string fail", __FUNCTION__);
//    }
    
    // create name: Setup:/Network/Service/D091AF51-BEC3-490C-B701-FA09B7C98B50/Interface
    setupInterface = CFStringCreateWithFormat(kCFAllocatorDefault, 
                                              NULL, 
                                              CFSTR("Setup:/Network/Service/%@/Interface"), 
                                              interfaceService);
    setupName = CFStringCreateWithFormat(kCFAllocatorDefault, 
                                         NULL, 
                                         CFSTR("Setup:/Network/Service/%@"), 
                                         interfaceService);
    // create name: State:/Network/Interface/en1/IPv4
    stateInterface = CFStringCreateWithFormat(kCFAllocatorDefault,
                                              NULL,
                                              CFSTR("State:/Network/Interface/%@/IPv4"),
                                              interfaceName);
    /*
     <dictionary> {
     Type : Ethernet
     DeviceName : en1
     UserDefinedName : AirPort
     Hardware : AirPort
     }     
     */
    // get user defined name
    CFRelease(propList);
    propList = SCDynamicStoreCopyValue(store, setupName);
    if (propList == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get setup info fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    // UserDefinedName - AirPort/Wi-Fi
    userDefName = CFDictionaryGetValue(propList, CFSTR("UserDefinedName"));
    if (userDefName == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get user defined name fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    // store in buffer
    if (!CFStringGetCString(userDefName, user_name, user_name_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert user defined name string fail", __FUNCTION__);
    }
    
    CFRelease(propList);
    propList = SCDynamicStoreCopyValue(store, setupInterface);
    if (propList == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get setup interface info fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    // get device name to compare
    deviceName = CFDictionaryGetValue(propList, CFSTR("DeviceName"));
//    CFStringGetCString(deviceName, name, name_size, kCFStringEncodingUTF8)
    if (deviceName == NULL || !CFStringGetCString(deviceName, name, name_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert device name string fail", __FUNCTION__);
    }
    // Hardware - AirPort
    hardwareName = CFDictionaryGetValue(propList, CFSTR("Hardware"));
    if (hardwareName == NULL)
    {
        // get Type instead
        hardwareName = CFDictionaryGetValue(propList, CFSTR("Type"));
        if (hardwareName == NULL)
        {
            McLog(MCLOG_ERR, @"[%s] get hardware and type name fail", __FUNCTION__);
            ret = -1;
            goto out;
        }
    }
    // store in buffer
    if (!CFStringGetCString(hardwareName, hardware, hardware_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert user defined name string fail", __FUNCTION__);
    }
    
    // get ip address
    CFRelease(propList);
    propList = SCDynamicStoreCopyValue(store, stateInterface);
    if (propList == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get state interface info fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    // Addresses - <array> {0 : 192.168.1.106}
    ipAddrs = CFDictionaryGetValue(propList, CFSTR("Addresses"));
    if (ipAddrs == NULL)
    {
        McLog(MCLOG_ERR, @"[%s] get ip address array fail", __FUNCTION__);
        ret = -1;
        goto out;
    }
    // store in buffer, get the first ip address
    if (!CFStringGetCString(CFArrayGetValueAtIndex(ipAddrs, 0), ip, ip_size, kCFStringEncodingUTF8))
    {
        McLog(MCLOG_ERR, @"[%s] convert user defined name string fail", __FUNCTION__);
    }
    
    // get SSID under airport
    if (strcasecmp(hardware, "AirPort") != 0)
        goto out;
    
    // create name: State:/Network/Interface/en1/AirPort
    stateNameInterface = CFStringCreateWithFormat(kCFAllocatorDefault,
                                                  NULL,
                                                  CFSTR("State:/Network/Interface/%s/%s"),
                                                  name,
                                                  hardware);
    /*
     <dictionary> {
     Power Status : 1
     SecureIBSSEnabled : FALSE
     BSSID : <data> 0x001478c448aa
     Busy : FALSE
     SSID : <data> 0x53432d4741
     SSID_STR : SC-GA
     CHANNEL : <dictionary> {
     CHANNEL : 6
     CHANNEL_FLAGS : 10
     }
     }     
     */
    // get ssid name
    CFRelease(propList);
    propList = SCDynamicStoreCopyValue(store, stateNameInterface);
    if (propList == NULL)
    {
        //McLog(MCLOG_WARN, @"[%s] get name interface info fail", __FUNCTION__);
        //ret = -1;
        goto out;
    }
    // SSID_STR : SC-GA
    ssidName = CFDictionaryGetValue(propList, CFSTR("SSID_STR"));
    if (ssidName == NULL)
    {
        //McLog(MCLOG_WARN, @"[%s] get ssid name fail", __FUNCTION__);
        //ret = -1;
        goto out;
    }
    // store in buffer
    CFStringGetCString(ssidName, ssid, ssid_size, kCFStringEncodingUTF8);
//    if (!CFStringGetCString(ssidName, ssid, ssid_size, kCFStringEncodingUTF8))
//    {
        //McLog(MCLOG_ERR, @"[%s] convert ssid name string fail", __FUNCTION__);
//    }
    
out:
    // release
    ReleaseCFObject(setupInterface);
    ReleaseCFObject(setupName);
    ReleaseCFObject(stateInterface);
    ReleaseCFObject(stateNameInterface);
    ReleaseCFObject(propList);
    ReleaseCFObject(store);

    return ret;
}

int CmcGetInterfacePref(const char *bsd_name,
                        char *interface_type,
                        int type_size,
                        char *interface_name,
                        int name_size)
{
    NSString *compareBsdName = [NSString stringWithUTF8String:bsd_name];
    NSArray *interfaceList = (__bridge_transfer NSArray *)SCNetworkInterfaceCopyAll();
    for (id interface in interfaceList)
    {
        SCNetworkInterfaceRef NetworkInterface = (__bridge SCNetworkInterfaceRef)interface;
        
        // compare name en0 - enx
        CFStringRef interBsdName = SCNetworkInterfaceGetBSDName(NetworkInterface);
        //NSLog(@"%@", interBsdName);
        if ([(__bridge NSString *)interBsdName isEqualToString:compareBsdName])
        {
            CFStringRef interType = SCNetworkInterfaceGetInterfaceType(NetworkInterface);
            if (!interType) return -1;
            CFStringGetCString(interType, interface_type, type_size, kCFStringEncodingUTF8);

            CFStringRef interDisplayName = SCNetworkInterfaceGetLocalizedDisplayName(NetworkInterface);
            if (!interDisplayName) return -1;
            CFStringGetCString(interDisplayName, interface_name, name_size, kCFStringEncodingUTF8);
            return 0;
        }
    }
    
    return -1;
}
