//
#import "McPipeCmdStruct.h"

// defines for structures
#define MCPIPE_DIR                  "/Library/Application Support/Lemon/pipe"

// name for different purpose
#define MCPIPE_NAME_FSMON           @"/Library/Application Support/Lemon/pipe/lemon_fsmon"
#define MCPIPE_NAME_PROC            @"/Library/Application Support/Lemon/pipe/lemon_proc"
#define MCPIPE_NAME_SOCK            @"/Library/Application Support/Lemon/pipe/lemon_sock"

// postfix for pipe name
#define MCREAD_POSTFIX              @"_rd"
#define MCWRITE_POSTFIX             @"_wr"
#define MCLOCK_POSTFIX              @"_lk"
#define MCSEM_POSTFIX               @"_sem"

#define MCARRIVE_CMD                0xEB138A29
#define MCARRIVE_RESULT             0xDA027918

/*
 enum mc_arg_type
 {
 MCARG_VALUE = 0,
 MCARG_POINT
 };
 
 typedef struct _mc_cmd_arg
 {
 mc_arg_type     arg_type;
 void            *value;
 } mc_cmd_arg;
 */

typedef struct _mc_pipe_cmd
{
    int             size;
    int             cmd_magic;
    //int             arg_count;
    //void *param;
} mc_pipe_cmd;

typedef struct _mc_pipe_result
{
    int             size;
    int             cmd_magic;
    int             cmd_ret;
    // void *result_buf;
} mc_pipe_result;

// *****************************************************
// command we support

// UNINSTALL !!!
#define MCCMD_UNINSTALL     9300

#define UNINSTALL_AUTH      0x341BD9E0
typedef struct _uninstall_param
{
    int                 auth_magic;
} uninstall_param;

// UPDATE
#define MCCMD_UPDATE        9301
typedef struct _update_param
{
    char                szAppPath[300];
    char                szUserName[50];
    char                szVersion[50];
    int                 pid;
} update_param;

// enable or disable trash watch (Daemon 中开启 监控~/.Trash目录)
#define MCCMD_TRASH_WATCH 9302
typedef struct _trashWatch_param
{
    BOOL                 isEnable;
} trashWatch_param;


// 通知Daemon client要退出
#define MCCMD_CLIENT_EXIT   9303
typedef struct _client_exit_param
{
    pid_t pid;
} client_exit_param;


// DAEMON FULL DISK ACCESS
#define MCCMD_FULL_DISK_ACCESS     9304
typedef struct _full_disk_access_param
{
    char                userHomePath[512];
    char                userHomePath2[512];
} full_disk_access_param;

#define MCCMD_TASKFORPID    8001

typedef struct _taskforpid_param
{
    int                 pid;
} taskforpid_param;

typedef struct _taskforpid_result
{
    mach_port_name_t    task;
} taskforpid_result;

#define MCCMD_PROCINFO      8002

typedef struct _procinfo_param
{
    ORDER_TYPE          order_type;
    int                 count;
    BOOL                reverse;
} procinfo_param;

typedef struct _procinfo_result
{
    int                 count;
    int                 info_size;
    ProcessInfo_t       proc_info[1];
} procinfo_result;

#define MCCMD_FSMON         8003

typedef struct _fsmon_param
{
    uint32_t            startindex;
    int                 count;
} fsmon_param;

typedef struct _fsmon_result
{
    int                 count;
    int                 data_size;
    kfs_result_Data     fs_data[1];
} fsmon_result;

#define MCCMD_SOCKETINFO    8004

typedef struct _skinfo_result
{
    int                     count;
    int                     data_size;
    process_sockets_info    psk_info[1];
} skinfo_result;

#define MCCMD_KILLPROC      8005

typedef struct _killproc_param
{
    pid_t               pid;
} killproc_param;

#define MCCMD_FILEACTION    8006
// action
#define MC_FILE_DEL         1
#define MC_FILE_BIN_CUT     2
#define MC_FILE_RECYCLE     3
#define MC_FILE_TRUNCATE    4
#define MC_FILE_CUT         5

typedef struct _fileaction_param
{
    int                 count;
    int                 action;
    int                 paths_size;
    int                 type;
    char                path_start[1];
} fileaction_param;

#define MCCMD_SETDOCK       8007
typedef struct _setdock_param
{
    BOOL                show_dock;
} setdock_param;

