//
//  McCoreFunction.m
//  McCoreFunction
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McCoreFunction.h"
#import "McProcessInfo.h"
#import "McFileEvent.h"
#import "McFunCleanFile.h"
#import "McPipeStruct.h"
#import "LMXpcClient.h"
#import "NSString+Extension.h"

@implementation McCoreFunction

+ (void)initialize
{
    //    init_pipes();
    init_xpc();
}

- (id)init
{
    self = [super init];
    if (self)
    {
        fileEvent = [[McFileEvent alloc] init];
        processInfo = [[McProcessInfo alloc] init];
        funCleanFile = [[McFunCleanFile alloc] init];
    }
    
    return self;
}


+ (id)shareCoreFuction
{
    static dispatch_once_t onceToken = 0;
    __strong static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

+ (BOOL)isAppStoreVersion{
#ifndef APPSTORE_VERSION
    return NO;
#else
    return YES;
#endif
}

#pragma -
#pragma get info from Daemon

/*
 获取系统所以进程信息，返回结果为McProcessInfoData
 */
- (NSArray *)processInfo:(float *)cpuUsage totalMemory:(uint64 *)memory
{
    NSMutableArray * result = [processInfo GetProcessInfo:McprocNone count:0 isReverse:YES block:nil];
    if (cpuUsage || memory)
    {
        [processInfo getTotalCPU:cpuUsage totalMemory:memory];
    }
    return result;
}

- (void)processInfo:(float *)cpuUsage totalMemory:(uint64 *)memory block:(block_v_a)block_a
{
    [processInfo GetProcessInfo:McprocNone count:0 isReverse:YES block:block_a];
    if (cpuUsage || memory)
    {
        [processInfo getTotalCPU:cpuUsage totalMemory:memory];
    }
}


/*
 获取系统文件发生改变信息，返回结果为McFileEventData
 */
- (NSArray *)fileEventInfo
{
    NSMutableArray * fsData = [fileEvent fillFileEventData:nil];
    return fsData;
}

- (void)fileEventInfoAysnc:(block_v_a)block_a
{
    [fileEvent fillFileEventData:block_a];
}
#pragma -
#pragma - other opear

/*
 关闭进程
 pid:需要关闭进程的pid
 */
- (void)killProcessByID:(int)pid
{
    _dm_kill_process(pid);
}
- (void)killProcessByID:(int)pid block:(block_v_i)block_i
{
    _dm_kill_process_async(pid,  block_i);
}


- (void)killProcessByID:(int)pid ifMatch:(NSString *)keyword
{
    _dm_kill_process_with_keyword(pid, [keyword UTF8String]);
}
- (void)killProcessByID:(int)pid ifMatch:(NSString *)keyword block:(block_v_i)block_i
{
    _dm_kill_process_with_keyword_async(pid, [keyword UTF8String],  block_i);
}



/*
 内部逻辑复杂, 暂不修改为同步+ 异步接口
 删除文件/移动到回收站，并删除无用的二进制
 removePaths:需要删除的路径
 cutBinPaths:需要删除无用的二进制的路径
 cleanDelegate:删除文件委托
 type:删除文件方式（删除/移动到回收站/采用高权限）
 */

- (BOOL)cleanItemAtPath:(NSString *)path
                  array:(NSArray *)pathArray
             removeType:(McCleanRemoveType)type;
{
#ifdef DEBUG
    if (path)
        NSLog(@"path : %@", path);
    if (pathArray)
        NSLog(@"pathArray : %@", pathArray);
    return YES;
#else
    if (path && pathArray)  //互斥, 防止2个都有值, 而不是防止2个都为空
        return NO;
    if (path)
        NSLog(@"path : %@ ", path);
    if (pathArray)
        NSLog(@"pathArray : %@", pathArray);
    return [self->funCleanFile cleanItemAtPath:path array:pathArray delegate:nil removeType:type];
#endif
}

- (void)cutunlessBinary:(NSString *)path
                 array:(NSArray *)pathArray
            removeType:(AppBinaryType)type {
    [self->funCleanFile cutunlessBinary:pathArray removeType:type];
    
}

// 暂未有调用, 不修改成 同步/ 异步方法.
- (void)startCleanWithThread:(NSArray *)removePaths
                   cutBinary:(NSArray *)binaries
                    delegate:(id<McCleanDelegate>)cleanDelegate
                  removeType:(McCleanRemoveType)type
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self->funCleanFile startClean:removePaths
                             cutBinary:binaries
                              delegate:cleanDelegate
                            removeType:type];
    });
}


