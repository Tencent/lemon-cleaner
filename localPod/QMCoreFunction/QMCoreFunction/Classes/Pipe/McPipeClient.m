// implementation of pipe client

#import "McPipeClient.h"
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/errno.h>
#import <sys/types.h>
#import <sys/mman.h>
#import <semaphore.h>
#import "QMDistributedLock.h"
#import "LMXpcClientManager.h"

const char *g_szDaemonPath = "/Library/Application Support/Lemon/LemonDaemon";

int g_mapsize = 1024*1024*2;

// store map address information for each name pipe
// map_read / map_write / fd_read / fd_write / sem_read / sem_write
const int g_elementCount = 6;
NSDictionary *g_mapsDictionary = nil;

// 分配使用情况
// MCPIPE_NAME_FSMON - 清理文件操作、简单快速返回的操作
//  dm_uninstall_all / dm_update / dm_get_fsmon_event / dm_file_action / dm_dock_show / dm_fix_plist / dm_modify_plist_file
//  dm_load_kext / dm_unload_kext / dm_moveto_file
// MCPIPE_NAME_PROC - 查询进程、系统状态等信息
//  dm_get_process_info / dm_get_process_socket_info / dm_kill_process / dm_set_fan_speed
// MCPIPE_NAME_SOCK - 可能会有长等待的操作（例如执行命令）
//  changeNetworkInfo purgeMemory unInstallPlist

// init pipes
void init_pipes(void)
{
    // this function is called by initializer
    // clear all lock files
    
    /*
     2014/12/12 by haotan
     1.以前使用老版本NSDistributedLock时,如果进程A正在加锁,进程B在此处删除锁,那么A和B的互斥被打破
     2.目前使用更安全的QMDistributedLock,更不需要删除文件便能很好的构建进程间的互斥
     NSString *path_lock;
     path_lock = [NSString stringWithFormat:@"%@%@", MCPIPE_NAME_FSMON, MCLOCK_POSTFIX];
     rmdir([path_lock fileSystemRepresentation]);
     path_lock = [NSString stringWithFormat:@"%@%@", MCPIPE_NAME_PROC, MCLOCK_POSTFIX];
     rmdir([path_lock fileSystemRepresentation]);
     path_lock = [NSString stringWithFormat:@"%@%@", MCPIPE_NAME_SOCK, MCLOCK_POSTFIX];
     rmdir([path_lock fileSystemRepresentation]);
     */
    
    if (g_mapsDictionary == nil)
    {
        g_mapsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSMutableArray arrayWithCapacity:g_elementCount], MCPIPE_NAME_FSMON,
                            [NSMutableArray arrayWithCapacity:g_elementCount], MCPIPE_NAME_PROC,
                            [NSMutableArray arrayWithCapacity:g_elementCount], MCPIPE_NAME_SOCK, nil];
    }
}

// get array for certain path
static NSMutableArray *get_maps_array(NSString *path)
{
    return [g_mapsDictionary objectForKey:path];
}

