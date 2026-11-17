//
//  ExecuteCmdHelper.m
//  LemonDaemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#include "ExecuteCmdHelper.h"

NSString* executeCmdAndGetResult(NSString *cmd)
{
    if (cmd.length == 0) {
        return nil;
    }
    return executeLaunchPathAndGetResult(@"/bin/bash", @[@"-c", cmd]);
}

NSString* executeLaunchPathAndGetResult(NSString *launchPath, NSArray<NSString *> *arguments)
{
    if (launchPath.length == 0 || arguments == nil) {
        return nil;
    }
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSPipe pipe]];
    NSFileHandle *file = [pipe fileHandleForReading];
    @try {
        [task launch];
    } @catch (NSException *exception) {
        NSLog(@"%s, launch failed: %@, path=%@ args=%@", __FUNCTION__, exception, launchPath, arguments);
        return nil;
    }
    NSData *data = [file readDataToEndOfFile];
    [task waitUntilExit];
    [file closeFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

int executeLaunchPath(NSString *launchPath, NSArray<NSString *> *arguments)
{
    if (launchPath.length == 0 || arguments == nil) {
        return -1;
    }
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    @try {
        [task launch];
        [task waitUntilExit];
        return task.terminationStatus;
    } @catch (NSException *exception) {
        NSLog(@"%s, launch failed: %@, path=%@ args=%@", __FUNCTION__, exception, launchPath, arguments);
        return -1;
    }
}

NSString* executeExecutableWithArguments(NSString *launchPath, NSArray<NSString *> *arguments)
{
    return executeLaunchPathAndGetResult(launchPath, arguments ?: @[]);
}

int executeExecutableWithArgumentsGetStatus(NSString *launchPath, NSArray<NSString *> *arguments)
{
    return executeLaunchPath(launchPath, arguments ?: @[]);
}