/*
 暂未有调用, 不修改成 同步/ 异步方法.
 moveFileItem移动文件，copyFileItem拷贝文件（root权限）
 返回值:YES成功，NO失败
 path1:原路径
 path2:目标路径
 */
- (BOOL)moveFileItem:(NSString *)path1 toPath:(NSString *)path2
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSError * err = nil;
    if (![fm fileExistsAtPath:path1])
        return NO;
    
    if ([fm replaceItemAtURL:[NSURL fileURLWithPath:path2]
               withItemAtURL:[NSURL fileURLWithPath:path1]
              backupItemName:nil
                     options:NSFileManagerItemReplacementUsingNewMetadataOnly
            resultingItemURL:nil
                       error:&err]
        && err == nil)
    {
        return YES;
    }
    else
    {
        return ([funCleanFile moveFileItem:path1 toPath:path2] == 0);
    }
}

// 暂未有调用, 不修改成 同步/ 异步方法.
- (BOOL)copyFileItem:(NSString *)path1 toPath:(NSString *)path2
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSError * err = nil;
    if (![fm fileExistsAtPath:path1])
        return NO;
    if ([fm fileExistsAtPath:path2])
        [fm removeItemAtPath:path2 error:nil];
    if ([fm copyItemAtPath:path1 toPath:path2 error:&err] && err == nil)
    {
        return YES;
    }
    else
    {
        return ([funCleanFile copyFileItem:path1 toPath:path2] == 0);
    }
}

/*
 设置风扇最低转速
 index:代表第几个风扇
 speed:转速
 */
- (void)setFanMinSpeeds:(int)index minSpeed:(float)speed
{
    _dm_set_fan_speed(index, speed);
}

- (void)setFanMinSpeeds:(int)index minSpeed:(float)speed block:(block_v_i)block_i
{
    _dm_set_fan_speed_async(index, speed, block_i);
}

static void pack_smc_event(NSMutableArray *fsData, double *fs_data, int ret) {
    if (ret > 0)
    {
        for (int i = 0; i < ret; i++)
        {
            [fsData addObject:[NSNumber numberWithDouble:fs_data[i]]];
        }
    }
}


- (void)getFanSpeeds:(block_v_a)completion
{
    const int per_count = 10;
    double *fs_data = malloc(sizeof(fs_data)*per_count);
    __block NSMutableArray * fsData = [NSMutableArray array];
    block_v_i copyBlock = ^(int return_code) {
        pack_smc_event(fsData, fs_data, return_code);
        completion([NSArray arrayWithArray:fsData]);
        free(fs_data);
    };
    _dm_get_fan_speed_async(0, per_count, fs_data, copyBlock);
}

- (void)getCPUTemperature:(block_v_a)completion
{
    const int per_count = 1;
    double *fs_data = malloc(sizeof(fs_data)*per_count);
    __block NSMutableArray * fsData = [NSMutableArray array];
    block_v_i copyBlock = ^(int return_code) {
        pack_smc_event(fsData, fs_data, return_code);
        completion([NSArray arrayWithArray:fsData]);
        free(fs_data);
    };
    _dm_get_cpu_temperature_async(0, per_count, fs_data, copyBlock);
}

/*
 移除plist文件中key
 file:文件路径
 removeKey:需要移除的key
 */
- (void)fixPlistFile:(NSString *)file removeKey:(NSString *)key
{
    _dm_fix_plist([file UTF8String], [key UTF8String]);
}

/*
 修改plist文件中的值（对应，NSString、Number、NSDictionary）
 file:文件路径
 key:需要修改的key
 obj:值
 */
- (BOOL)modifyPlistFileByString:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSString *)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    if (objData == nil)
        return NO;
    
    int result = _dm_modify_plist_file([file UTF8String],
                                       [key UTF8String],
                                       MCCMD_WRITEPLIST_MODIFY,
                                       MCCMD_TYPE_NSSTRING,
                                       type,
                                       [objData bytes],
                                       (int)[objData length]);
    return result != -1;
}

- (BOOL)modifyPlistFileByNumber:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSNumber *)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    if (objData == nil)
        return NO;
    
    int result = _dm_modify_plist_file([file UTF8String],
                                       [key UTF8String],
                                       MCCMD_WRITEPLIST_MODIFY,
                                       MCCMD_TYPE_NSNUMBER,
                                       type,
                                       [objData bytes],
                                       (int)[objData length]);
    return result != -1;
}