static int init_maps_for_onepipe(NSString *path, void *output_addr[2], sem_t *output_sem[2])
{
    NSString *path_read = [path stringByAppendingString:MCREAD_POSTFIX];
    NSString *path_write = [path stringByAppendingString:MCWRITE_POSTFIX];
    
    // open files
    int fd_write = open([path_read UTF8String], O_RDWR);
    if (fd_write == -1)
    {
        NSLog(@"[err] open pipe file %@ fail: %s", path_read, strerror(errno));
        return -1;
    }
    int fd_read = open([path_write UTF8String], O_RDWR);
    if (fd_read == -1)
    {
        close(fd_write);
        NSLog(@"[err] open pipe file %@ fail: %d", path_write, errno);
        return -1;
    }
    
    // mmap
    void *map_write = mmap(NULL, g_mapsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd_write, 0);
    if (map_write == MAP_FAILED)
    {
        close(fd_read);
        close(fd_write);
        NSLog(@"[err] mmap pipe file %@ fail: %d", path_read, errno);
        return -1;
    }
    void *map_read = mmap(NULL, g_mapsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd_read, 0);
    if (map_read == MAP_FAILED)
    {
        munmap(map_write, g_mapsize);
        close(fd_read);
        close(fd_write);
        NSLog(@"[err] mmap pipe file %@ fail: %d", path_write, errno);
        return -1;
    }
    
    // open semaphore
    NSString *semReadPath = [[path_read lastPathComponent] stringByAppendingString:MCSEM_POSTFIX];
    NSString *semWritePath = [[path_write lastPathComponent]stringByAppendingString:MCSEM_POSTFIX];
    sem_t *sem_read = sem_open([semWritePath UTF8String], 0);
    sem_t *sem_write = sem_open([semReadPath UTF8String], 0);
    if (sem_read == (void *)-1 || sem_write == (void *)-1)
    {
        if (sem_read != (void *)-1) sem_close(sem_read);
        if (sem_write != (void *)-1) sem_close(sem_write);
        munmap(map_read, g_mapsize);
        munmap(map_write, g_mapsize);
        close(fd_read);
        close(fd_write);
        return -1;
    }
    
    // add to array
    NSMutableArray *addrArray = get_maps_array(path);
    if (addrArray == nil)
    {
        sem_close(sem_read);
        sem_close(sem_write);
        munmap(map_read, g_mapsize);
        munmap(map_write, g_mapsize);
        close(fd_read);
        close(fd_write);
        return -1;
    }
    
    [addrArray removeAllObjects];
    [addrArray addObject:[NSNumber valueWithPointer:map_read]];
    [addrArray addObject:[NSNumber valueWithPointer:map_write]];
    [addrArray addObject:[NSNumber numberWithInt:fd_read]];
    [addrArray addObject:[NSNumber numberWithInt:fd_write]];
    [addrArray addObject:[NSNumber valueWithPointer:sem_read]];
    [addrArray addObject:[NSNumber valueWithPointer:sem_write]];
    
    output_addr[0] = map_read;
    output_addr[1] = map_write;
    output_sem[0] = sem_read;
    output_sem[1] = sem_write;
    
    return 0;
}

// close vmmap for path
static void close_maps_for_pipe(NSString *path)
{
    NSMutableArray *addrArray = get_maps_array(path);
    if (addrArray != nil && [addrArray count] == g_elementCount)
    {
        void *map_read = [[addrArray objectAtIndex:0] pointerValue];
        void *map_write = [[addrArray objectAtIndex:1] pointerValue];
        int fd_read = [[addrArray objectAtIndex:2] intValue];
        int fd_write = [[addrArray objectAtIndex:3] intValue];
        sem_t *sem_read = (sem_t *)[[addrArray objectAtIndex:4] pointerValue];
        sem_t *sem_write = (sem_t *)[[addrArray objectAtIndex:5] pointerValue];
        
        munmap(map_read, g_mapsize);
        munmap(map_write, g_mapsize);
        close(fd_read);
        close(fd_write);
        sem_close(sem_read);
        sem_close(sem_write);
        
        [addrArray removeAllObjects];
    }
}

// get vmmap address for certain command path
static int get_maps_for_pipes(NSString *path, void *output_addr[2], sem_t *output_sem[2])
{
    if (output_addr == NULL)
        return -1;
    
    // if we already init, check if still exist
    NSArray *addrArray = get_maps_array(path);
    if (addrArray == nil)
    {
        // wrong name?
        return -1;
    }
    
    if ([addrArray count] == g_elementCount)
    {
        void *map_read = [[addrArray objectAtIndex:0] pointerValue];
        void *map_write = [[addrArray objectAtIndex:1] pointerValue];
        //int fd_read = [[addrArray objectAtIndex:2] intValue];
        //int fd_write = [[addrArray objectAtIndex:3] intValue];
        sem_t *sem_read = (sem_t *)[[addrArray objectAtIndex:4] pointerValue];
        sem_t *sem_write = (sem_t *)[[addrArray objectAtIndex:5] pointerValue];
        
        // check here?
        if (YES)
        {
            // still ok
            output_addr[0] = map_read;
            output_addr[1] = map_write;
            output_sem[0] = sem_read;
            output_sem[1] = sem_write;
            return 0;
        }
    }
    
    // we have to init
    if (init_maps_for_onepipe(path, output_addr, output_sem) == -1)
    {
        return -1;
    }
    
    return 0;
}

