//
//  QMSampleStorage.m
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "QMSampleStorage.h"
#import <libproc.h>
#import "McCoreFunction.h"
#import "McCpuInfo.h"
#import "QMNetTopMonitor.h"
#import <libproc.h>

#define TIMEVAL_TO_UINT64(a) ((unsigned long long)((a)->tv_sec) * 1000000ULL + (a)->tv_usec)

@interface QMSampleStorage ()
@property (strong) NSArray *originProcessInfoArray;
@property (strong) NSArray *processInfoArray;
@end

@implementation QMSampleStorage
{
    NSArray *_originProcessInfoArray;
    NSArray *_processInfoArray;
    NSArray *_cpuUsageList;
    uint64_t _lastSampleTime;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.originProcessInfoArray = [NSMutableArray array];
        self.isProcessPortStat = NO;
    }
    return self;
}

- (void)sample
{
    pid_t myPid = [NSProcessInfo processInfo].processIdentifier;
    
    NSMutableDictionary *pidMap = [NSMutableDictionary dictionary];
    NSMutableArray *childProcesses = [NSMutableArray array];
    __block McProcessInfoData *safariProcess = nil;
    NSMutableArray *safariWebContent = [NSMutableArray array];
    
    
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(McProcessInfoData *processInfo, NSDictionary *bindings) {
        pid_t pid = processInfo.pid;
        
        if (pid == 1184) {
            
        }
        // 过滤自身
        if (pid == myPid) return NO;
        
        BOOL (^testPath)(NSString *) = ^BOOL (NSString *execPath) {
            return [execPath hasPrefix:@"/Applications/"] || [execPath hasPrefix:@"/Users/"] || [execPath hasPrefix:@"/Volumes/"];
        };
        NSString *path = processInfo.pExecutePath;
        // 过滤被结束的应用
        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
        if (app) {
            // 过滤自身/插件与Agent
            if ([app.bundleIdentifier hasPrefix:@"com.tencent.LemonMonitor"]) return NO;
            if ([app.bundleIdentifier hasPrefix:@"com.tencent.Lemon"]) return NO;
            if ([[path lastPathComponent] isEqualToString:@"LemonDaemon"]) return NO;
            
            if ([app.bundleIdentifier isEqualToString:@"com.apple.Safari"]) {
                safariProcess = processInfo;
            } else if ([[app.executableURL path] hasPrefix:@"/System/Library/Frameworks/WebKit.framework/"])        {
                [safariWebContent addObject:processInfo];
            } else {
                // 判断是否父进程为/Applications或/Home目录下的
                pid_t ppid = processInfo.ppid;
                NSRunningApplication *parentApp = [NSRunningApplication runningApplicationWithProcessIdentifier:ppid];
                if (parentApp) {
                    NSString *execPath = [app.executableURL path];
                    if (testPath(execPath)) {
                        [childProcesses addObject:processInfo];
                        return NO;
                    }
                }
            }
        }
        if (testPath(path)) {
            pidMap[@(pid)] = processInfo;
            return YES;
        }
        return NO;
    }];
    
    NSArray *processArray = [[McCoreFunction shareCoreFuction] processInfo:NULL totalMemory:NULL];
    NSArray *sample = [processArray filteredArrayUsingPredicate:filter];
    if (self.isProcessPortStat) {
        self.originProcessInfoArray = processArray;
    }
    NSDictionary *flowSpeed = [QMNetTopMonitor flowSpeed];
    
    for (McProcessInfoData *procInfo in sample)
    {
        NSDictionary *flowInfo = [flowSpeed objectForKey:@(procInfo.pid)];
        procInfo.upSpeed = [flowInfo[kUpNetKey] doubleValue];
        procInfo.downSpeed = [flowInfo[kDownNetKey] doubleValue];
    }
    
    
    for (McProcessInfoData *childProcess in childProcesses) {
        McProcessInfoData *parent = pidMap[@(childProcess.ppid)];
        if (parent) {
            parent.cpuUsage += childProcess.cpuUsage;
            parent.resident_size += childProcess.resident_size;
            
            NSDictionary *childFlowInfo = [flowSpeed objectForKey:@(childProcess.pid)];
            if (childFlowInfo) {
                parent.upSpeed += [childFlowInfo[kUpNetKey] doubleValue];
                parent.downSpeed += [childFlowInfo[kDownNetKey] doubleValue];
            }
        }
    }
    
    if (safariProcess) {
        for (McProcessInfoData *webContentProcess in safariWebContent) {
            safariProcess.cpuUsage += webContentProcess.cpuUsage;
            safariProcess.resident_size += webContentProcess.resident_size;
            NSDictionary *flowInfo = [flowSpeed objectForKey:@(webContentProcess.pid)];
            safariProcess.upSpeed += [flowInfo[kUpNetKey] doubleValue];
            safariProcess.downSpeed += [flowInfo[kDownNetKey] doubleValue];
        }
    }
    
    self.processInfoArray = sample;
}

- (void)setProcessPortStat:(BOOL)isStat{
    self.isProcessPortStat = isStat;
    if (!isStat){
        self.originProcessInfoArray = [NSMutableArray array];
    }
}

@end