- (BOOL)modifyPlistFileByDic:(NSString *)file key:(NSString *)key plistType:(int)type obj:(NSDictionary *)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    if (objData == nil)
        return NO;
    
    int result = _dm_modify_plist_file([file UTF8String],
                                       [key UTF8String],
                                       MCCMD_WRITEPLIST_MODIFY,
                                       MCCMD_TYPE_NSDICTIONARY,
                                       type,
                                       [objData bytes],
                                       (int)[objData length]);
    return result != -1;
}

- (BOOL)removePlistFileyKey:(NSString *)file key:(NSString *)key plistType:(int)type
{
    int result = _dm_modify_plist_file([file UTF8String],
                                       [key UTF8String],
                                       MCCMD_WRITEPLIST_DELETE,
                                       MCCMD_TYPE_NSDICTIONARY,
                                       type,
                                       NULL,
                                       0);
    return result != -1;
}

- (void)sortProcess:(NSMutableArray *) array
          orderEnum:(ProcessOrderEnum) orderEnum
              isAsc:(BOOL) isAsc
{
    [processInfo sortProcess:array
                   orderEnum:orderEnum
                       isAsc:isAsc];
}

- (int)notiflyClientExit {
    pid_t pid = getpid();
    return _dm_notifly_client_exit(pid);
}

- (void)notiflyClientExitAsync:(block_v_i)block_i {
    pid_t pid = getpid();
    _dm_notifly_client_exit_async(pid, block_i);
}
/*
 卸载程序
 */
- (int)unInstallMagican
{
    return _dm_uninstall_all();
}

- (void)unInstallMagicanAsync:(block_v_i)block_i
{
    _dm_uninstall_all_async(block_i);
}


// 更新程序
static void getVersionByPath(NSString **fullVersion, NSString *newAppPath) {
    NSBundle *newBundle = [NSBundle bundleWithPath:newAppPath];
    NSString *curVersion = [[newBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[newBundle infoDictionary] objectForKey:@"CFBundleVersion"];
    *fullVersion = [curVersion stringByAppendingPathComponent:buildVersion];
}
- (int)updateAPP:(NSString *)newAppPath fullVersion:(NSString *)fullVersion
{
    if ([newAppPath length] == 0)
        return -1;
    
    if(fullVersion == NULL){
        // 检查bundle完整性
        getVersionByPath(&fullVersion, newAppPath);
    }
    
    if ([fullVersion length] == 0)
        return -2;
    
    return _dm_update([newAppPath UTF8String], [fullVersion UTF8String]);
}

- (void)updateAPP:(NSString *)newAppPath fullVersion:(NSString *)fullVersion block:(block_v_i)block_i
{
    if ([newAppPath length] == 0)
        block_i(-1);
    
    if(fullVersion == NULL){
        // 检查bundle完整性
        getVersionByPath(&fullVersion, newAppPath);
    }
    
    if ([fullVersion length] == 0)
        block_i(-2);
    
    _dm_update_async([newAppPath UTF8String], [fullVersion UTF8String], block_i);
}

#pragma mark - get full disk access from Daemon
- (QMFullDiskAuthorationStatus)getFullDiskAccessForDaemon {
    const char * userHomePath = [[NSString getUserHomePath] UTF8String];
    const char * userHomePath2 = [[@"~" stringByExpandingTildeInPath] UTF8String];
    if (userHomePath == NULL) {
        return QMFullDiskAuthorationStatusNotDetermined;
    } else {
        return _full_disk_access(userHomePath, userHomePath2);
    }
}

#pragma get info from Daemon


// 摄像头或音频接口
- (BOOL)changeOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState{
    return _change_owl_device_proc_info(deviceType, deviceState);
}
- (void)changeOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState block:(block_v_i)block_i{
    _change_owl_device_proc_info_async(deviceType, deviceState, block_i);
}

static NSMutableArray *packOwlDeviceProcInfo(int fun_ret, lemon_com_process_info *owl_proc_info) {
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (int i = 0; i < fun_ret; i++) {
        NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
        
        dicItem[@"OWL_PROC_ID"] = [NSNumber numberWithInt:owl_proc_info[i].pid];
        dicItem[@"OWL_PROC_NAME"] = [NSString stringWithUTF8String:owl_proc_info[i].name];
        dicItem[@"OWL_PROC_PATH"] = [NSString stringWithUTF8String:owl_proc_info[i].path];
        dicItem[@"OWL_PROC_DELTA"] = [NSNumber numberWithInt:owl_proc_info[i].time_count];
        dicItem[@"OWL_DEVICE_TYPE"] = [NSNumber numberWithInt:owl_proc_info[i].device_type];
        [result addObject:dicItem];
    }
    return result;
}

- (NSArray *)getOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState
{
    __block lemon_com_process_info *owl_proc_info = NULL;
    int fun_ret = _get_owl_device_proc_info(deviceType, deviceState, &owl_proc_info);
    if (fun_ret <= 0)
    {
        return nil;
    }
    
    NSMutableArray * result = packOwlDeviceProcInfo(fun_ret, owl_proc_info);
    free(owl_proc_info);
    return result;
}

- (void)getOwlDeviceProcInfo:(int)deviceType deviceState:(int)deviceState block:(block_v_a)block_a
{
    __block lemon_com_process_info *owl_proc_info = NULL;
    block_v_i copyBlock = ^(int fun_ret) {
        if (fun_ret <= 0)
        {
            block_a(nil);
        }
        
        // owl_proc_info 本身是个堆指针,不需要考虑__block 的问题.
        NSMutableArray * result = packOwlDeviceProcInfo(fun_ret, owl_proc_info);
        free(owl_proc_info);
        block_a(result);
    };
    _get_owl_device_proc_info_async(deviceType, deviceState, &owl_proc_info, copyBlock);
    
}


// changeNetworkInfo is chmod 644 /dev/bpf* for get network info
- (BOOL)changeNetworkInfo{
    int result = _changeNetworkInfo();
    return result != -1;
}

- (void)changeNetworkInfoAsync:(block_v_b)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code != -1);
        block(flag);
    };
    _changeNetworkInfoAsync(copyBlock);
}

