//
//  LMXpcClient.m
//  AFNetworking
//
//  
//

#import "LMXpcClient.h"
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/errno.h>
#import <sys/types.h>
#import <sys/mman.h>
#import <semaphore.h>
#import "LMXpcClientManager.h"


#define XPC_OVER_TIME  5
// mark: 函数声明
int executeXPCCommandQueueSync(mc_pipe_cmd *pcmd,
                               mc_pipe_result **ppresult,
                               xpc_operation *operation);

void executeXPCCommandQueueAsync(mc_pipe_cmd *pcmd,
                                 mc_pipe_result **ppresult,
                                 xpc_operation *operation,
                                 void(^result_block)(int));

dispatch_queue_t xpcSyncQueue; //同步异步队列
dispatch_queue_t xpcAsyncQueue;

void init_xpc(void){
    xpcSyncQueue = dispatch_queue_create("lemon_xpc_to_daemon_sync", DISPATCH_QUEUE_SERIAL);
    xpcAsyncQueue = dispatch_queue_create("lemon_xpc_to_daemon_async", DISPATCH_QUEUE_SERIAL);
}

void clean_after(mc_pipe_cmd *pcmd, mc_pipe_result *presult, xpc_operation *poperation)
{
    if(pcmd != NULL){
        free(pcmd);
    }
    if(presult != NULL){
        free(presult);
    }
    if(poperation != NULL){
        free(poperation);
    }
}

void operation_prepare(xpc_operation **ppoperation){
    
    xpc_operation * poperation = malloc(sizeof(xpc_operation));
    memset(poperation, 0, sizeof(xpc_operation));
    
    poperation->add_time = CFAbsoluteTimeGetCurrent();
    poperation->overtime = XPC_OVER_TIME;
    *ppoperation = poperation;
}

//封装普通的 return_data(只简单的取mc_pipe_result的cmd_ret当做返回值)
static int pack_normal_return_data(mc_pipe_cmd *pcmd, mc_pipe_result *presult,xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL)
    {
        clean_after(pcmd, presult, poperation);
        return -1;
    }
    
    int ret = presult->cmd_ret;
    clean_after(pcmd, presult, poperation);
    return ret;
}

static int pack_lemon_com_proc_info(lemon_com_process_info **odp_proc_info, mc_pipe_cmd *pcmd, mc_pipe_result *presult, xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL )
    {
        clean_after(pcmd, presult, poperation);
        return -1;
    }
    
    // get procinfo list
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        lemon_com_result *pcmd_result = (lemon_com_result *)(presult + 1);
        lemon_com_process_info *pinfo = (lemon_com_process_info *)malloc(pcmd_result->info_size);
        memcpy(pinfo, pcmd_result->odp_info, pcmd_result->info_size);
        
        *odp_proc_info = pinfo;
    }
    
    clean_after(pcmd, presult, poperation);
    return ret;
}
static void normal_cmd_prepare(int cmd_magic, mc_pipe_cmd ** ppcmd, xpc_operation **ppoperation) {
    // total size
    int cmd_size = sizeof(mc_pipe_cmd);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = cmd_magic;
    *ppcmd =  pcmd;
    
    operation_prepare(ppoperation);
}

// mark: unistall all  start...................


