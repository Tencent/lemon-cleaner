//
//  LemonDNCServer.m
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LemonMonitorDNCServer.h"
#import "LemonMonitorDNCClient.h"
#import "LemonDNCDefine.h"
#import <QMCoreFunction/QMFullDiskAccessManager.h>

@implementation LemonMonitorDNCServer

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static LemonMonitorDNCServer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)addServer {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(restartNotification:) name:LemonDNCRestartNotificationName object:nil];
}

- (void)restartNotification:(NSNotification *)notify {
    LemonDNCRestartType type = [notify.userInfo[LemonDNCRestartUserInfoTypeKey] unsignedIntegerValue];
    LemonDNCRestartReason reason = [notify.userInfo[LemonDNCRestartUserInfoReasonKey] unsignedIntegerValue];
    
    if (type == LemonDNCRestartTypeMonitor) {
        if (reason == LemonDNCRestartReasonFullDiskAccess) {
            if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized) {
                return;
            }
        }
        
        // 无完全磁盘访问权限，无法拉起自己。让其他进程帮助拉起自己
        [[LemonMonitorDNCClient sharedInstance] helpStart];
         
        [NSApp terminate:nil];
    }
}

@end
