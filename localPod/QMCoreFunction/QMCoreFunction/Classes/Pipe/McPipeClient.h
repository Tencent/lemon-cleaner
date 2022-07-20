// pipe header file for client

#import "McPipeStruct.h"

// init pipes
void init_pipes(void);


// 通知Daemon client要退出
int dm_notifly_client_exit(pid_t clientPid);

// uninstall castle !!!
int dm_uninstall_all(void);

// update app
int dm_update(const char *szNewApp, const char *version);

// 是否开启应用残留检测
int dm_trash_watch_enable(BOOL isEnable);

// execute a command through pipe
int executePipeCommand(NSString *path, 
                       mc_pipe_cmd *pcmd, 
                       mc_pipe_result **ppresult);

// just used for test
//int dm_task_for_pid(int pid, mach_port_name_t *task);

// get process information
int dm_get_process_info(ORDER_TYPE orderType, 
                        int count, 
                        BOOL isReverse, 
                        ProcessInfo_t **pproc);

// get file system monitor event
int dm_get_fsmon_event(unsigned int startno,
                       int count,
                       kfs_result_Data *outdata);

// get process sockets information
int dm_get_process_socket_info(process_sockets_info **proc_sk_info);

// kill process
int dm_kill_process(pid_t pid);

// file action
int dm_file_action(int action, int count, char *file_paths, int size);

// set dock show
int dm_dock_show(BOOL show);

// set fan speed
int dm_set_fan_speed(int index, float min_speed);

// fix an info.plist file
int dm_fix_plist(const char *szPlistPath, const char *szKey);

// load kernel externsion
int dm_load_kext(const char *kextPath);

// unload kernel extension
int dm_unload_kext(const char *kextBundle);

// move file to other path
int dm_moveto_file(const char *srcPath, const char *dstPath, int action);

// modify a plist file
int dm_modify_plist_file(const char *szPath,
                         const char *szKeyName,
                         int action_type,
                         int obj_type,
                         int plist_type,
                         const void *obj_data,
                         int obj_size);

// change owl device state
int change_owl_device_proc_info(int device_type,
                                int device_state);
// get owl device process info
int get_owl_device_proc_info(int device_type,
                             int device_state,
                             lemon_com_process_info **odp_proc_info);

// changeNetworkInfo is chmod 644 /dev/bpf* for get network info
int changeNetworkInfo(void);

// purgeMemory
int purgeMemory(void);

// unInstallPlist
int unInstallPlist(const char *plist);