// purgeMemory
- (BOOL)purgeMemory{
    int result = _purgeMemory();
    return result != -1;
}
- (void)purgeMemoryAsync:(block_v_b)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code != -1);
        block(flag);
    };
    _purgeMemoryAsync(copyBlock);
}


// unInstallPlist  只是执行了 launchctl unload 操作,没有移除 plist 文件
- (BOOL)unInstallPlist:(NSString *)plist{
    int result = _unInstallPlist([plist UTF8String]);
    return result != -1;
}

- (void)unInstallPlist:(NSString *)plist block:(block_v_b)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code != -1);
        block(flag);
    };
    _unInstallPlistAsync([plist UTF8String], copyBlock);
}

- (NSDictionary*)getFileInfo:(NSString *)filePath{
    get_file_info *file_info = NULL;
    int fun_ret = _getFileInfo([filePath UTF8String], &file_info);
    if (fun_ret <= 0 || (file_info == NULL))
    {
        return nil;
    }
    NSDictionary *resDic = @{@"fileSize": @(file_info->file_size)};
    free(file_info);
    return resDic;
}
- (void)getFileInfoAsync:(NSString *)filePath block:(block_v_d)block{
    get_file_info *file_info = NULL;
    block_v_i copyBlock = ^(int fun_ret) {
        if (fun_ret <= 0 || (file_info == NULL))
        {
            block(nil);
        }
        NSDictionary *resDic = @{@"fileSize": @(file_info->file_size)};
        free(file_info);
        block(resDic);
    };
    _getFileInfoAsync([filePath UTF8String], &file_info, copyBlock);
}

/*
 卸载 内核拓展(驱动).  unload Kext 并且移除 kext文件,如果可能的话. kext 文件一般存贮在/Library/Extensions
 kext:需要卸载的驱动的bundleId.
 */
- (BOOL)uninstallKextWithBundleId:(NSString *)kext;
{
    int result = _dm_uninstall_kext_with_bundleId([kext UTF8String]);
    return result >= 0;
}
- (void)uninstallKextWithBundleId:(NSString *)kext block:(block_v_b)block;
{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _dm_uninstall_kext_with_bundleId_async([kext UTF8String], copyBlock);
}

//unload Kext 并且移除 kext文件
- (BOOL)uninstallKextWithPath:(NSString *)kext;
{
    int result = _dm_uninstall_kext_with_path([kext UTF8String]);
    return result >= 0;
}
- (void)uninstallKextWithPath:(NSString *)kext block:(block_v_b)block;
{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _dm_uninstall_kext_with_path_async([kext UTF8String], copyBlock);
}



// pkgutil --forget
- (BOOL)removePkgInfoWithBundleId:(NSString *)bundleId{
    int result = _dm_rm_pkg_info_with_bundleId([bundleId UTF8String]);
    return result >= 0;
}
- (void)removePkgInfoWithBundleId:(NSString *)bundleId block:(block_v_b)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _dm_rm_pkg_info_with_bundleId_async([bundleId UTF8String], copyBlock);
}

/*
 移除系统LoginItem.  注意 Daemon 端处理的时候用到了 applescript(速度较慢), 不要在主线程直接调用.
 kext:需要卸载的驱动的名字.
 */
