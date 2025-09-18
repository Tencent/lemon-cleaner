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
#import "QMNetworkSpeedCalculator.h"
#import "QMNetTopHelp.h"
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
    NSMutableDictionary *nameMap = [NSMutableDictionary dictionary];
    NSMutableArray *childProcesses = [NSMutableArray array];
    __block McProcessInfoData *safariProcess = nil;
    NSMutableArray *safariWebContent = [NSMutableArray array];
    
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(McProcessInfoData *processInfo, NSDictionary *bindings) {
        pid_t pid = processInfo.pid;
        
        // 过滤自身
        if (pid == myPid) return NO;
        
        NSString *path = processInfo.pExecutePath;
        // 过滤被结束的应用
        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
        // 过滤自身/插件与Agent
        if ([app.bundleIdentifier hasPrefix:@"com.tencent.LemonMonitor"]) return NO;
        if ([app.bundleIdentifier hasPrefix:@"com.tencent.Lemon"]) return NO;
        if ([[path lastPathComponent] isEqualToString:@"LemonDaemon"]) return NO;
        
        pid_t ppid = processInfo.ppid;
        NSRunningApplication *parentApp = [NSRunningApplication runningApplicationWithProcessIdentifier:ppid];
        if (parentApp) {
            [childProcesses addObject:processInfo];
            return NO;
        }
        
        // com.apple.WebKit.Networking 特殊处理
        if ([processInfo.pName isEqualToString:@"com.apple.WebKit.Networking"]) {
            [childProcesses addObject:processInfo];
            return NO;
        }
        NSString *localizedName = app.localizedName;
        if (localizedName) {
            nameMap[localizedName] = processInfo;
        }
        pidMap[@(pid)] = processInfo;
        return YES;
    }];
    
    NSArray *processArray = [[McCoreFunction shareCoreFuction] processInfo:NULL totalMemory:NULL];
    NSArray *sample = [processArray filteredArrayUsingPredicate:filter];
    if (self.isProcessPortStat) {
        self.originProcessInfoArray = processArray;
    }
//    NSDictionary *flowSpeed = [QMNetTopMonitor flowSpeed];
    // 使用nettop 替换 socket
    NSDictionary *flowSpeed = [QMNetworkSpeedCalculator calculateNetworkSpeed];
    
    for (McProcessInfoData *procInfo in sample)
    {
        NSDictionary *flowInfo = [flowSpeed objectForKey:@(procInfo.pid)];
        procInfo.upSpeed = [flowInfo[kUpNetKey] doubleValue];
        procInfo.downSpeed = [flowInfo[kDownNetKey] doubleValue];
    }
    
    
    for (McProcessInfoData *childProcess in childProcesses) {
        
        McProcessInfoData *parent = nil;
        if ([childProcess.pName isEqualToString:@"com.apple.WebKit.Networking"]) {
            // com.apple.WebKit.Networking 特殊处理
            NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:childProcess.pid];
            NSString *localizedName = app.localizedName;
            NSString *pLocalizedName = [self stringByRemovingNetworkingSuffixFromString:localizedName];
            if (pLocalizedName) {
                parent = nameMap[pLocalizedName];
                if (!parent) {
                    NSLog(@"Warning: Failed to find parent process for localizedName: %@", localizedName);
                }
            }
        } else {
            parent = pidMap[@(childProcess.ppid)];
        }
        
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
    
    self.processInfoArray = sample;
}

- (void)setProcessPortStat:(BOOL)isStat{
    self.isProcessPortStat = isStat;
    if (!isStat){
        self.originProcessInfoArray = [NSMutableArray array];
    }
}

- (NSString *)stringByRemovingNetworkingSuffixFromString:(NSString *)string {
    if (!string) return nil;
    NSString *suffix = @"Networking";
    // 使用 rangeOfString:options: 从后向前匹配，确保是结尾且忽略大小写
    NSRange range = [string rangeOfString:suffix options:(NSBackwardsSearch | NSCaseInsensitiveSearch)];
    if (range.location != NSNotFound && NSMaxRange(range) == string.length) {
        NSString *trimmed = [string substringToIndex:range.location];
        return [trimmed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return nil;
}

@end
