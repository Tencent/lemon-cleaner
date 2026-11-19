//
//  LMXPCFunction.m
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMXPCFunction.h"
#import "CmcProcInfo.h"
#import "Cmcfsmonitor.h"
#import "CmcNetSocket.h"
#import "McUninstall.h"
#import "CmcFileAction.h"
#import "CmcFan.h"
#import "CmcTemperature.h"
#import "McRemoveTrojan.h"
#import "OwlManageDaemon.h"
#import "DaemonStartup.h"
#import "ExecuteCmdHelper.h"
#import "LMKextManager.h"
#import <Libproc.h>

@implementation LMXPCFunction


int kill_proc_if_match_keyword(mc_pipe_cmd *pcmd, mc_pipe_result **ppresult);

// reply with on data, just return value
+ (mc_pipe_result *)cmdSimpleReply:(int)ret magic:(int)magic {
    int total_size = sizeof(mc_pipe_result);
    mc_pipe_result *presult = (mc_pipe_result *) malloc(total_size);
    presult->cmd_magic = magic;
    presult->size = total_size;
    presult->cmd_ret = ret;
    return presult;
}


+ (void)cmdDispather:(mc_pipe_cmd *)pcmd result:(mc_pipe_result **)ppresult {
#ifdef DEBUG
    NSLog(@"[info] cmdDispather");
#endif
    if (pcmd == NULL || ppresult == NULL)
        return;
    *ppresult = NULL;
    int total_size;
    int fun_ret;
    mc_pipe_result *presult;
    //procinfo_param *proc_param;
    fsmon_param *fs_param;
    ProcessInfo_t *proc_info = NULL;
    switch (pcmd->cmd_magic) {
        case MCCMD_TASKFORPID: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_TASKFORPID cmd");
#endif

            taskforpid_param *param = (taskforpid_param *) (pcmd + 1);
            total_size = sizeof(mc_pipe_result) + sizeof(taskforpid_result);
            presult = (mc_pipe_result *) malloc(total_size);
            taskforpid_result cmd_result;

            // call functions
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = task_for_pid(mach_task_self(), param->pid, &cmd_result.task);

            memcpy(presult + 1, &cmd_result, sizeof(taskforpid_result));

            *ppresult = presult;
            break;
        }

        case MCCMD_PROCINFO:
            //NSLog(@"[info] MCCMD_PROCINFO cmd");

            // call function
            //proc_param = (procinfo_param *)(pcmd + 1);
            //            fun_ret = CmcGetProcessInfo(proc_param->order_type,
            //                                        proc_param->count,
            //                                        proc_param->reverse,
            //                                        &proc_info);
            fun_ret = CmcFillAllProcInfo(&proc_info);
            if (fun_ret == -1 || fun_ret == 0) {
                total_size = sizeof(mc_pipe_result) + sizeof(procinfo_result);
            } else {
                total_size = sizeof(mc_pipe_result) + sizeof(procinfo_result) + (fun_ret - 1) * sizeof(ProcessInfo_t);
            }

            // build result
            presult = (mc_pipe_result *) malloc(total_size);
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = fun_ret;

            if (fun_ret > 0) {
                procinfo_result *pproc_result = (procinfo_result *) (presult + 1);
                pproc_result->count = fun_ret;
                pproc_result->info_size = fun_ret * sizeof(ProcessInfo_t);
                memcpy(pproc_result->proc_info, proc_info, pproc_result->info_size);

                //NSLog(@"[info] process count: %d", pproc_result->count);
            }

            if (proc_info != NULL) {
                free(proc_info);
                proc_info = NULL;
            }

            *ppresult = presult;
            break;

        case MCCMD_FSMON:
            //NSLog(@"[info] MCCMD_FSMON cmd");

            // call function
            fs_param = (fsmon_param *) (pcmd + 1);
            kfs_result_Data *fs_data = malloc(sizeof(kfs_result_Data) * fs_param->count);
            fun_ret = CmcGetFsmonData(fs_param->startindex, fs_data, fs_param->count);

            total_size = sizeof(mc_pipe_result) + sizeof(fsmon_result);
            if (fun_ret > 0) {
                total_size += (fun_ret - 1) * sizeof(kfs_result_Data);
            }

            // build result
            presult = (mc_pipe_result *) malloc(total_size);
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = fun_ret;

            if (fun_ret > 0) {
                fsmon_result *fs_result = (fsmon_result *) (presult + 1);
                fs_result->count = fun_ret;
                fs_result->data_size = fun_ret * sizeof(kfs_result_Data);
                memcpy(fs_result->fs_data, fs_data, fs_result->data_size);

                //                NSLog(@"[info] fsmon event count: %d (%d - %d)",
                //                      fs_result->count, fs_data[0].index, fs_data[fs_result->count - 1].index);
                //                for (int i = 0; i < fs_result->count; i++)
                //                {
                //                    NSLog(@"EVENT[%d] - type:%d path:%s",
                //                          fs_data[i].index, fs_data[i].type, fs_data[i].result_Detail1.path);
                //                }
            }

            free(fs_data);

            *ppresult = presult;
            break;

        case MCCMD_SOCKETINFO:
            //NSLog(@"[info] MCCMD_SOCKETINFO cmd");

            total_size = sizeof(mc_pipe_result) + sizeof(skinfo_result) - sizeof(process_sockets_info);

            // call function
            //const int max_proc_count = 1000;
            process_sockets_info *proc_sk_info[1000];
            int proc_count = CmcGetProcessSocketsInfo(proc_sk_info, 1000);
            if (proc_count != 0) {
                for (int i = 0; i < proc_count; i++) {
                    total_size += proc_sk_info[i]->len;
                }

                // build result
                presult = (mc_pipe_result *) malloc(total_size);
                presult->cmd_magic = pcmd->cmd_magic;
                presult->size = total_size;
                presult->cmd_ret = proc_count;

                // build each process socket info
                skinfo_result *sk_info_result = (skinfo_result *) (presult + 1);
                sk_info_result->count = proc_count;
                process_sockets_info *cur_proc_info = sk_info_result->psk_info;
                int total_proc_sk_info_size = 0;
                for (int i = 0; i < proc_count; i++) {
                    memcpy(cur_proc_info, proc_sk_info[i], proc_sk_info[i]->len);
                    cur_proc_info = (process_sockets_info *) ((char *) cur_proc_info + proc_sk_info[i]->len);

                    total_proc_sk_info_size += proc_sk_info[i]->len;

                    // free
                    free(proc_sk_info[i]);
                }

                sk_info_result->data_size = total_proc_sk_info_size;
            } else {
                // build result
                presult = (mc_pipe_result *) malloc(total_size);
                presult->cmd_magic = pcmd->cmd_magic;
                presult->size = total_size;
                presult->cmd_ret = proc_count;
            }

            *ppresult = presult;
            break;

        case MCCMD_KILLPROC: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_KILLPROC cmd");
#endif

            // kill process
            killproc_param *kill_param = (killproc_param *) (pcmd + 1);
            // dont kill self
            fun_ret = -1;
            if (kill_param->pid != getpid()) {
                fun_ret = kill(kill_param->pid, SIGKILL);
            }

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }

        case MCCMD_KILLPROC_WITH_KEY_WORD:{
#ifdef DEBUG
            NSLog(@"[info] MCCMD_KILLPROC_WITH_KEY_WORD cmd");
#endif
            
            // kill process
            int fun_ret = kill_proc_if_match_keyword(pcmd, ppresult);
            *ppresult = [LMXPCFunction cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];

            break;
        }
        case MCCMD_UNINSTALL: {
#ifdef DEBUG
            NSLog(@"[info] Ready to uninstall !!!");
#endif

            // certify the auth value
            uninstall_param *un_param = (uninstall_param *) (pcmd + 1);
            if (un_param->auth_magic == UNINSTALL_AUTH) {
                uninstallCastle();

                // notify result
                *ppresult = [self cmdSimpleReply:1 magic:pcmd->cmd_magic];

//                if (presult != NULL)
//                {
//                    if (presult->size > g_mapsize - 10)
//                    {
//                        NSLog(@"[ERR] result size to big: %d - %d", presult->cmd_magic, presult->size);
//                        presult->size = g_mapsize - 10;
//                    }
//                    //            NSLog(@"to send [%d]: %d %d %d",
//                    //                  presult->cmd_magic,
//                    //                  *(int *)presult, *((int *)presult+1), *((int *)presult+2));
//
//                    memcpy((char *)map_write + sizeof(int), presult, presult->size);
//                    *(int *)map_write = MCARRIVE_RESULT;
//                    free(presult);
//                }
//                sem_post(sem_write);
//                sleep(1);
//                exit(0);
            } else {
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
            }

            // never return
            break;
        }

        case MCCMD_UPDATE: {
#ifdef DEBUG
            NSLog(@"[info] Update self !!!");
#endif

            update_param *upt_param = (update_param *) (pcmd + 1);
            fun_ret = UpdateCastle(upt_param->szAppPath, upt_param->szUserName, upt_param->szVersion, upt_param->pid);

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }


        case MCCMD_FILEACTION:{
#ifdef DEBUG
            NSLog(@"[info] MCCMD_FILEACTION cmd");
#endif

            fun_ret = -1;
            fileaction_param *file_param = (fileaction_param *) (pcmd + 1);

            // 注意: file_param->path_start 是一个 string 数组的起始位置. 每一个 string以 \0 分隔.
            switch (file_param->action) {
                case MC_FILE_DEL:
                    fun_ret = filesRemove(file_param->path_start, file_param->count);
                    break;

                case MC_FILE_BIN_CUT:
                    fun_ret = fileCutBinaries(file_param->path_start, file_param->count);
                    break;

                case MC_FILE_RECYCLE:
                    fun_ret = fileMoveToTrash(file_param->path_start, file_param->count);
                    break;

                case MC_FILE_TRUNCATE:
                    fun_ret = fileClearContent(file_param->path_start, file_param->count);
                    break;
                case MC_FILE_CUT:
                    fun_ret = fileCutContent(file_param->path_start, file_param->count,file_param->type);
                    break;
            }

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_MOVEFILE:{
#ifdef DEBUG
            NSLog(@"[info] MCCMD_MOVEFILE cmd");
#endif

            movefile_param *movfile_param = (movefile_param *) (pcmd + 1);
            
            // 安全校验：源路径和目标路径都必须在白名单中
            NSString *mvSrcPath = [NSString stringWithUTF8String:movfile_param->szSrcPath];
            NSString *mvDstPath = [NSString stringWithUTF8String:movfile_param->szDestPath];
            if (!isPathAllowedForFileOp(mvSrcPath)) {
                NSLog(@"[security] MCCMD_MOVEFILE: reject src path: %@", mvSrcPath);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            if (!isPathAllowedForFileOp(mvDstPath)) {
                NSLog(@"[security] MCCMD_MOVEFILE: reject dst path: %@", mvDstPath);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }

            fun_ret = fileMoveTo(movfile_param->szSrcPath, movfile_param->szDestPath, movfile_param->action);

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_SETDOCK:{
#ifdef DEBUG
            NSLog(@"[info] MCCMD_SETDOCK cmd");
#endif

            setdock_param *setd_param = (setdock_param *) (pcmd + 1);
            fun_ret = 0;
            if (!setCastleShowDock(setd_param->show_dock))
                fun_ret = -1;

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_SETFANSPEED:{
#ifdef DEBUG
            NSLog(@"[info] MCCMD_SETFANSPEED cmd");
#endif

            setfanspeed_param *setfan_param = (setfanspeed_param *) (pcmd + 1);

            fun_ret = CmcSetMinFanSpeed(setfan_param->index, setfan_param->min_speed);

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_CHANGE_NETWORK_INFO: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_CHANGE_NETWORK_INFO cmd");
#endif
            fun_ret = system("chmod 644 /dev/bpf*");
            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
        }
            break;
        case MCCMD_PURGE_MEMORY: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_PURGE_MEMORY cmd");
#endif
            fun_ret = system("purge");
            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
        }
            break;
        case MCCMD_UNINSTALL_PLIST: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_UNINSTALL_PLIST cmd");
#endif

            op_file_path *plist_param = (op_file_path *) (pcmd + 1);
            NSString *plist = [NSString stringWithUTF8String:plist_param->szPath];
            fun_ret = -1;
            
            // 安全校验：只允许合法的 LaunchDaemons/LaunchAgents 路径
            if (![plist hasPrefix:@"/Library/LaunchDaemons/"] &&
                ![plist hasPrefix:@"/Library/LaunchAgents/"]) {
                NSLog(@"[security] reject invalid plist path: %@", plist);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            // 防止路径穿越和命令注入
            if ([plist containsString:@".."] || [plist containsString:@";"] ||
                [plist containsString:@"|"] || [plist containsString:@"&"] ||
                [plist containsString:@"`"] || [plist containsString:@"$"]) {
                NSLog(@"[security] reject suspicious plist path: %@", plist);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if ([fileMgr fileExistsAtPath:plist]) {
                fun_ret = executeLaunchPath(@"/bin/launchctl", @[@"unload", plist]);
            }
            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_MANAGE_LAUNCH_SYSTEM_STATUS: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_MANAGE_LAUNCH_SYSTEM_STATUS cmd");
#endif
            
            manage_launch_system_param *param = (manage_launch_system_param *) (pcmd + 1);
            NSString *path = [NSString stringWithUTF8String:param->path];
            NSString *label = [NSString stringWithUTF8String:param->label];
            fun_ret = -1;
            
            // 安全校验：路径白名单
            if (![path hasPrefix:@"/Library/LaunchDaemons/"] &&
                ![path hasPrefix:@"/Library/LaunchAgents/"]) {
                NSLog(@"[security] reject invalid path: %@", path);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            // 安全校验：label 只允许字母、数字、点号、连字符、下划线
            NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:
                @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_"];
            if ([label rangeOfCharacterFromSet:[allowedChars invertedSet]].location != NSNotFound) {
                NSLog(@"[security] reject invalid label: %@", label);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            // 防止路径穿越和命令注入
            if ([path containsString:@".."] || [path containsString:@";"] ||
                [path containsString:@"|"] || [path containsString:@"&"] ||
                [path containsString:@"`"] || [path containsString:@"$"]) {
                NSLog(@"[security] reject suspicious path: %@", path);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if ([fileMgr fileExistsAtPath:path]) {
                int action = param->action;
#ifdef DEBUG
                NSLog(@"[info] action = %d", action);
#endif
                if (action == MCCMD_LAUNCH_SYSTEM_STATUS_ENABLE) {
                    NSString *target = [NSString stringWithFormat:@"system/%@", label];
                    fun_ret = executeLaunchPath(@"/bin/launchctl", @[@"enable", target]);
                    if (fun_ret == 0) {
                        fun_ret = executeLaunchPath(@"/bin/launchctl", @[@"load", path]);
                    }
                } else if (action == MCCMD_LAUNCH_SYSTEM_STATUS_DISABLE) {
                    NSString *target = [NSString stringWithFormat:@"system/%@", label];
                    fun_ret = executeLaunchPath(@"/bin/launchctl", @[@"disable", target]);
                    if (fun_ret == 0) {
                        fun_ret = executeLaunchPath(@"/bin/launchctl", @[@"unload", path]);
                    }
                }
#ifdef DEBUG
                NSLog(@"%s, manage root launchctl item: %@, result: %d ", __FUNCTION__, label, fun_ret);
#endif
            }
            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_GET_LAUNCH_SYSTEM_STATUS : {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_GET_LAUNCH_SYSTEM_STATUS cmd");
#endif
            op_simple_string *param = (op_simple_string *)(pcmd + 1);
            NSString *label = [NSString stringWithUTF8String:param->str];
            
            // 安全校验：label 只允许字母、数字、点号、连字符、下划线
            NSCharacterSet *allowedLabelChars = [NSCharacterSet characterSetWithCharactersInString:
                @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_"];
            if (!label || label.length == 0 ||
                [label rangeOfCharacterFromSet:[allowedLabelChars invertedSet]].location != NSNotFound) {
                NSLog(@"[security] reject invalid label for GET_LAUNCH_SYSTEM_STATUS: %@", label);
                *ppresult = [self cmdSimpleReply:-1 magic:pcmd->cmd_magic];
                break;
            }
            
            NSString *result = executeLaunchPathAndGetResult(@"/bin/launchctl", @[@"list"]);
            int status = 0;
            if (result.length > 0) {
                for (NSString *line in [result componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
                    NSArray<NSString *> *fields = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSMutableArray<NSString *> *nonEmpty = [NSMutableArray array];
                    for (NSString *field in fields) {
                        if (field.length > 0) {
                            [nonEmpty addObject:field];
                        }
                    }
                    if (nonEmpty.count > 0 && [nonEmpty.lastObject isEqualToString:label]) {
                        status = 1;
                        break;
                    }
                }
            }
            *ppresult = [self cmdSimpleReply:status magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_GET_FILE_INFO: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_GET_FILE_INFO cmd");
#endif

            op_file_path *plist_param = (op_file_path *) (pcmd + 1);
            NSString *path = [NSString stringWithUTF8String:plist_param->szPath];
            fun_ret = -1;

            //计算文件大小
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                uint64 fileSize = 0;
                BOOL diskMode = YES;

                struct stat fileStat;
                if (lstat([path fileSystemRepresentation], &fileStat) == noErr) {
                    if (fileStat.st_mode & S_IFDIR)
                        fileSize = [self fastFolderSizeAtFSRef:path diskMode:diskMode];
                    else {
                        if (diskMode && fileStat.st_blocks != 0)
                            fileSize += fileStat.st_blocks * 512;
                        else
                            fileSize += fileStat.st_size;
                    }
                }
                total_size = sizeof(mc_pipe_result) + sizeof(get_file_info);
                presult = (mc_pipe_result *) malloc(total_size);
                get_file_info cmd_result;
                cmd_result.file_size = fileSize;

                // call functions
                presult->cmd_magic = pcmd->cmd_magic;
                presult->size = total_size;
                presult->cmd_ret = 1;

                memcpy(presult + 1, &cmd_result, sizeof(get_file_info));

                *ppresult = presult;
            } else {
                *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            }
            break;
        }
        case MCCMD_CLIENT_EXIT: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_CLIENT_EXIT cmd");
#endif
            client_exit_param *params = (client_exit_param *) (pcmd + 1);
            fun_ret = clientExit(params->pid);
            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_FIXPLIST: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_FIXPLIST cmd");
#endif

            fixplist_param *fix_param = (fixplist_param *) (pcmd + 1);
            fun_ret = 0;
            {
                NSString *fixPlistPath = [NSString stringWithUTF8String:fix_param->szPlistPath];
                // 安全校验：路径白名单
                if (!isPathAllowedForFileOp(fixPlistPath)) {
                    NSLog(@"[security] MCCMD_FIXPLIST: reject path: %@", fixPlistPath);
                    fun_ret = -1;
                } else if (!fixPlistFile(fix_param->szPlistPath, fix_param->szObjectKey)) {
                    fun_ret = -1;
                }
            }

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }

        case MCCMD_WRITEPLIST: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_WRITEPLIST cmd");
#endif

            writeplist_param *plist_param = (writeplist_param *) (pcmd + 1);
            fun_ret = 0;
            {
                NSString *writePlistPath = [NSString stringWithUTF8String:plist_param->szPlistPath];
                // 安全校验：路径白名单
                if (!isPathAllowedForFileOp(writePlistPath)) {
                    NSLog(@"[security] MCCMD_WRITEPLIST: reject path: %@", writePlistPath);
                    fun_ret = -1;
                } else if (!writePlistFile(plist_param->szPlistPath,
                        plist_param->szObjectKey,
                        plist_param->action_type,
                        plist_param->plist_type,
                        plist_param->obj_type,
                        plist_param->obj_data,
                        plist_param->obj_size)) {
                    fun_ret = -1;
                }
            }

            *ppresult = [self cmdSimpleReply:fun_ret magic:pcmd->cmd_magic];
            break;
        }

        case MCCMD_OWL_GET_OWL_DEVICE_PROCESS_INFO: {
            lemon_com_process_info *odp_info = NULL;
            owl_watch_device_param *param = (owl_watch_device_param *) (pcmd + 1);
            //[[OwlManageDaemon shareInstance] changeDeviceWatchState:param];
            fun_ret = [[OwlManageDaemon shareInstance] getDeviceWitchProcess:param pInfo:&odp_info];
            if (fun_ret == -1 || fun_ret == 0) {
                total_size = sizeof(mc_pipe_result) + sizeof(lemon_com_result);
            } else {
                total_size = sizeof(mc_pipe_result) + sizeof(lemon_com_result) + (fun_ret - 1) * sizeof(lemon_com_process_info);
            }

            // build result
            presult = (mc_pipe_result *) malloc(total_size);
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = fun_ret;

            if (fun_ret > 0) {
                lemon_com_result *podp_result = (lemon_com_result *) (presult + 1);
                podp_result->count = fun_ret;
                podp_result->info_size = fun_ret * sizeof(lemon_com_process_info);
                memcpy(podp_result->odp_info, odp_info, podp_result->info_size);
                //NSLog(@"[info] odp_info count: %d", podp_result->count);
                //for (int i = 0; i < fun_ret; i++) {
                //    NSLog(@"pid: %d, %d", podp_result->odp_info[i].pid, podp_result->odp_info[i].time_count);
                //}
            }

            if (odp_info != NULL) {
                free(odp_info);
                odp_info = NULL;
            }

            *ppresult = presult;
//            NSLog(@"[info] MCCMD_OWL_GET_lemon_com_process_info");
            break;
        }
        case MCCMD_OWL_WATCH_DEVICE_STATE: {
            owl_watch_device_param *param = (owl_watch_device_param *)(pcmd + 1);
            [[OwlManageDaemon shareInstance] changeDeviceWatchState:param];
#ifdef DEBUG
            NSLog(@"[info] MCCMD_OWL_WATCH_DEVICE_STATE");
#endif
            *ppresult = [self cmdSimpleReply:0 magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_UNINSTALL_KEXT_WITH_BUNDLEID: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_UNINSTALL_KEXT_WITH_BUNDLEID");
#endif
            NSInteger code = [LMKextManager uninstallKextWithBundleId:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_UNINSTALL_KEXT_WITH_PATH: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_UNINSTALL_KEXT_WITH_PATH");
#endif
            NSInteger code = [LMKextManager uninstallKextWithPath:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_RM_PKG_INFO_WITH_BUNDLEID: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_RM_PKG_INFO_WITH_BUNDLEID");
#endif
            NSInteger code = [self removePkgInfoBy:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_REMOVE_Login_Item: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_REMOVE_Login_Item");
#endif
            NSInteger code = [self removeLoginItem:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_COLLECT_LEMON_LOGINFO: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_COLLECT_LEMON_LOGINFO");
#endif
            NSInteger code = [self collectLemonLoginfo:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_NETWORK_FIREWALL_PF: {
#ifdef DEBUG
            NSLog(@"[info] MCCMD_NETWORK_FIREWALL_PF");
#endif
            NSInteger code = [self setLemonFirewallPortPF:pcmd];
            *ppresult = [self cmdSimpleReply:(int) code magic:pcmd->cmd_magic];
            break;
        }
        case MCCMD_GET_CPU_TEMP:
        {
            NSLog(@"[info] MCCMD_GET_CPU_TEMP");
            fs_param = (fsmon_param *) (pcmd + 1);
            double value;
            fun_ret = CmcGetCpuTemperature(&value);
            if (fun_ret == 0) {
                fun_ret = 1;
            }
            double *cpu_temp = malloc(sizeof(double) * fs_param->count);
            cpu_temp[0] = value;

            total_size = sizeof(mc_pipe_result) + sizeof(smc_result);
            if (fun_ret > 0) {
                total_size += (fun_ret - 1) * sizeof(double);
            }
            presult = (mc_pipe_result *) malloc(total_size);
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = fun_ret;

            if (fun_ret > 0) {
                smc_result *fs_result = (smc_result *) (presult + 1);
                fs_result->count = fun_ret;
                fs_result->info_size = fun_ret * sizeof(double);
                memcpy(fs_result->smc_info, cpu_temp, fs_result->info_size);
            }
            free(cpu_temp);

            *ppresult = presult;
            break;
        }
        case MCCMD_GET_FAN_SPEED:
        {
            NSLog(@"[info] MCCMD_GET_FAN_SPEED");
            fs_param = (fsmon_param *) (pcmd + 1);
            fun_ret = CmcGetFanCount();
            double *fSpeeds = malloc(sizeof(double) * fs_param->count);
            if (CmcGetFanSpeeds(fun_ret, fSpeeds) == -1) {
                fun_ret = -1;
            }
            total_size = sizeof(mc_pipe_result) + sizeof(smc_result);
            if (fun_ret > 0) {
                total_size += (fun_ret - 1) * sizeof(double);
            }
            presult = (mc_pipe_result *) malloc(total_size);
            presult->cmd_magic = pcmd->cmd_magic;
            presult->size = total_size;
            presult->cmd_ret = fun_ret;

            if (fun_ret > 0) {
                smc_result *fs_result = (smc_result *) (presult + 1);
                fs_result->count = fun_ret;
                fs_result->info_size = fun_ret * sizeof(double);
                memcpy(fs_result->smc_info, fSpeeds, fs_result->info_size);
            }
            free(fSpeeds);
            
            *ppresult = presult;
            break;
        }
        default:
            break;
    }
}

+ (void)cmdForStatPort:(mc_pipe_cmd *)pcmd result:(mc_pipe_result **)ppresult {

    if (pcmd == NULL || ppresult == NULL)
        return;

    *ppresult = NULL;
    int total_size;
    int fun_ret;
    mc_pipe_result *presult;
#ifdef DEBUG
    NSLog(@"[info] MCCMD_STAT_PORT_INFO");
#endif

    {
        NSString *cmdReturnStr = executeCmdAndGetResult(@"lsof -n -P |grep LISTEN");
#ifdef DEBUG
        NSLog(@"%s execute result is [%@]", __func__, cmdReturnStr);
#endif

        NSArray *items = [cmdReturnStr componentsSeparatedByString:@"\n"];
        NSMutableArray *portArray = [NSMutableArray array];
        for (NSString *item in items) {
            NSString *ss = @"[ ]{1,}(\\d+)[ ]{3,}";
            //ss = @" +(\\d+)\\ +";
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:ss options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *matches = [regex matchesInString:item options:0 range:NSMakeRange(0, [item length])];
            for (NSTextCheckingResult *match in matches) {
                for (int i = 0; i < [match numberOfRanges]; i++) {
                    NSString *component = [item substringWithRange:[match rangeAtIndex:i]];
                    component = [component stringByReplacingOccurrencesOfString:@" " withString:@""];
                    int pid = [component intValue];
                    NSMutableDictionary *portItem = [[NSMutableDictionary alloc] init];
                    portItem[@"PROC_ID"] = @(pid);
                    portItem[@"PROC_NAME"] = @"";
                    if ([item hasSuffix:@"(LISTEN)"]) {
                        portItem[@"PROC_STATE"] = @(1);
                    } else {
                        portItem[@"PROC_STATE"] = @(0);
                    }
                    NSString *port = [[item componentsSeparatedByString:@":"] lastObject];
                    port = [port stringByReplacingOccurrencesOfString:@" (LISTEN)" withString:@""];
                    portItem[@"PROC_PORT"] = @([port intValue]);
                    BOOL exist = NO;
                    for (NSDictionary *preItem in portArray) {
                        if (portItem[@"PROC_PORT"] == preItem[@"PROC_PORT"] &&
                                portItem[@"PROC_ID"] == preItem[@"PROC_ID"]) {
                            exist = YES;
                        }
                    }
                    if (exist) {
                        break;
                    }
                    [portArray addObject:portItem];
                }
            }
        }
#ifdef DEBUG
        NSLog(@"portArray: %@", portArray);
#endif

        fun_ret = (int) (portArray.count);
        lemon_com_process_info *odp_info = malloc(sizeof(lemon_com_process_info) * fun_ret);
        for (int i = 0; i < portArray.count; i++) {
            memset(&odp_info[i], 0, sizeof(lemon_com_process_info));
            NSDictionary *dicItem = [portArray objectAtIndex:i];
            odp_info[i].pid = (pid_t) [dicItem[@"PROC_ID"] intValue];
            odp_info[i].time_count = (int) [dicItem[@"PROC_PORT"] intValue];
            odp_info[i].device_type = (int) [dicItem[@"PROC_STATE"] intValue];
        }


        if (fun_ret == -1 || fun_ret == 0) {
            total_size = sizeof(mc_pipe_result) + sizeof(lemon_com_result);
        } else {
            total_size = sizeof(mc_pipe_result) + sizeof(lemon_com_result) + (fun_ret - 1) * sizeof(lemon_com_process_info);
        }

        // build result
        presult = (mc_pipe_result *) malloc(total_size);
        presult->cmd_magic = pcmd->cmd_magic;
        presult->size = total_size;
        presult->cmd_ret = fun_ret;

        if (fun_ret > 0) {
            lemon_com_result *podp_result = (lemon_com_result *) (presult + 1);
            podp_result->count = fun_ret;
            podp_result->info_size = fun_ret * sizeof(lemon_com_process_info);
            memcpy(podp_result->odp_info, odp_info, podp_result->info_size);
        }

        if (odp_info != NULL) {
            free(odp_info);
            odp_info = NULL;
        }

        *ppresult = presult;
    }
}

+ (unsigned long long)fastFolderSizeAtFSRef:(NSString *)path diskMode:(BOOL)diskMode {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                                    includingPropertiesForKeys:nil
                                                       options:0
                                                  errorHandler:nil];
    NSUInteger totalSize = 0;

    for (NSURL *pathURL in dirEnumerator) {
        @autoreleasepool {
            NSString *resultPath = [pathURL path];
            struct stat fileStat;
            if (lstat([resultPath fileSystemRepresentation], &fileStat) != 0)
                continue;
            if (fileStat.st_mode & S_IFDIR)
                continue;

            if (diskMode) {
                if (fileStat.st_flags != 0)
                    totalSize += (((fileStat.st_size +
                            4096 - 1) / 4096) * 4096);
                else
                    totalSize += fileStat.st_blocks * 512;

            } else
                totalSize += fileStat.st_size;

            if (CFAbsoluteTimeGetCurrent() - startTime > 10)
                break;
        }
    }
    return totalSize;
}


// system() 无法获取 shell 执行结果
// 至于获取结果, 可以使用 use `fork` and one of the `exec` functions directly. 或者
// NSTask and NSPipe 可以执行普通权限shell,并且获取结果. (在 Daemon 中是普通权限吗? ->root 权限, NSFileManager也能删除敏感文件了.)





+ (NSInteger)removeLoginItem:(mc_pipe_cmd *)pcmd {
    op_uninstall_kext *kext_param = (op_uninstall_kext *) (pcmd + 1);
    NSString *loginItemName = [NSString stringWithUTF8String:kext_param->szKext];
    if (!loginItemName || loginItemName.length < 1) {
        NSLog(@"%s stop execute because  login_item_name is %@", __func__, loginItemName == nil ? @"nil" : loginItemName);
        return 0;
    }
    NSLog(@"%s: login item name is %@", __func__, loginItemName);

    NSString *removeCmd = [NSString stringWithFormat:@"tell application \"System Events\" to delete every login item whose name is \"%@\"", loginItemName];
    NSLog(@"%s: exec cmd str is %@", __func__, removeCmd);
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:removeCmd];
    NSDictionary *error = nil;
    NSAppleEventDescriptor *output = [scriptObject executeAndReturnError:&error];
    NSLog(@"%s execute result is %@", __func__, error == nil ? @"success" : @"fail");
    if (error) {
        NSLog(@"applescript error is = %@", error);
        return -1;
    } else {
        NSLog(@"applescript output is = %@", output.stringValue);
        return 1;
    }
}

+ (NSInteger)removePkgInfoBy:(mc_pipe_cmd *)pcmd {
    op_simple_string *param = (op_simple_string *) (pcmd + 1);
    NSString *pkgBundleId = [NSString stringWithUTF8String:param->str];
    
    if (!pkgBundleId || pkgBundleId.length < 1) {
        NSLog(@"%s stop execute because  pkgBundleId is %@", __func__, pkgBundleId == nil ? @"nil" : pkgBundleId);
        return 0;
    }
    
    // 安全校验：bundleId 只允许 reverse-DNS 合法字符（字母、数字、点号、连字符）
    NSCharacterSet *allowedBundleIdChars = [NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-"];
    if ([pkgBundleId rangeOfCharacterFromSet:[allowedBundleIdChars invertedSet]].location != NSNotFound) {
        NSLog(@"[security] reject invalid pkgBundleId: %@", pkgBundleId);
        return -1;
    }
    
    NSLog(@"%s: pkgBundleId  is %@", __func__, pkgBundleId);
    
    NSString *resultStr = executeLaunchPathAndGetResult(@"/usr/sbin/pkgutil", @[@"--forget", pkgBundleId]);
    NSLog(@"%s: remove pkg info with pkgBundleId: %@, result is %@", __func__, pkgBundleId, resultStr);

    if(!resultStr || [resultStr containsString:@"Error"]){  //卸载失败的字符串类似于Unknown error Error ...
        return -2;
    }
    return 0;
}

+ (void)collectLemonInfoItems:(NSString *)filePath destPath:(NSString *)destPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    for (NSString *item in [fm contentsOfDirectoryAtPath:filePath error:&error]) {
        NSString *path = [filePath stringByAppendingPathComponent:item];
        if ([path localizedCaseInsensitiveContainsString:@"Lemon"]) {
            // 这里 相当于  cp  /path/to/source/aaa   /path/to/dest/bbb    destPath 是具体的路径,而不是 dir. 注意 cp 时,如果dest
            
            NSError *error = nil;

            BOOL isDir;
            if(![fm fileExistsAtPath:destPath isDirectory:&isDir]){  // 路径不存在时,创建路径
                if (![fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"create  path: %@ fail, stop execute, error:%@", destPath, error);
                    return;
                }
            }
            
            [fm copyItemAtPath:path toPath:[destPath stringByAppendingPathComponent:[path lastPathComponent]] error: &error];
            if(error != nil){
                NSLog(@"%s copyItemAtPath error:%@, srcPath:%@, toPath:%@", __FUNCTION__, error, path, [destPath stringByAppendingPathComponent:[path lastPathComponent]] );
            }
        }
    }
}

+ (NSInteger)collectLemonLoginfo:(mc_pipe_cmd *)pcmd {
    op_file_path *plist_param = (op_file_path *) (pcmd + 1);
    NSString *userHomeDir = [NSString stringWithUTF8String:plist_param->szPath];
    
    // 安全校验：只允许 /Users/<name> 格式的路径
    if (![userHomeDir hasPrefix:@"/Users/"] ||
        [userHomeDir containsString:@".."] ||
        [userHomeDir containsString:@";"] ||
        [userHomeDir containsString:@"|"] ||
        [userHomeDir containsString:@"&"] ||
        [userHomeDir containsString:@"`"] ||
        [userHomeDir containsString:@"$"]) {
        NSLog(@"[security] collectLemonLoginfo: reject invalid userHomeDir: %@", userHomeDir);
        return -1;
    }
    NSArray *pathComponents = [userHomeDir pathComponents];
    if (pathComponents.count < 3) {
        NSLog(@"[security] collectLemonLoginfo: reject too short userHomeDir: %@", userHomeDir);
        return -1;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *support = [userHomeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@/lemonLogInfoTemp", MAIN_APP_BUNDLEID]];
    if ([fm fileExistsAtPath:support]) {
        [fm removeItemAtPath:support error:nil];
    }
    NSError *error = nil;
    if (![fm createDirectoryAtPath:support withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"create collectLemonLoginfo support path fail");
    }

    [fm copyItemAtPath:[userHomeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Application Support/%@", MAIN_APP_BUNDLEID]] toPath:[support stringByAppendingPathComponent:@"LemonLog_ull"] error:nil];
    [fm copyItemAtPath:@"/Library/Application Support/Lemon/Version.log" toPath:[support stringByAppendingPathComponent:@"install_version.log"] error:nil];
    //NSLog(@"%s %@   %@", __FUNCTION__, [userName stringByAppendingPathComponent:@"Library/Preferences/com.tencent.Lemon.plist"], [support stringByAppendingPathComponent:@"com.tencent.Lemonpre.plist"]);
    [fm copyItemAtPath:[userHomeDir stringByAppendingPathComponent:@"Library/Preferences/com.tencent.Lemon.plist"] toPath:[support stringByAppendingPathComponent:@"com.tencent.Lemonpre.plist"] error:nil];

    if (![fm createDirectoryAtPath:[support stringByAppendingPathComponent:@"library_logs"] withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"create library_logs path fail");
    }
    
    [self collectLemonInfoItems:@"/Library/Logs" destPath:[support stringByAppendingPathComponent:@"library_logs"]];
    [self collectLemonInfoItems:[userHomeDir stringByAppendingPathComponent:@"Library/Logs"] destPath:support];
    [self collectLemonInfoItems:[userHomeDir stringByAppendingPathComponent:@"Library/Logs/DiagnosticReports"] destPath:[support stringByAppendingPathComponent:@"DiagnosticReports/userland"]];  //用户目录下
    [self collectLemonInfoItems:@"/Library/Logs/DiagnosticReports" destPath:[support stringByAppendingPathComponent:@"DiagnosticReports/root"]]; //系统目录

    NSString *sysinfo = [support stringByAppendingPathComponent:@"system_info.xml"];
    NSString *lemon_run_env_file = [support stringByAppendingPathComponent:@"lemon_run_env.log"];

    [[NSFileManager defaultManager] createFileAtPath:lemon_run_env_file contents:nil attributes:nil];
    NSMutableString *envLog = [NSMutableString stringWithString:@"sw_vers .....\n"];
    NSString *swVersOut = executeExecutableWithArguments(@"/usr/bin/sw_vers", @[]);
    if (swVersOut.length > 0) {
        [envLog appendString:swVersOut];
        if (![swVersOut hasSuffix:@"\n"]) {
            [envLog appendString:@"\n"];
        }
    }

    NSString *launchctlList = executeExecutableWithArguments(@"/bin/launchctl", @[@"list"]);
    [envLog appendString:@"launchctl list as root .....\n"];
    for (NSString *line in [launchctlList componentsSeparatedByString:@"\n"]) {
        if ([line localizedCaseInsensitiveContainsString:@"Lemon"]) {
            [envLog appendFormat:@"%@\n", line];
        }
    }
    [envLog writeToFile:lemon_run_env_file atomically:YES encoding:NSUTF8StringEncoding error:nil];


    // 无法打印用户态下面的 launchctl list.  sudo -u userName 执行的结果还是 root用户态下的结果,而非 userName 用户态下. 可能的解决方法是 "su - username -c 'cmd' &" 这里会切换用户态(且在子 shell 中,切换只在当前命令有效),但失败了, 在 root shell su 貌似没有-c命令
//    NSArray<NSString *> *userArray = getCurrentLogInUserName();
//    if(userArray && [userArray count] >0){
//        NSString *userName = userArray[0];
//        NSString* userPrefixCmd = [NSString stringWithFormat:@"echo 'launchctl list as user..... user is %@' >> %@", userName, lemon_run_env_file];
//        system([userPrefixCmd UTF8String]);
//        NSString* userLaunchCtlCmd = [NSString stringWithFormat:@"sudo -u %@ launchctl list | grep Lemon >> %@", userName, lemon_run_env_file];
//        system([userLaunchCtlCmd UTF8String]);
//    }
//

    //NSString* cmdReturnStr = [self excuteCmd:cmd1];

    NSString *sysProfile = executeExecutableWithArguments(@"/usr/sbin/system_profiler", @[@"-xml", @"SPHardwareDataType"]);
    if (sysProfile) {
        [sysProfile writeToFile:sysinfo atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return 1;
}

+ (NSInteger)setLemonFirewallPortPF:(mc_pipe_cmd *)pcmd {
    lm_sz_com_param *com_param = (lm_sz_com_param *) (pcmd + 1);
    NSString *tcpPorts = [NSString stringWithUTF8String:com_param->szParam1];
    NSString *udpPorts = [NSString stringWithUTF8String:com_param->szParam2];
    NSLog(@"%s, tcpPorts: %@, udpPorts: %@", __func__, tcpPorts, udpPorts);
    NSCharacterSet *allowedPorts = [NSCharacterSet characterSetWithCharactersInString:@"0123456789, "];
    if ((tcpPorts.length > 0 && [tcpPorts rangeOfCharacterFromSet:[allowedPorts invertedSet]].location != NSNotFound) ||
        (udpPorts.length > 0 && [udpPorts rangeOfCharacterFromSet:[allowedPorts invertedSet]].location != NSNotFound)) {
        NSLog(@"[security] setLemonFirewallPortPF: reject invalid port list tcp=%@ udp=%@", tcpPorts, udpPorts);
        return -1;
    }
    NSString *strPfFile = @"/etc/pf.conf";
    NSError *error;
    NSString *strPF = [NSString stringWithContentsOfFile:strPfFile encoding:NSUTF8StringEncoding error:&error];
    //int oldLength = [strPF length];
    if (error) {
        NSLog(@"%s read pf.conf error:%@", __FUNCTION__, error);
        return -1;
    }
    if (strPF == nil) {
        strPF = @"";
    }
    NSRange rangeBegin = [strPF rangeOfString:@"# lemon fw filter begin"];
    if (rangeBegin.location != NSNotFound) {
        NSRange rangeEnd = [strPF rangeOfString:@"# lemon fw filter end"];
        if (rangeBegin.location != NSNotFound) {
            NSString *strOldFilter = [strPF substringWithRange:NSMakeRange(rangeBegin.location, rangeEnd.location + rangeEnd.length - rangeBegin.location)];
            strPF = [strPF stringByReplacingOccurrencesOfString:strOldFilter withString:@""];

        }
    }
    if ([tcpPorts length] != 0 || [udpPorts length] != 0) {
        NSString *lemonFilter = @"# lemon fw filter begin\n";
        if (![strPF hasSuffix:@"\n"]) {
            lemonFilter = @"\n# lemon fw filter begin\n";
        }
        if ([tcpPorts length] != 0) {
            lemonFilter = [lemonFilter stringByAppendingString:@"lemontcpports = \"{ "];
            lemonFilter = [lemonFilter stringByAppendingString:tcpPorts];
            lemonFilter = [lemonFilter stringByAppendingString:@" }\"\n"];
            lemonFilter = [lemonFilter stringByAppendingString:@"block drop in proto tcp from any port $lemontcpports to any\n"];
        }
        if ([udpPorts length] != 0) {
            lemonFilter = [lemonFilter stringByAppendingString:@"lemonudpports = \"{ "];
            lemonFilter = [lemonFilter stringByAppendingString:udpPorts];
            lemonFilter = [lemonFilter stringByAppendingString:@" }\"\n"];
            lemonFilter = [lemonFilter stringByAppendingString:@"block drop in proto udp from any port $lemonudpports to any\n"];
        }
        lemonFilter = [lemonFilter stringByAppendingString:@"# lemon fw filter end"];
        strPF = [strPF stringByAppendingString:lemonFilter];
    }

    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:strPfFile];
    if (!file) {
        NSLog(@"%s write pf.conf error:%d", __FUNCTION__, errno);
        return -1;
    }
    [file truncateFileAtOffset:0];
    [file writeData:[NSData dataWithBytes:[strPF UTF8String] length:[strPF length]]];
    [file closeFile];

    NSString *cmdReturnStr = executeExecutableWithArguments(@"/sbin/pfctl", @[@"-ef", strPfFile]);
    NSLog(@"%s execute result is [%@]", __func__, cmdReturnStr);

    return 1;
}


int kill_proc_if_match_keyword(mc_pipe_cmd *pcmd, mc_pipe_result **ppresult) {
    op_simple_int_with_string *kill_param_with_keyword = (op_simple_int_with_string *) (pcmd + 1);
    int pid = kill_param_with_keyword->i;
    NSString *keyword = [[NSString alloc]initWithUTF8String:kill_param_with_keyword->str];
    
    if(keyword.length <1){
        NSLog(@"%s stop kill process because key word is %@ ", __FUNCTION__, keyword);
        return -3;
    }
    
    
    char namebuf[PROC_PIDPATHINFO_MAXSIZE] = {0};
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE] = {0};
    int ret1 = proc_name(pid, namebuf, sizeof(namebuf));
    int ret2 = proc_pidpath (pid, pathbuf, sizeof(pathbuf));
    
    NSString *procName;
    NSString *procPath;
    
    BOOL nameMath = FALSE;
    BOOL pathMath = FALSE;
    if (ret1 > 0){
        procName = [NSString stringWithUTF8String:namebuf];
        nameMath = procName.length > 0 ? [procName containsString:keyword]: FALSE;
    }
    if( ret2 > 0){
        procPath = [NSString stringWithUTF8String:pathbuf];
        pathMath = procPath.length > 0 ? [procPath containsString:keyword]: FALSE;
        
    }
    NSLog(@"%s kill pid is %d, keyword is %@, name is %@, path is %@", __FUNCTION__, pid, keyword, procName, procPath);
    
    if(!nameMath && !pathMath){
        NSLog(@"%s stop kill process because key word not match", __FUNCTION__);
        return -4;
    }
    
    // dont kill self
    int fun_ret = -1;
    if (pid != getpid()) {
        fun_ret = kill(pid, SIGKILL);
    }
    
    return fun_ret;
}
@end
