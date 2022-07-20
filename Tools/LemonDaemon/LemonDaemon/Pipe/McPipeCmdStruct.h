/*
 *  McPipeCmdStruct.h
 *  Untitled_4
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#import <sys/types.h>
#import <sys/proc_info.h>

//****************************************************

// use for order data
typedef enum
{
    McprocNone = 0,
    McprocPid,
    McprocCPU,
    McprocResident,
    McprocVirtual
} ORDER_TYPE;

// define for p_flag
#define MCPROC_LP64     0x4

// process info struct
typedef struct _ProcessInfo_t
{
    pid_t pid;
    pid_t ppid;
    
    uid_t uid;
    
    int p_flag;
    
    char pUserName[100];
    char pExecutePath[300];
    char pExeName[100];

    
    uint64_t resident_size;
    uint64_t virtual_size;
    
    int threadCount;
    
    uint64_t cpu_time;
    uint64_t current_time;
} ProcessInfo_t;

//****************************************************

// detail
typedef struct
{
    //char *path;             // !!! pointer should recalculate
    char path[300];
    int ino;
    mode_t mode;
} kfs_result_Detail;

// file monitor data
typedef struct
{
    unsigned int index;
    int type;
    pid_t pid;
    unsigned long long tstamp;
    struct timeval record_time;
    // rename action: from detail1 to detail2
    kfs_result_Detail result_Detail1;
    kfs_result_Detail result_Detail2;
} kfs_result_Data;

//****************************************************

// socket info
typedef struct
{
    int                    soi_family;
    struct tcp_sockinfo skinfo;
} socket_info;

// socket info of process
typedef struct
{
    int             len;
    pid_t           pid;
    int             count;
    socket_info     sockets[1];
} process_sockets_info;


// the camera/audio process using info
typedef struct
{
    int             device_type;//0 is camera, 1 is audio
    pid_t           pid;
    char            name[100];
    int             time_count;
    char            path[300];
} lemon_com_process_info;


typedef struct
{
    size_t          file_size;
} get_file_info;

typedef struct
{
    int          is_enable; //0 : disable, 1 : enable
} get_launch_system_status;

//****************************************************