int dm_notifly_client_exit(pid_t clientPid) {
    client_exit_param param;
    param.pid = clientPid;
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(client_exit_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_CLIENT_EXIT;
    memcpy(pcmd + 1, &param, sizeof(client_exit_param));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// uninstall castle !!!
int dm_uninstall_all(void)
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// update app
int dm_update(const char *szNewApp, const char *version)
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}
// enable trash watch
int dm_trash_watch_enable(BOOL isEnable)
{
    trashWatch_param param;
    param.isEnable = isEnable;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(trashWatch_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_TRASH_WATCH;
    memcpy(pcmd + 1, &param, sizeof(trashWatch_param));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

static boolean_t g_hasDaemon = FALSE;


// execute a command through xpc
int executeXPCCommand(NSString *path,
                      mc_pipe_cmd *pcmd,
                      mc_pipe_result **ppresult)
{
    NSData *pdata = [NSData dataWithBytes:(void*)pcmd length:pcmd->size];
    NSData *rdata = [[LMXpcClientManager sharedInstance] executeXPCCommandSync:pdata  magic:pcmd->cmd_magic overtime:8];
    
    if (nil == rdata) {
        return -1;
    }
    mc_pipe_result *presult = (mc_pipe_result *)[rdata bytes];
    int ret = presult->cmd_ret;
    
    //*ppresult = malloc(presult->size);
    //memcpy(*ppresult, presult, presult->size);
    
    mc_pipe_result *tresult;
    tresult = (mc_pipe_result *)malloc(presult->size);
    memcpy(tresult, presult, presult->size);
    *ppresult = tresult;
    
    return ret;
}
// execute a command through pipe
int executePipeCommand(NSString *path,
                       mc_pipe_cmd *pcmd,
                       mc_pipe_result **ppresult)
{
    if (pcmd == NULL || ppresult == NULL)
        return -1;
//    return  executeXPCCommand(path, pcmd, ppresult);
    
    BytePtr pAddr = (BytePtr)pcmd;
    int size = pcmd->size - sizeof(mc_pipe_cmd);
    for(int i = sizeof(mc_pipe_cmd); i < size; ++i){
        pAddr[i] = ((pAddr[i]^0x41)^0x7E) + 3;
    }
    
    if (pcmd->size > g_mapsize - 10)
    {
        NSLog(@"[ERR] cmd size to big: %d - %d", pcmd->cmd_magic, pcmd->size);
        return -1;
    }
    
    if (!g_hasDaemon)
    {
        struct stat fileStat = {0};
        if (stat(g_szDaemonPath, &fileStat) == -1)
            return -1;
        g_hasDaemon = TRUE;
    }
    
    NSString *path_lock = [path stringByAppendingString:MCLOCK_POSTFIX];
    // we must have mutex here to prevent multiple process problem
    
    // 2014/12/12 by haotan
    // 由于之前的使用NSDistributedLock在tryLock后退出程序会造成死锁,所以换用安全的QMDistributedLock
    QMDistributedLock *pipeLock = [QMDistributedLock lockWithPath:path_lock];
    int wait_count = 0;
    
    @try
    {
        while (![pipeLock tryLock])
        {
            // max wait for 10 mins
            if (wait_count++ > (1000 * 60 * 10))
            {
                [pipeLock breakLock];
                
                //2014/12/12 by haotan
                //既然此处的目的在于强制打破锁,立即又tryLock,岂不是达不到最多等待10mins的目的
                //[pipeLock tryLock];
            }
            usleep(20000);
        }
    }
    @catch (NSException * e)
    {
        NSLog(@"[ERR] try to lock file exception");
        [pipeLock unlock];
        return -1;
    }
    
    // get map address
    void *maps_addr[2] = {0};
    sem_t *sems[2] = {0};
    if (get_maps_for_pipes(path, maps_addr, sems) == -1)
    {
        NSLog(@"[ERR] get vmmap address fial, path: %@", path);
        [pipeLock unlock];
        return -1;
    }
    
    void *map_read = maps_addr[0];
    void *map_write = maps_addr[1];
    sem_t *sem_read = sems[0];
    sem_t *sem_write = sems[1];
    
    // clear flag before send command
    *(int *)map_read = 0;
    
    // send command
    memcpy((char *)map_write + sizeof(int), pcmd, pcmd->size);
    *(int *)map_write = MCARRIVE_CMD;
    
    // notify daemon
    sem_post(sem_write);
    
    // waiting to get reply
    sem_wait(sem_read);
    
    mc_pipe_result *presult;
    if (*(int *)map_read != MCARRIVE_RESULT)
    {
        NSLog(@"[ERR] check result magic fail: %d", pcmd->cmd_magic);
        close_maps_for_pipe(path);
        [pipeLock unlock];
        return -1;
    }
    
    // get result and return
    presult = (mc_pipe_result *)((char *)map_read + sizeof(int));
    // data may get wrong
    if (presult->cmd_magic != pcmd->cmd_magic)
    {
        NSLog(@"[ERR] recieve data wrong magic %d:%d", presult->cmd_magic, pcmd->cmd_magic);
        close_maps_for_pipe(path);
        [pipeLock unlock];
        return -1;
    }
    
    void *temp = malloc(presult->size);
    memcpy(temp, presult, presult->size);
    
    // set pointer
    *ppresult = (mc_pipe_result *)temp;
    
    [pipeLock unlock];
    return 0;
}

//int dm_task_for_pid(int pid, mach_port_name_t *task)
//{
//    if (task == NULL)
//        return -1;
//
//    // parameter
//    taskforpid_param param;
//    param.pid = pid;
//
//    // total size
//    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(taskforpid_param);
//    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
//
//    // set parameters
//    pcmd->size = cmd_size;
//    pcmd->cmd_magic = MCCMD_TASKFORPID;
//    memcpy(pcmd + 1, &param, sizeof(taskforpid_param));
//
//    mc_pipe_result *presult;
//    if (executePipeCommand(MCPIPE_STAT_NAME, pcmd, &presult) == -1)
//    {
//        free(pcmd);
//        return -1;
//    }
//    free(pcmd);
//
//    // get whatever we want for return
//    int ret = presult->cmd_ret;
//    if (ret == 0)
//    {
//        taskforpid_result *pcmd_result = (taskforpid_result *)(presult + 1);
//        *task = pcmd_result->task;
//    }
//
//    free(presult);
//    return ret;
//}

int dm_get_process_info(ORDER_TYPE orderType,
                        int count,
                        BOOL isReverse,
                        ProcessInfo_t **pproc)
{
    if (pproc == NULL)
        return -1;
    
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    // get procinfo list
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        procinfo_result *pcmd_result = (procinfo_result *)(presult + 1);
        ProcessInfo_t *pinfo = (ProcessInfo_t *)malloc(pcmd_result->info_size);
        memcpy(pinfo, pcmd_result->proc_info, pcmd_result->info_size);
        
        *pproc = pinfo;
    }
    
    free(presult);
    return ret;
}

int dm_get_fsmon_event(unsigned int start_index,
                       int count,
                       kfs_result_Data *outdata)
{
    if (outdata == NULL || count == 0)
        return -1;
    
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
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
    
    free(presult);
    return ret;
}

// get process sockets information
int dm_get_process_socket_info(process_sockets_info **proc_sk_info)
{
    if (proc_sk_info == NULL)
        return -1;
    
    // cmd with no param
    mc_pipe_cmd cmd;
    cmd.size = sizeof(mc_pipe_cmd);
    cmd.cmd_magic = MCCMD_SOCKETINFO;
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, &cmd, &presult) == -1)
    {
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    if (ret > 0)
    {
        skinfo_result *sk_result = (skinfo_result *)(presult + 1);
        process_sockets_info *temp = malloc(sk_result->data_size);
        memcpy(temp, sk_result->psk_info, sk_result->data_size);
        
        *proc_sk_info = temp;
    }
    
    free(presult);
    return ret;
}

// kill process
int dm_kill_process(pid_t pid)
{
    killproc_param param;
    param.pid = pid;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(killproc_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_KILLPROC;
    memcpy(pcmd + 1, &param, sizeof(killproc_param));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// file action
int dm_file_action(int action, int count, char *file_paths, int size)
{
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(fileaction_param) + size - 1;
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_FILEACTION;
    
    fileaction_param *param = (fileaction_param *)(pcmd + 1);
    param->action = action;
    param->count = count;
    param->paths_size = size;
    memcpy(param->path_start, file_paths, size);
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// set dock show
int dm_dock_show(BOOL show)
{
    setdock_param param;
    param.show_dock = show;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(setdock_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_SETDOCK;
    memcpy(pcmd + 1, &param, sizeof(setdock_param));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// set fan speed
int dm_set_fan_speed(int index, float min_speed)
{
    setfanspeed_param param;
    param.index = index;
    param.min_speed = min_speed;
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(setfanspeed_param);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_SETFANSPEED;
    memcpy(pcmd + 1, &param, sizeof(setfanspeed_param));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// fix an info.plist file
int dm_fix_plist(const char *szPlistPath, const char *szKey)
{
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// modify a plist file
int dm_modify_plist_file(const char *szPath,
                         const char *szKeyName,
                         int action_type,
                         int obj_type,
                         int plist_type,
                         const void *obj_data,
                         int obj_size)
{
    // total size
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
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// move file to other path
int dm_moveto_file(const char *srcPath, const char *dstPath, int action)
{
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_FSMON, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
       return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// change owl device state
int change_owl_device_proc_info(int device_type,
                                int device_state)
{
    // parameter
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    free(presult);
    return 1;
}
// get owl device process info
int get_owl_device_proc_info(int device_type,
                             int device_state,
                             lemon_com_process_info **odp_proc_info)
{
    if (odp_proc_info == NULL)
        return -1;
    
    // parameter
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
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_PROC, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
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
    
    free(presult);
    return ret;
}

// changeNetworkInfo is chmod 644 /dev/bpf* for get network info
int changeNetworkInfo(void)
{
    // total size
    int cmd_size = sizeof(mc_pipe_cmd);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_CHANGE_NETWORK_INFO;
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_SOCK, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// purgeMemory
int purgeMemory(void)
{
    // total size
    int cmd_size = sizeof(mc_pipe_cmd);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_PURGE_MEMORY;
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_SOCK, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}

// unInstallPlist
int unInstallPlist(const char *plist)
{
    op_file_path param = {0};
    strncpy(param.szPath, plist, sizeof(param.szPath) - 1);
    
    // total size
    int cmd_size = sizeof(mc_pipe_cmd) + sizeof(op_file_path);
    mc_pipe_cmd *pcmd = (mc_pipe_cmd *)malloc(cmd_size);
    
    // set parameters
    pcmd->size = cmd_size;
    pcmd->cmd_magic = MCCMD_UNINSTALL_PLIST;
    memcpy(pcmd + 1, &param, sizeof(op_file_path));
    
    mc_pipe_result *presult = NULL;
    if (executePipeCommand(MCPIPE_NAME_SOCK, pcmd, &presult) == -1)
    {
        free(pcmd);
        if (presult != NULL) {
            free(presult);
        }
        return -1;
    }
    free(pcmd);
    if (presult == NULL) {
        return -1;
    }
    
    int ret = presult->cmd_ret;
    free(presult);
    return ret;
}