- (BOOL)removeLoginItem:(NSString *)loginItem
{
    int result = _dm_remove_login_item([loginItem UTF8String]);
    return result >= 0;
}
- (void)removeLoginItem:(NSString *)loginItem block:(block_v_b)block
{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _dm_remove_login_item_async([loginItem UTF8String], copyBlock);
}

/*
 collect the lemon log info.
 */
- (BOOL)collectLemonLogInfo:(NSString *)homeDir
{
    int result = _collect_lemon_loginfo([homeDir UTF8String]);
    return result >= 0;
}
- (void)collectLemonLogInfo:(NSString *)homeDir block:(block_v_b)block
{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _collect_lemon_loginfo_async([homeDir UTF8String], copyBlock);
}

//pf is control the ipfw(or iptable)
- (BOOL)setLemonFirewallPortPF:(NSString *)strTcpPort udpPort:(NSString *)strUdpPort{
    int result = _set_lemon_firewall_port_pf([strTcpPort UTF8String], [strUdpPort UTF8String]);
    return result >= 0;
}
- (void)setLemonFirewallPortPF:(NSString *)strTcpPort udpPort:(NSString *)strUdpPort block:(block_v_b)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        block(flag);
    };
    
    _set_lemon_firewall_port_pf_async([strTcpPort UTF8String], [strUdpPort UTF8String], copyBlock);
}

// stat port using info(through lsof)
static NSMutableArray *packLemonPortInfo(int fun_ret, lemon_com_process_info *port_info) {
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (int i = 0; i < fun_ret; i++) {
        NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
        
        dicItem[@"PROC_ID"] = [NSNumber numberWithInt:port_info[i].pid];
        dicItem[@"PROC_PORT"] = [NSNumber numberWithInt:port_info[i].time_count];
        dicItem[@"PROC_STATE"] = [NSNumber numberWithInt:port_info[i].device_type];
        [result addObject:dicItem];
    }
    return result;
}

- (NSArray *)statPortProcInfo
{
    __block lemon_com_process_info *port_proc_info = NULL;
    int fun_ret = _stat_port_proc_info(&port_proc_info);
    if (fun_ret <= 0)
    {
        return nil;
    }
    
    NSMutableArray * result = packLemonPortInfo(fun_ret, port_proc_info);
    free(port_proc_info);
    return result;
}

- (void)statPortProcInfoAsync:(block_v_a)block_a
{
    __block lemon_com_process_info *port_proc_info = NULL;
    block_v_i copyBlock = ^(int fun_ret) {
        if (fun_ret <= 0)
        {
            block_a(nil);
            return;
        }
        
        // port_info 本身是个堆指针,不需要考虑__block 的问题.
        NSMutableArray * result = packLemonPortInfo(fun_ret, port_proc_info);
        free(port_proc_info);
        block_a(result);
    };
    _stat_port_proc_info_async(&port_proc_info, copyBlock);
    
}

- (BOOL)enableLaunchSystemWithFilePath:(NSString *)path label:(NSString *)label{
    int result = _manageLaunchSystemStatus([path UTF8String], [label UTF8String], MCCMD_LAUNCH_SYSTEM_STATUS_ENABLE);
    return result != -1;
}

- (void)enableLaunchSystemAsyncWithFilePath:(NSString *)path label:(NSString *)label block:(block_v_i)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        if (block) {
            block(flag);
        }
    };
    _manageLaunchSystemStatusAsync([path UTF8String], [label UTF8String], MCCMD_LAUNCH_SYSTEM_STATUS_ENABLE, copyBlock);
}

- (BOOL)disableLaunchSystemWithFilePath:(NSString *)path label:(NSString *)label{
    int result = _manageLaunchSystemStatus([path UTF8String], [label UTF8String], MCCMD_LAUNCH_SYSTEM_STATUS_DISABLE);
    return result != -1;
}

- (void)disableLaunchSystemAsyncWithFilePath:(NSString *)path label:(NSString *)label block:(block_v_i)block{
    block_v_i copyBlock = ^(int return_code) {
        BOOL flag = (return_code > 0);
        if (block) {
            block(flag);
        }
    };
    _manageLaunchSystemStatusAsync([path UTF8String], [label UTF8String], MCCMD_LAUNCH_SYSTEM_STATUS_DISABLE, copyBlock);
}

- (BOOL)getLaunchSystemStatusWithlabel:(NSString *)label{
    int result = _getLaunchSystemStatus([label UTF8String]);
    return result == 1;
}


@end
