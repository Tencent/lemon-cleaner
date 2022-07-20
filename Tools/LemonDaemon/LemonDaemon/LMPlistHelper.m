//
//  LMPlistHelper.m
//  LemonDaemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMPlistHelper.h"
#import "CmcProcess.h"
#import "ExecuteCmdHelper.h"

// 执行launchctl命令
// return: -1：执行失败
//          0: launchctl成功执行
//         >0: launchctl执行错误。
int execlaunchctlCmd(NSString *cmd) {
    pid_t status = system([cmd UTF8String]);
    //system命令执行错误
    NSLog(@"%s: %@ status:0x%x", __FUNCTION__, cmd, status);
    if (-1 == status) {
        NSLog(@"%s: %@, system error: 0x%x", __FUNCTION__, cmd, status);
        return -1;
    }
    //cmd执行成功
    if (WIFEXITED(status)) {
        NSLog(@"%s: %@, run successfully and exit with return value:%d, %@", __FUNCTION__, cmd, WEXITSTATUS(status), getErrorStr(WEXITSTATUS(status)));
        return WEXITSTATUS(status);
    }
    
    NSLog(@"%s: %@, run error", __FUNCTION__, cmd);
    return -1;
}


NSArray<NSNumber *> * getCurrentLogInUserId() {
    ProcessInfo_t *proc_info = NULL;
    int ret = CmcGetProcessInfo(McprocNone, 0, NO, &proc_info);
    NSMutableArray* uid_array = [[NSMutableArray alloc] init];
    if (ret > 0)
    {
        NSString *exeName;
        for (int i = 0; i < ret; i++)
        {
            exeName = [[NSString stringWithUTF8String:proc_info[i].pExecutePath] lastPathComponent];
            if ([exeName isEqualToString:@"Dock"])
            {
                [uid_array addObject:[NSNumber numberWithInt:proc_info[i].uid]];
            }
        }
    }
    if (proc_info != NULL)
        free(proc_info);
    
    return [uid_array copy];;
}

NSArray<NSString *> * getCurrentLogInUserName(void){
    NSArray<NSNumber *>* idArray = getCurrentLogInUserId();
    NSMutableArray<NSString *>* mutableArray = [NSMutableArray array];
    for(NSNumber* idNum in idArray){
        NSString *getNameByUserIdCmd = [NSString stringWithFormat:@"id -nu %u", [idNum intValue]];
        NSString* userName = executeCmdAndGetResult(getNameByUserIdCmd);
        if(userName){
            [mutableArray addObject:userName];
        }
    }
    return [mutableArray copy];
}



//launchctl error NUMBER, 可以看到各个返回值的意义
NSString *getErrorStr(int returnno) {
    switch (returnno) {
        case 0:
            return @"successed";
            break;
        case 1:
            return @"Operation not permitted";
            break;
        case 2:
            return @"No such file or directory";
            break;
        case 3:
            return @"No such process";
            break;
        default:
            return @"unknown error number";
            break;
    }
}

int unloadPlistByLable(NSString *plistLable) {
    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl remove %@", plistLable];
    return execlaunchctlCmd(unloadCmd);
}

int unloadAgentPlistByLabel(NSString *plistLable, uid_t uid) {
    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl asuser %d launchctl remove %@",  uid, plistLable];
    return execlaunchctlCmd(unloadCmd);
}

int unloadAgentPlistByLableForAllUser(NSString *plistLable) {
    NSArray<NSNumber *> * uidArray = getCurrentLogInUserId();
    for (NSNumber *uid in uidArray) {
        unloadAgentPlistByLabel(plistLable, [uid intValue]);
    }
    return 0;
}

int unloadPlist(NSString *plist) {
    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl unload %@", plist];
    return execlaunchctlCmd(unloadCmd);
}

int unloadAgentPlist(NSString *plist, uid_t uid) {
    NSString *unloadCmd = [NSString stringWithFormat:@"launchctl asuser %d launchctl unload %@", uid,  plist];
    return execlaunchctlCmd(unloadCmd);
}

int loadPlist(NSString *plist) {
    NSString *cmd = [NSString stringWithFormat:@"launchctl load -w %@", plist];
    return execlaunchctlCmd(cmd);
}