void uninstall_prepare(mc_pipe_cmd **ppcmd, xpc_operation **ppoperation)
{
    uninstall_param param;
    param.auth_magic = UNINSTALL_AUTH;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(uninstall_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UNINSTALL;
    memcpy(pcmd + 1, &param, sizeof(uninstall_param));
    
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _dm_uninstall_all(void)
{
    mc_pipe_cmd *pcmd = NULL; // malloc
    xpc_operation *operation = NULL; // stack var
    uninstall_prepare(&pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult ,operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}


void _dm_uninstall_all_async(block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL; // malloc
    xpc_operation *operation = NULL; // stack var
    uninstall_prepare(&pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
    
}

// mark : full disk access
void full_disk_access_prepare(const char *userHomePath, const char *userHomePath2, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation)
{
    full_disk_access_param param;
    strncpy(param.userHomePath, userHomePath, sizeof(param.userHomePath) - 1);
    strncpy(param.userHomePath2, userHomePath2, sizeof(param.userHomePath2) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(full_disk_access_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FULL_DISK_ACCESS;
    memcpy(pcmd + 1, &param, sizeof(full_disk_access_param));
    
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

// 判断守护进程是否有完全磁盘访问权限
int _full_disk_access(const char *userHomePath, const char *userHomePath2) {
    mc_pipe_cmd *pcmd = NULL; // malloc
    xpc_operation *operation = NULL; // stack var
    full_disk_access_prepare(userHomePath, userHomePath2, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult ,operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}


// mark : kill process
void kill_process_prepare(pid_t pid,mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    killproc_param param;
    param.pid = pid;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(killproc_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_KILLPROC;
    memcpy(pcmd + 1, &param, sizeof(killproc_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}


// kill process
int _dm_kill_process(pid_t pid)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    kill_process_prepare(pid, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_kill_process_async(pid_t pid, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    kill_process_prepare(pid, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}



// mark : kill process with keyword
void kill_process_with_keyword_prepare(pid_t pid, const char *keyword, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    op_simple_int_with_string param = {0};
    param.i = pid;
    strncpy(param.str, keyword, sizeof(param.str) - 1);

    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_simple_int_with_string);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_KILLPROC_WITH_KEY_WORD;
    memcpy(pcmd + 1, &param, sizeof(op_simple_int_with_string));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}


// kill process
int _dm_kill_process_with_keyword(pid_t pid, const char *keyword)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    kill_process_with_keyword_prepare(pid, keyword, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_kill_process_with_keyword_async(pid_t pid, const char *keyword,  block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    kill_process_with_keyword_prepare(pid, keyword, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// mark: file action
void file_action_prepare(int action, int count, char *file_paths, int size, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation ){
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fileaction_param) + size - 1; // -1 是因为fileaction_param的path_start 相当于不占空间. 直接作为后面的file_paths的起始地址.
    
    // 整体的数据结构如下:
    // mc_pipe_cmd
    // fileaction_param
    // [file_str 数组]  strings 之间以一个 \0 作为分隔. count 记录 strings 的数量. 注意的是. file_strs的起始位置是fileaction_param->fileaction_param,而不是紧跟在
    // fileaction_param之后.
    
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FILEACTION;
    
    fileaction_param *param = (fileaction_param *)(pcmd + 1);
    param->action = action;
    param->count = count;
    param->paths_size = size;
    memcpy(param->path_start, file_paths, size);
    
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    ;
}


// 文件操作(删除等). action:操作类型. count: 文件路径的数量. file_paths:多个文件路径合并成一条 string.(互相以\0分割), size: file_paths 这个 char*数组的长度.s
int _dm_file_action(int action, int count, char *file_paths, int size)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    file_action_prepare(action, count, file_paths, size, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

static void cut_action_prepare(int action, int count, char *file_paths, int size, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation ,int arch) {
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fileaction_param) + size - 1; // -1 是因为fileaction_param的path_start 相当于不占空间. 直接作为后面的file_paths的起始地址.

    // 整体的数据结构如下:
    // mc_pipe_cmd
    // fileaction_param
    // [file_str 数组]  strings 之间以一个 \0 作为分隔. count 记录 strings 的数量. 注意的是. file_strs的起始位置是fileaction_param->fileaction_param,而不是紧跟在
    // fileaction_param之后.

    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);

    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FILEACTION;

    fileaction_param *param = (fileaction_param *)(pcmd + 1);
    param->action = action;
    param->count = count;
    param->type = arch;
    param->paths_size = size;
    memcpy(param->path_start, file_paths, size);

    *ppcmd = pcmd;
    operation_prepare(ppoperation);
    ;
}

int _dm_cut_action(int action, int count, char *file_paths, int size, int arch)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    cut_action_prepare(action, count, file_paths, size, &pcmd, &operation, arch);

    __block mc_pipe_result *presult = NULL;
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _dm_file_action_async(int action, int count, char *file_paths, int size, block_v_i block){
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    file_action_prepare(action, count, file_paths, size, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}


//  move file
static void moveto_file_prepare(mc_pipe_cmd ** ppcmd ,int action, const char *dstPath, const char *srcPath, xpc_operation **ppoperation) {
    movefile_param param = {0};
    param.action = action;
    strncpy(param.szSrcPath, srcPath, sizeof(param.szSrcPath) - 1);
    strncpy(param.szDestPath, dstPath, sizeof(param.szDestPath) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(movefile_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_MOVEFILE;
    memcpy(pcmd + 1, &param, sizeof(movefile_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}


int _dm_moveto_file(const char *srcPath, const char *dstPath, int action)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    moveto_file_prepare(&pcmd, action, dstPath, srcPath, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _dm_moveto_file_async(const char *srcPath, const char *dstPath, int action, block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    moveto_file_prepare(&pcmd, action, dstPath, srcPath, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
    
}


// mark: update app
int update_parpare(const char *szNewApp, const char *version, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation)
{
    const char *szUserName = [NSUserName() UTF8String];
    if (szNewApp == NULL || version == NULL || szUserName == NULL)
        return -1;
    
    update_param param;
    strncpy(param.szAppPath, szNewApp, sizeof(param.szAppPath) - 1);
    strncpy(param.szVersion, version, sizeof(param.szVersion) - 1);
    strncpy(param.szUserName, szUserName, sizeof(param.szUserName) - 1);
    param.pid = getpid();
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(update_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UPDATE;
    memcpy(pcmd + 1, &param, sizeof(update_param));
    
    *ppcmd =pcmd;
    
    operation_prepare(ppoperation);
    
    return 1;
}


int _dm_update(const char *szNewApp, const char *version)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    int success = update_parpare(szNewApp, version, &pcmd, &operation);
    if(success < 0){
        return -1;
    }
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_update_async(const char *szNewApp, const char *version, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    int success = update_parpare(szNewApp, version, &pcmd, &operation);
    if(success < 0){
        block(- 1);
    }
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
    
}

// mark: process info
void get_process_info_prepare(ORDER_TYPE orderType, int count, BOOL isReverse, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation)
{
    // parameter
    procinfo_param param;
    param.order_type = orderType;
    param.count = count;
    param.reverse = isReverse;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(procinfo_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_PROCINFO;
    memcpy(pcmd + 1, &param, sizeof(procinfo_param));
    
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}

// 传 ** 的意义:  因为方法调用是值传递. 如果想修改 原值,需要 传入地址.  比如 int a = 0, 在另一个方法中调用 需传入 &a.
// 而对于 未初始化的结构体. 想在方法中进行初始化, 那么 需要修改的是 结构体的指针地址(int 类型). 而这个指针地址为了保证被修改,那么必须传入这个指针地址的指针. 否则 调用的方法中内部的修改对外部无效.
// 这里有个专有名词  : 参数作为返回值.
// 判断一个 指针 p == NULL, 相当于判断 p 这个变量的值是不是0.

static int pack_process_info(mc_pipe_cmd *pcmd, ProcessInfo_t **pproc, mc_pipe_result *presult, xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL){
        clean_after(pcmd, presult, poperation);
        return -1;
    }else{
        // get procinfo list
        int ret = presult->cmd_ret;
        if (ret > 0)
        {
            procinfo_result *pcmd_result = (procinfo_result *)(presult + 1);
            ProcessInfo_t *pinfo = (ProcessInfo_t *)malloc(pcmd_result->info_size);
            memcpy(pinfo, pcmd_result->proc_info, pcmd_result->info_size);
            
            *pproc = pinfo;
        }
        clean_after(pcmd, presult, poperation);
        return return_code;
        
    }
}

int _dm_get_process_info(ORDER_TYPE orderType,
                         int count,
                         BOOL isReverse,
                         ProcessInfo_t **pproc)
{
    if (pproc == NULL)
        return -1;
    
    
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    get_process_info_prepare(orderType, count, isReverse, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    
    return pack_process_info(pcmd, pproc, presult, operation, return_code);
    
}

void _dm_get_process_info_aysnc(ORDER_TYPE orderType,
                                int count,
                                BOOL isReverse,
                                block_v_i_proc block)
{
    
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    get_process_info_prepare(orderType, count, isReverse, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        ProcessInfo_t *pproc = NULL;
        return_code = pack_process_info(pcmd, &pproc, presult, operation, return_code);
        block(return_code, pproc);
    };
    
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
    
}

// client exit
static void client_exit_prepare(mc_pipe_cmd **ppcmd, pid_t clientPid, xpc_operation **ppoperation) {
    client_exit_param param;
    param.pid = clientPid;
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(client_exit_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_CLIENT_EXIT;
    memcpy(pcmd + 1, &param, sizeof(client_exit_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}



int _dm_notifly_client_exit(pid_t clientPid) {
    
    xpc_operation *operation = NULL;
    mc_pipe_cmd * pcmd = NULL;
    client_exit_prepare(&pcmd, clientPid, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _dm_notifly_client_exit_async(pid_t clientPid,  block_v_i block) {
    
    xpc_operation *operation = NULL;
    mc_pipe_cmd * pcmd = NULL;
    client_exit_prepare(&pcmd, clientPid, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// fsmon_event
void fsmon_event_prepare(int count, unsigned int start_index, mc_pipe_cmd ** ppcmd, xpc_operation **ppoperation) {
    fsmon_param param;
    param.count = count;
    param.startindex = start_index;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fsmon_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FSMON;
    memcpy(pcmd + 1, &param, sizeof(fsmon_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

static int pack_fsmon_event(int count, kfs_result_Data *outdata, mc_pipe_cmd *pcmd, mc_pipe_result *presult, xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL)
    {
        clean_after(pcmd, presult, poperation);
        return -1;
    }
    
    
    // get event
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        fsmon_result *fs_result = (fsmon_result *)(presult + 1);
        if (ret > count
            || fs_result->data_size > count * sizeof(kfs_result_Data))
        {
            free(presult);
            return -1;
        }
        
        memcpy(outdata, fs_result->fs_data, fs_result->data_size);
    }
    
    clean_after(pcmd, presult, poperation);
    return ret;
}

int _dm_get_fsmon_event(unsigned int start_index,
                        int count,
                        kfs_result_Data *outdata)
{
    if (outdata == NULL || count == 0)
        return -1;
    
    mc_pipe_cmd * pcmd = NULL;
    xpc_operation *operation = NULL;
    fsmon_event_prepare(count, start_index, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    
    return pack_fsmon_event(count, outdata, pcmd, presult, operation, return_code);
}



void _dm_get_fsmon_event_aysnc(unsigned int start_index,
                               int count,
                               kfs_result_Data *outdata,  // outdata 本身是个堆指针. 不用考虑 __block 的问题.
                               block_v_i block)
{
    if (outdata == NULL || count == 0)
        block(-1);
    
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    fsmon_event_prepare(count, start_index, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_fsmon_event(count, outdata, pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}



// set fan speed
static void set_fan_speed_prepare(mc_pipe_cmd **ppcmd , int index, float min_speed, xpc_operation **ppoperation) {
    setfanspeed_param param;
    param.index = index;
    param.min_speed = min_speed;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(setfanspeed_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    (pcmd)->size = cmd_size;
    (pcmd)->cmd_magic = MCCMD_SETFANSPEED;
    memcpy(pcmd + 1, &param, sizeof(setfanspeed_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _dm_set_fan_speed(int index, float min_speed)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    set_fan_speed_prepare(&pcmd, index, min_speed, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_set_fan_speed_async(int index, float min_speed, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    set_fan_speed_prepare(&pcmd, index, min_speed, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

static int pack_dm_fan_event(int count, double *outdata, mc_pipe_cmd *pcmd, mc_pipe_result *presult, xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL)
    {
        clean_after(pcmd, presult, poperation);
        return -1;
    }
    
    
    // get event
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        smc_result *fs_result = (smc_result *)(presult + 1);
        if (ret > count
            || fs_result->info_size > count * sizeof(double))
        {
            free(presult);
            return -1;
        }
        
        memcpy(outdata, fs_result->smc_info, fs_result->info_size);
    }
    
    clean_after(pcmd, presult, poperation);
    return ret;
}

void dm_smc_event_prepare(int count, unsigned int start_index, int magic, mc_pipe_cmd ** ppcmd, xpc_operation **ppoperation) {
    fsmon_param param;
    param.count = count;
    param.startindex = start_index;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fsmon_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = magic;
    memcpy(pcmd + 1, &param, sizeof(fsmon_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

void _dm_get_fan_speed_async(unsigned int start_index,
                             int count,
                             double *outdata,
                             block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    dm_smc_event_prepare(count, start_index, MCCMD_GET_FAN_SPEED, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_dm_fan_event(count, outdata, pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

void _dm_get_cpu_temperature_async(unsigned int start_index,
                                   int count,
                                   double *outdata,
                                   block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    dm_smc_event_prepare(count, start_index, MCCMD_GET_CPU_TEMP, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_dm_fan_event(count, outdata, pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

//fix an info.plist file
static void fix_plist_prepare(mc_pipe_cmd ** ppcmd, const char *szKey, const char *szPlistPath, xpc_operation **ppoperation) {
    fixplist_param param = {0};
    strncpy(param.szPlistPath, szPlistPath, sizeof(param.szPlistPath) - 1);
    strncpy(param.szObjectKey, szKey, sizeof(param.szObjectKey) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fixplist_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FIXPLIST;
    memcpy(pcmd + 1, &param, sizeof(fixplist_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _dm_fix_plist(const char *szPlistPath, const char *szKey)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    fix_plist_prepare(&pcmd, szKey, szPlistPath, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}



static void modify_plist_file_prepare(mc_pipe_cmd ** ppcmd, int action_type, const void *obj_data, int obj_size, int obj_type, int plist_type, const char *szKeyName, const char *szPath,xpc_operation **ppoperation) {
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(writeplist_param) + obj_size - 1;
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_WRITEPLIST;
    
    writeplist_param *param = (writeplist_param *)(pcmd + 1);
    strncpy(param->szPlistPath, szPath, sizeof(param->szPlistPath) - 1);
    strncpy(param->szObjectKey, szKeyName, sizeof(param->szObjectKey) - 1);
    param->action_type = action_type;
    param->plist_type = plist_type;
    param->obj_type = obj_type;
    
    if (obj_size > 0)
    {
        param->obj_size = obj_size;
        memcpy(param->obj_data, obj_data, obj_size);
    }
    else
    {
        param->obj_size = 0;
    }
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

// modify a plist file
int _dm_modify_plist_file(const char *szPath,
                          const char *szKeyName,
                          int action_type,
                          int obj_type,
                          int plist_type,
                          const void *obj_data,
                          int obj_size)
{
    // total size
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    modify_plist_file_prepare(&pcmd, action_type, obj_data, obj_size, obj_type, plist_type, szKeyName, szPath, &operation);
    
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}


// change owl device state
static void change_owl_device_proc_info_prepare(mc_pipe_cmd ** ppcmd, int device_state, int device_type, xpc_operation **ppoperation) {
    owl_watch_device_param param;
    param.device_type = device_type;
    param.device_state = device_state;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(owl_watch_device_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_OWL_WATCH_DEVICE_STATE;
    memcpy(pcmd + 1, &param, sizeof(owl_watch_device_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _change_owl_device_proc_info(int device_type, int device_state)
{
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    change_owl_device_proc_info_prepare(&pcmd, device_state, device_type, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _change_owl_device_proc_info_async(int device_type, int device_state, block_v_i block)
{
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    change_owl_device_proc_info_prepare(&pcmd, device_state, device_type, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// get owl device process info
static void get_owl_device_proc_info_prepare( mc_pipe_cmd ** ppcmd,int device_state, int device_type, xpc_operation **ppoperation) {
    owl_watch_device_param param;
    param.device_type = device_type;
    param.device_state = device_state;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(owl_watch_device_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_OWL_GET_OWL_DEVICE_PROCESS_INFO;
    memcpy(pcmd + 1, &param, sizeof(owl_watch_device_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _get_owl_device_proc_info(int device_type,
                              int device_state,
                              lemon_com_process_info **odp_proc_info)
{
    if (odp_proc_info == NULL)
        return -1;
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_owl_device_proc_info_prepare(&pcmd, device_state, device_type, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_lemon_com_proc_info(odp_proc_info, pcmd, presult, operation, return_code);
}

void _get_owl_device_proc_info_async(int device_type,
                                     int device_state,
                                     lemon_com_process_info **odp_proc_info,
                                     block_v_i block)
{
    if (odp_proc_info == NULL)
        block(-1);
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_owl_device_proc_info_prepare(&pcmd, device_state, device_type, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_lemon_com_proc_info(odp_proc_info, pcmd, presult, operation,return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}


// change network info

int _changeNetworkInfo(void)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_CHANGE_NETWORK_INFO, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _changeNetworkInfoAsync(block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_CHANGE_NETWORK_INFO, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// purgeMemory

int _purgeMemory(void)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_PURGE_MEMORY, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _purgeMemoryAsync(block_v_i block)
{
    mc_pipe_cmd * pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_PURGE_MEMORY, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// enable or disable launchd service
static void manageLaunchSystemStatusPrepare(mc_pipe_cmd **ppcmd, const char *path, const char *label, xpc_operation **ppoperation, int action) {
    manage_launch_system_param param = {0};
    strncpy(param.path, path, sizeof(param.path) - 1);
    strncpy(param.label, label, sizeof(param.label) - 1);
    param.action = action;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(manage_launch_system_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_MANAGE_LAUNCH_SYSTEM_STATUS;
    memcpy(pcmd + 1, &param, sizeof(manage_launch_system_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _manageLaunchSystemStatus(const char *path, const char *label, int action)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    manageLaunchSystemStatusPrepare(&pcmd, path, label, &operation, action);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _manageLaunchSystemStatusAsync(const char *path, const char *label, int action, block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    manageLaunchSystemStatusPrepare(&pcmd, path, label, &operation, action);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

static void getLaunchSystemStatusPrepare(mc_pipe_cmd **ppcmd,const char *label, xpc_operation **ppoperation) {
    op_simple_string param = {0};
    strncpy(param.str, label, sizeof(param.str) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_simple_string);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_GET_LAUNCH_SYSTEM_STATUS;
    memcpy(pcmd + 1, &param, sizeof(op_simple_string));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _getLaunchSystemStatus(const char *label)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    getLaunchSystemStatusPrepare(&pcmd, label, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}


// unInstallPlist
static void unInstallPlistPrepare(mc_pipe_cmd **ppcmd, const char *plist, xpc_operation **ppoperation) {
    op_file_path param = {0};
    strncpy(param.szPath, plist, sizeof(param.szPath) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_file_path);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UNINSTALL_PLIST;
    memcpy(pcmd + 1, &param, sizeof(op_file_path));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

int _unInstallPlist(const char *plist)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    unInstallPlistPrepare(&pcmd, plist, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}

void _unInstallPlistAsync(const char *plist, block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    unInstallPlistPrepare(&pcmd, plist, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

static void get_file_info_prepare(mc_pipe_cmd ** ppcmd, const char *filePath, xpc_operation **ppoperation) {
    op_file_path param = {0};
    strncpy(param.szPath, filePath, sizeof(param.szPath) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_file_path);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_GET_FILE_INFO;
    memcpy(pcmd + 1, &param, sizeof(op_file_path));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

static int pack_get_file_info(get_file_info **file_info, mc_pipe_cmd *pcmd, mc_pipe_result *presult, xpc_operation *poperation, int return_code) {
    if (return_code == -1 || presult == NULL )
    {
        clean_after(pcmd, presult, poperation);
        return -1;
    }
    
    // get procinfo list
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        get_file_info *pinfo = (get_file_info *)malloc(sizeof(get_file_info));
        memcpy(pinfo, (get_file_info *)(presult + 1), sizeof(get_file_info));
        
        *file_info = pinfo;
    }
    
    clean_after(pcmd, presult, poperation);
    return ret;
}
int _getFileInfo(const char *filePath, get_file_info **file_info)
{
    if (file_info == NULL)
        return -1;
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_file_info_prepare(&pcmd, filePath, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_get_file_info(file_info, pcmd, presult, operation, return_code);
}

void _getFileInfoAsync(const char *filePath, get_file_info **file_info, block_v_i block)
{
    if (file_info == NULL)
        block(-1);
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_file_info_prepare(&pcmd, filePath, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_get_file_info(file_info, pcmd, presult, operation,return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}


// mark : uninstall kext with bundle id
void uninstall_kext_with_bundleId_prepare(const char *kext, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    op_uninstall_kext param = {0};
    strncpy(param.szKext, kext, sizeof(param.szKext) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_uninstall_kext);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UNINSTALL_KEXT_WITH_BUNDLEID;
    memcpy(pcmd + 1, &param, sizeof(op_uninstall_kext));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}


//  uninstall kext with bundle id
int _dm_uninstall_kext_with_bundleId(const char *kext)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    uninstall_kext_with_bundleId_prepare(kext, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_uninstall_kext_with_bundleId_async(const char *kext, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    uninstall_kext_with_bundleId_prepare(kext, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}


// mark : uninstall kext with path
void uninstall_kext_with_path_prepare(const char *kext, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    op_uninstall_kext param = {0};
    strncpy(param.szKext, kext, sizeof(param.szKext) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_uninstall_kext);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UNINSTALL_KEXT_WITH_PATH;
    memcpy(pcmd + 1, &param, sizeof(op_uninstall_kext));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}

//  uninstall kext with path
int _dm_uninstall_kext_with_path(const char *kext)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    uninstall_kext_with_path_prepare(kext, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_uninstall_kext_with_path_async(const char *kext, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    uninstall_kext_with_path_prepare(kext, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}




//MARK: remove pkg info
void rm_pkg_info_with_path_prepare(const char *kext, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    op_simple_string param = {0};
    strncpy(param.str, kext, sizeof(param.str) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_simple_string);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_RM_PKG_INFO_WITH_BUNDLEID;
    memcpy(pcmd + 1, &param, sizeof(op_simple_string));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}

//  rm pkginfo with path
int _dm_rm_pkg_info_with_bundleId(const char *bundleId)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    rm_pkg_info_with_path_prepare(bundleId, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_rm_pkg_info_with_bundleId_async(const char *bundleId, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    rm_pkg_info_with_path_prepare(bundleId, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}





// mark : remove login item
void remove_login_item_prepare(const char *loginItem, mc_pipe_cmd **ppcmd, xpc_operation **ppoperation){
    op_remove_login_item param = {0};
    strncpy(param.szLoginItemName, loginItem, sizeof(param.szLoginItemName) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_remove_login_item);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_REMOVE_Login_Item;
    memcpy(pcmd + 1, &param, sizeof(op_remove_login_item));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}

// loginItem: 登录项的名字.
int _dm_remove_login_item(const char *loginItem)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    remove_login_item_prepare(loginItem, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
    
}

void _dm_remove_login_item_async(const char *loginItem, block_v_i block)
{
    xpc_operation *operation = NULL;
    mc_pipe_cmd *pcmd = NULL;
    remove_login_item_prepare(loginItem, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

//get lemon loginfo
static void get_lemon_log_info_prepare(mc_pipe_cmd ** ppcmd, const char *homeDir, xpc_operation **ppoperation) {
    op_file_path param = {0};
    strncpy(param.szPath, homeDir, sizeof(param.szPath) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_file_path);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_COLLECT_LEMON_LOGINFO;
    memcpy(pcmd + 1, &param, sizeof(op_file_path));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
}
int _collect_lemon_loginfo(const char *homeDir)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_lemon_log_info_prepare(&pcmd, homeDir, &operation);
    
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}
void _collect_lemon_loginfo_async(const char *homeDir, block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    get_lemon_log_info_prepare(&pcmd, homeDir, &operation);
    
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

//pf is control the ipfw(or iptable)
static void lemon_firewall_port_pf_prepare(mc_pipe_cmd ** ppcmd ,const char *srcTcpPort, const char *srcUdpPort, xpc_operation **ppoperation) {
    lm_sz_com_param param = {0};
    strncpy(param.szParam1, srcTcpPort, sizeof(param.szParam1) - 1);
    strncpy(param.szParam2, srcUdpPort, sizeof(param.szParam2) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(lm_sz_com_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_NETWORK_FIREWALL_PF;
    memcpy(pcmd + 1, &param, sizeof(lm_sz_com_param));
    *ppcmd = pcmd;
    
    operation_prepare(ppoperation);
    
}
int _set_lemon_firewall_port_pf(const char *srcTcpPort, const char *srcUdpPort)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    lemon_firewall_port_pf_prepare(&pcmd, srcTcpPort, srcUdpPort, &operation);
    mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_normal_return_data(pcmd, presult, operation, return_code);
}
void _set_lemon_firewall_port_pf_async(const char *srcTcpPort, const char *srcUdpPort, block_v_i block)
{
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    lemon_firewall_port_pf_prepare(&pcmd, srcTcpPort, srcUdpPort, &operation);
    mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_normal_return_data(pcmd, presult, operation, return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
    
}

// stat port using info(through lsof)
int _stat_port_proc_info(lemon_com_process_info **odp_proc_info)
{
    if (odp_proc_info == NULL)
        return -1;
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_STAT_PORT_INFO, &pcmd, &operation);
    __block mc_pipe_result *presult = NULL;
    
    int return_code = executeXPCCommandQueueSync(pcmd, &presult, operation);
    return pack_lemon_com_proc_info(odp_proc_info, pcmd, presult, operation, return_code);
}

void _stat_port_proc_info_async(lemon_com_process_info **odp_proc_info,
                                block_v_i block)
{
    if (odp_proc_info == NULL)
        block(-1);
    
    // parameter
    mc_pipe_cmd *pcmd = NULL;
    xpc_operation *operation = NULL;
    normal_cmd_prepare(MCCMD_STAT_PORT_INFO, &pcmd, &operation);
    operation->overtime = XPC_OVER_TIME;
    __block mc_pipe_result *presult = NULL;
    
    block_v_i copyBlock = ^(int return_code) {
        return_code = pack_lemon_com_proc_info(odp_proc_info, pcmd, presult, operation,return_code);
        block(return_code);
    };
    executeXPCCommandQueueAsync(pcmd, &presult, operation, copyBlock);
}

// mark:  xpc sync  async
int _executeXPCCommand(mc_pipe_cmd *pcmd,
                       mc_pipe_result **ppresult,
                       int overtime)
{
    if (pcmd == NULL){
        return -1;
    }
    NSData *pdata = [NSData dataWithBytes:(void*)pcmd length:pcmd->size];
    NSData *rdata = [[LMXpcClientManager sharedInstance] executeXPCCommandSync:pdata  magic:pcmd->cmd_magic overtime:overtime];
    
    if (nil == rdata) {
        return -1;
    }
    mc_pipe_result *presult = (mc_pipe_result *)[rdata bytes];
    int ret = presult->cmd_ret;
    
    mc_pipe_result *tresult;
    tresult = (mc_pipe_result *)malloc(presult->size);
    memcpy(tresult, presult, presult->size);
    *ppresult = tresult;
    return ret;
}
void _executeXPCCommandAsync(mc_pipe_cmd *pcmd,
                             mc_pipe_result **ppresult,
                             int overtime,
                             block_v_i block)
{
    NSData *pdata = [NSData dataWithBytes:(void*)pcmd length:pcmd->size];
    
    [[LMXpcClientManager sharedInstance] executeXPCCommand:pdata overtime:overtime withReply:^(NSData *rdata) {
        
        int return_code = 0;
        if (nil == rdata) {
            return_code = -1;
        }else{
            NSLog(@"rdata: %lu", (unsigned long)rdata.length);
            mc_pipe_result *presult = (mc_pipe_result *)[rdata bytes];
            return_code = presult->cmd_ret;
            
            mc_pipe_result *tresult;
            tresult = (mc_pipe_result *)malloc(presult->size);
            memcpy(tresult, presult, presult->size);
            *ppresult = tresult;
        }
        
        block(return_code);
    }];
    
}

// return -2 :获取执行权的时候已经超时.
int executeXPCCommandQueueSync(mc_pipe_cmd *pcmd,
                               mc_pipe_result **ppresult,
                               xpc_operation *poperation)
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block int return_code = 0;
    __block bool isComplete = NO;
    NSLock *lock = [[NSLock alloc] init];
    dispatch_async(xpcSyncQueue, ^{
        [lock lock];
        if(isComplete){ //已经超时了, 不应该继续向下运行(executeXPCCommandQueueSync函数已经返回,不再需要封装数据).
            [lock unlock];
            return ;
        }
        // 这里可能会触发问题. 多线程中. 当执行到这句的时候,有可能同时dispatch_semaphore_wait触发(超时后继续运行). 所以通过加锁保证原子性和可见性.
        
        
        // 执行前判断下是否超时.
        poperation->start_time = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime beforeExecuteDuration = poperation->start_time - poperation->add_time;
        if(beforeExecuteDuration > poperation->overtime && beforeExecuteDuration > 0){
            NSLog(@"executeXPCCommandQueueSync stop : wait too much time %f to execute self", beforeExecuteDuration);
            return_code = -2;
            dispatch_semaphore_signal(semaphore);
            [lock unlock];
            return ;
        }
        NSLog(@"_executeXPCCommand");
        return_code = _executeXPCCommand(pcmd, ppresult, poperation->overtime);
        NSLog(@"return_code-->%d",return_code);
        dispatch_semaphore_signal(semaphore);
        isComplete = YES;
        [lock unlock];
        
    });
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(poperation->overtime * NSEC_PER_SEC)));  //有可能超时自动唤醒.这时候还没有执行上面的 block 方法.
    
    [lock lock];
    if(!isComplete){  // 超时返回时
        isComplete = YES;
        return_code = -1;
    }
    
    // 结束时打印下执行时间.
    poperation->end_time = CFAbsoluteTimeGetCurrent();
    //CFAbsoluteTime duration = poperation->end_time - poperation->add_time;
    //NSLog(@"executeXPCCommandQueueSync :execute cost time: %f, add at: %f, start at: %f, end at: %f ",duration, poperation->add_time, poperation->start_time, poperation->end_time);
    
    [lock unlock];
    return return_code;
}


void executeXPCCommandQueueAsync(mc_pipe_cmd *pcmd,
                                 mc_pipe_result **ppresult,
                                 xpc_operation *poperation,
                                 block_v_i block)
// __block 变量不能修饰 参数, 不能修饰 数组. 这里 block 用到的指针必须是指向堆的, 不能是指向栈的
{
    
    dispatch_async(xpcAsyncQueue, ^{
        // 执行前判断下是否超时.
        poperation->start_time = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime beforeExecuteDuration = poperation->start_time - poperation->add_time;
        if(beforeExecuteDuration > poperation->overtime && beforeExecuteDuration > 0){
            NSLog(@"executeXPCCommandQueueAsync stop: wait too much time %f to execute self", beforeExecuteDuration);
            block(-2);
            return ;
        }
        
        _executeXPCCommandAsync(pcmd, ppresult, poperation->overtime, ^(int return_code) {
            block(return_code);
        });
        
        // 结束时打印下执行时间.
        poperation->end_time = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime duration = poperation->end_time - poperation->add_time;
        NSLog(@"executeXPCCommandQueueAsync :execute cost time: %f, add at: %f, start at: %f, end at: %f ",duration, poperation->add_time, poperation->start_time, poperation->end_time);
        
    });
    
}


