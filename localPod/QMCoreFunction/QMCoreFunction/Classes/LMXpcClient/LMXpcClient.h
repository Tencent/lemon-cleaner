//
//  LMXpcClient.h
//  AFNetworking
//
//  
//

#import "McPipeStruct.h"

typedef struct
{
    CFAbsoluteTime add_time;
    CFAbsoluteTime start_time;
    CFAbsoluteTime end_time;
    CFAbsoluteTime overtime;  //超时时间
}xpc_operation;

typedef void(^block_v_i)(int);
typedef void(^block_v_i_proc)(int,ProcessInfo_t*);
typedef void(^block_v_i_kfs)(int,kfs_result_Data *);

void init_xpc(void);

// uninstall castle !!!  sync
int _dm_uninstall_all(void);
void _dm_uninstall_all_async(block_v_i block);

int _full_disk_access(const char *userHomePath, const char *userHomePath2);

// kill process
int _dm_kill_process(pid_t pid);
void _dm_kill_process_async(pid_t pid, block_v_i block);

int _dm_kill_process_with_keyword(pid_t pid, const char *keyword);
void _dm_kill_process_with_keyword_async(pid_t pid,  const char *keyword,  block_v_i block);

int _dm_cut_action(int action, int count, char *file_paths, int size, int arch);

// file action
int _dm_file_action(int action, int count, char *file_paths, int size);
void _dm_file_action_async(int action, int count, char *file_paths, int size, block_v_i block);

// move file
int _dm_moveto_file(const char *srcPath, const char *dstPath, int action);
void _dm_moveto_file_async(const char *srcPath, const char *dstPath, int action, block_v_i block);


// update app
int _dm_update(const char *szNewApp, const char *version);
void _dm_update_async(const char *szNewApp, const char *version, block_v_i block);


// process info
void _dm_get_process_info_aysnc(ORDER_TYPE orderType,
                                int count,
                                BOOL isReverse,
                                block_v_i_proc block);

int _dm_get_process_info(ORDER_TYPE orderType,
                         int count,
                         BOOL isReverse,
                         ProcessInfo_t **pproc);

// fsmon event
int _dm_get_fsmon_event(unsigned int start_index,
                        int count,
                        kfs_result_Data *outdata);

void _dm_get_fsmon_event_aysnc(unsigned int start_index,
                               int count,
                               kfs_result_Data *outdata,
                               block_v_i block);


// client exit
int _dm_notifly_client_exit(pid_t clientPid);
void _dm_notifly_client_exit_async(pid_t clientPid, block_v_i block);


// set fan speed
int _dm_set_fan_speed(int index, float min_speed);
void _dm_set_fan_speed_async(int index, float min_speed, block_v_i block);

void _dm_get_fan_speed_async(unsigned int start_index,
                             int count,
                             double *outdata,
                             block_v_i block);
void _dm_get_cpu_temperature_async(unsigned int start_index,
                                   int count,
                                   double *outdata,
                                   block_v_i block);

//fix an info.plist file
int _dm_fix_plist(const char *szPlistPath, const char *szKey);

// modify a plist file
int _dm_modify_plist_file(const char *szPath,
                          const char *szKeyName,
                          int action_type,
                          int obj_type,
                          int plist_type,
                          const void *obj_data,
                          int obj_size);


// 摄像头或音频接口
int _change_owl_device_proc_info(int device_type, int device_state);
void _change_owl_device_proc_info_async(int device_type, int device_state, block_v_i block);

int _get_owl_device_proc_info(int device_type,
                              int device_state,
                              lemon_com_process_info **odp_proc_info);
void _get_owl_device_proc_info_async(int device_type,
                                     int device_state,
                                     lemon_com_process_info **odp_proc_info,
                                     block_v_i block);


int _changeNetworkInfo(void);
void _changeNetworkInfoAsync(block_v_i block);


int _purgeMemory(void);
void _purgeMemoryAsync(block_v_i block);

int _unInstallPlist(const char *plist);
void _unInstallPlistAsync(const char *plist, block_v_i block);

int _getFileInfo(const char *filePath, get_file_info **file_info);
void _getFileInfoAsync(const char *filePath, get_file_info **file_info, block_v_i block);

int _dm_uninstall_kext_with_bundleId(const char *kext);
void _dm_uninstall_kext_with_bundleId_async(const char *kext, block_v_i block);

int _dm_uninstall_kext_with_path(const char *kext);
void _dm_uninstall_kext_with_path_async(const char *kext, block_v_i block);


int _dm_rm_pkg_info_with_bundleId(const char *kext);
void _dm_rm_pkg_info_with_bundleId_async(const char *kext, block_v_i block);

int _dm_remove_login_item(const char *loginItem);
void _dm_remove_login_item_async(const char *loginItem, block_v_i block);

//get lemon loginfo
int _collect_lemon_loginfo(const char *userName);
void _collect_lemon_loginfo_async(const char *userName, block_v_i block);

//pf is control the ipfw(or iptable)
int _set_lemon_firewall_port_pf(const char *srcTcpPort, const char *srcUdpPort);
void _set_lemon_firewall_port_pf_async(const char *srcTcpPort, const char *srcUdpPort, block_v_i block);

// stat port using info(through lsof)
int _stat_port_proc_info(lemon_com_process_info **odp_proc_info);
void _stat_port_proc_info_async(lemon_com_process_info **odp_proc_info, block_v_i block);

int _manageLaunchSystemStatus(const char *path, const char *label, int action);
void _manageLaunchSystemStatusAsync(const char *path, const char *label, int action, block_v_i block);

int _getLaunchSystemStatus(const char *label);
