//
//  LMPlistHelper.m
//  LemonDaemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMPlistHelper.h"
#import "CmcProcess.h"
#import "ExecuteCmdHelper.h"

// 执行 launchctl 命令（使用 NSTask 直接调用，不经过 shell）
// @param arguments launchctl 的参数数组（不含 /bin/launchctl 本身）
// return: -1：执行失败
//          0: launchctl成功执行
//         >0: launchctl执行错误。
static int execlaunchctlArgs(NSArray<NSString *> *arguments) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = arguments;

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError  = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"%s: NSTask exception: %@, args=%@", __FUNCTION__, exception, arguments);
        return -1;
    }

    int exitStatus = task.terminationStatus;

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    if (output.length > 0) {
        NSLog(@"%s: args=%@, exit=%d, output=%@", __FUNCTION__, arguments, exitStatus, output);
    } else {
        NSLog(@"%s: args=%@, exit=%d (%@)", __FUNCTION__, arguments, exitStatus, getErrorStr(exitStatus));
    }
    return exitStatus;
}

// 兼容层：将原有的命令字符串拆分为参数数组，转发给 execlaunchctlArgs
int execlaunchctlCmd(NSString *cmd) {
    NSLog(@"%s: %@", __FUNCTION__, cmd);
    NSArray<NSString *> *components = [cmd componentsSeparatedByString:@" "];
    // 跳过第一个 "launchctl"，取后面的参数
    if (components.count > 1 && [components[0] isEqualToString:@"launchctl"]) {
        return execlaunchctlArgs([components subarrayWithRange:NSMakeRange(1, components.count - 1)]);
    }
    // 如果不是以 launchctl 开头，直接把所有 component 当参数
    return execlaunchctlArgs(components);
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
        NSString *userName = executeExecutableWithArguments(@"/usr/bin/id", @[@"-nu", [NSString stringWithFormat:@"%u", [idNum unsignedIntValue]]]);
        userName = [userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(userName.length > 0){
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

// 安全校验：plist 路径是否合法（白名单前缀 + 无注入字符）
static BOOL isValidPlistPath(NSString *plist) {
    if (!plist || plist.length == 0) return NO;
    if (![plist hasPrefix:@"/Library/LaunchDaemons/"] &&
        ![plist hasPrefix:@"/Library/LaunchAgents/"]) {
        return NO;
    }
    if ([plist containsString:@".."] || [plist containsString:@";"] ||
        [plist containsString:@"|"] || [plist containsString:@"&"] ||
        [plist containsString:@"`"] || [plist containsString:@"$"] ||
        [plist containsString:@"'"] || [plist containsString:@"\""]) {
        return NO;
    }
    return YES;
}

// 安全校验：label 是否合法（只允许字母、数字、点号、连字符、下划线）
static BOOL isValidLabel(NSString *label) {
    if (!label || label.length == 0) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_"];
    return [label rangeOfCharacterFromSet:[allowed invertedSet]].location == NSNotFound;
}

int unloadPlistByLable(NSString *plistLable) {
    if (!isValidLabel(plistLable)) {
        NSLog(@"[security] unloadPlistByLable: reject invalid label: %@", plistLable);
        return -1;
    }
    return execlaunchctlArgs(@[@"remove", plistLable]);
}

int unloadAgentPlistByLabel(NSString *plistLable, uid_t uid) {
    if (!isValidLabel(plistLable)) {
        NSLog(@"[security] unloadAgentPlistByLabel: reject invalid label: %@", plistLable);
        return -1;
    }
    return execlaunchctlArgs(@[@"asuser", [NSString stringWithFormat:@"%d", uid], @"launchctl", @"remove", plistLable]);
}

int unloadAgentPlistByLableForAllUser(NSString *plistLable) {
    NSArray<NSNumber *> * uidArray = getCurrentLogInUserId();
    for (NSNumber *uid in uidArray) {
        unloadAgentPlistByLabel(plistLable, [uid intValue]);
    }
    return 0;
}

int unloadPlist(NSString *plist) {
    if (!isValidPlistPath(plist)) {
        NSLog(@"[security] unloadPlist: reject invalid path: %@", plist);
        return -1;
    }
    return execlaunchctlArgs(@[@"unload", plist]);
}

int unloadAgentPlist(NSString *plist, uid_t uid) {
    if (!isValidPlistPath(plist)) {
        NSLog(@"[security] unloadAgentPlist: reject invalid path: %@", plist);
        return -1;
    }
    return execlaunchctlArgs(@[@"asuser", [NSString stringWithFormat:@"%d", uid], @"launchctl", @"unload", plist]);
}

int unloadAgentPlistForUser(NSString *plist, int userPid, NSString *userName) {
    if (!isValidPlistPath(plist)) {
        NSLog(@"[security] unloadAgentPlistForUser: reject invalid path: %@", plist);
        return -1;
    }
    (void)userName;
    return execlaunchctlArgs(@[@"bsexec",
                               [NSString stringWithFormat:@"%d", userPid],
                               @"/bin/launchctl",
                               @"unload",
                               plist]);
}

int loadPlist(NSString *plist) {
    if (!isValidPlistPath(plist)) {
        NSLog(@"[security] loadPlist: reject invalid path: %@", plist);
        return -1;
    }
    return execlaunchctlArgs(@[@"load", @"-w", plist]);
}