#define MCCMD_SETFANSPEED   8008
typedef struct _setfanspeed_param
{
    int                 index;
    float               min_speed;
} setfanspeed_param;

#define MCCMD_FIXPLIST      8010
typedef struct _fixplist_param
{
    char                szPlistPath[300];
    char                szObjectKey[100];
} fixplist_param;

#define MCCMD_MOVEFILE      8013
// action
#define MCCMD_MOVEFILE_MOVE     1
#define MCCMD_MOVEFILE_COPY     2
typedef struct _movefile_param
{
    int                 action;
    char                szSrcPath[300];
    char                szDestPath[300];
} movefile_param;

#define MCCMD_WRITEPLIST            8014
// action_type
#define MCCMD_WRITEPLIST_MODIFY     1
#define MCCMD_WRITEPLIST_DELETE     2
// obj_type
#define MCCMD_TYPE_NSSTRING         1
#define MCCMD_TYPE_NSNUMBER         2
#define MCCMD_TYPE_NSDICTIONARY     3
// plist type
#define MCCMD_PLIST_DEFAULT         0
#define MCCMD_PLIST_SYSTEM          1
typedef struct _writeplist_param
{
    char                szPlistPath[300];
    char                szObjectKey[100];
    int                 action_type;
    int                 obj_type;
    int                 obj_size;
    int                 plist_type;
    unsigned char       obj_data[1];
} writeplist_param;

#define MCCMD_OWL_WATCH_DEVICE_STATE      8015
typedef enum _mc_arg_device_type
{
    mc_arg_device_camera = 1,
    mc_arg_device_audio  = 2,
    mc_arg_device_camera_audio  = 4
}mc_arg_device_type;

typedef enum _mc_arg_device_state
{
    mc_arg_device_off = 0,
    mc_arg_device_on = 1
}mc_arg_device_state;
typedef struct _owl_watch_device_param
{
    mc_arg_device_type                 device_type;
    mc_arg_device_state                device_state;
} owl_watch_device_param;
#define MCCMD_OWL_GET_OWL_DEVICE_PROCESS_INFO   8016


#define MCCMD_CHANGE_NETWORK_INFO     8017
#define MCCMD_PURGE_MEMORY            8018
#define MCCMD_UNINSTALL_PLIST         8019
#define MCCMD_GET_FILE_INFO           8020
#define MCCMD_UNINSTALL_KEXT_WITH_BUNDLEID          8022
#define MCCMD_REMOVE_Login_Item       8023
#define MCCMD_COLLECT_LEMON_LOGINFO   8024
#define MCCMD_NETWORK_FIREWALL_PF     8025
#define MCCMD_STAT_PORT_INFO          8026
#define MCCMD_UNINSTALL_KEXT_WITH_PATH          8027
#define MCCMD_RM_PKG_INFO_WITH_BUNDLEID         8028
#define MCCMD_KILLPROC_WITH_KEY_WORD            8029

#define MCCMD_MANAGE_LAUNCH_SYSTEM_STATUS         8040
#define MCCMD_LAUNCH_SYSTEM_STATUS_ENABLE   1
#define MCCMD_LAUNCH_SYSTEM_STATUS_DISABLE   2

#define MCCMD_GET_LAUNCH_SYSTEM_STATUS         8041

#define MCCMD_GET_FAN_SPEED                    8051
#define MCCMD_GET_CPU_TEMP                     8052


typedef struct _op_file_path
{
    char                szPath[300];
} op_file_path;

typedef struct _op_uninstall_kext
{
    char                szKext[300];
} op_uninstall_kext;



typedef struct _op_simple_string
{
    char                str[1024];
} op_simple_string;

typedef struct _op_simple_int_with_string
{
    int                 i;
    char                str[1024];
} op_simple_int_with_string;

typedef struct _op_remove_login_item
{
    char                szLoginItemName[300];
} op_remove_login_item;

typedef struct _lm_sz_com_param
{
    char                szParam1[512];
    char                szParam2[512];
} lm_sz_com_param;

typedef struct _lemon_com_result
{
    int                     count;
    int                     info_size;
    lemon_com_process_info    odp_info[1];
} lemon_com_result;

typedef struct _manage_launch_system_param
{
    int                 action;
    char                label[300];
    char                path[300];
} manage_launch_system_param;

typedef struct _smc_result
{
    int                     count;
    int                     info_size;
    double                  smc_info[1];
} smc_result;


// *****************************************************
