/*
 *  CmcNetSysctl.h
 *  TestFunction
 *
 *  Created by developer on 11-1-22.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// get network packets information
int CmcGetNetPacketsInfo(uint64_t *packets_recv,
                         uint64_t *packets_send,
                         uint64_t *bytes_recv,
                         uint64_t *bytes_send);

// get current network location name
int CmcGetNetLocation(char *location, int location_size);

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
                           int ssid_size);

int CmcGetInterfacePref(const char *bsd_name,
                        char *interface_type,
                        int type_size,
                        char *interface_name,
                        int name_size);
