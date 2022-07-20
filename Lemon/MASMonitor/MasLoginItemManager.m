//
//  MasLoginItemManager.m
//  Lemon
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "MasLoginItemManager.h"
#import <Foundation/Foundation.h>
#import <ServiceManagement/SMLoginItem.h>

#define SHOW_GET_DIR_ACCESS @"show_get_dir_access"
#define MAS_MONITOR_APP_NAME @"88L2Q4487U.com.tencent.LemonASMonitor.app"
#define MAS_MONITOR_BUNDLE_ID @"88L2Q4487U.com.tencent.LemonASMonitor"
#define MAS_IS_CONNECTION_XPC @"mas_is_connection_xpc"
#define MAS_MONITOR_EXIT @"mas_monitor_exit"

@interface MasLoginItemManager()

@property (nonatomic, strong) NSXPCConnection *connection;

@end

@implementation MasLoginItemManager{
     id <MASXPCAgent> _agent;
}

-(instancetype)init{
    self = [super init];
    if(self){
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(checkIsConnection) name:MAS_IS_CONNECTION_XPC object:nil];
    }
    
    return self;
}

-(void)checkIsConnection{
    if(self.connection == nil){
        NSLog(@"checkIsConnection没有连接 发起xpc连接");
        [self setupMASXpcWhenLogItemRunning];
    }else{
        NSLog(@"checkIsConnection已经连接");
    }
}

-(void)dealloc{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (id)sharedManager
{
    static dispatch_once_t onceToken = 0;
    __strong static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}


-(BOOL)enableLoginItemAndXpcAtGuidePage{
    NSError *error = nil;
    NSString *bundleId = MAS_MONITOR_BUNDLE_ID;
    if(bundleId == nil){
        NSLog(@"%s Failed to get bundle identifier", __FUNCTION__);
        return NO;
    }
    
    BOOL flag = [self enableMASLoginItem:bundleId error:&error];
    [self setupMASMonitorXpcConnection:bundleId];
    return flag;
}

-(BOOL) disAbleLoginItem{
    NSError *error = nil;
    NSString *bundleId = MAS_MONITOR_BUNDLE_ID;
    if(bundleId == nil){
        NSLog(@"%s Failed to get bundle identifier", __FUNCTION__);
        return NO;
    }
    BOOL flag = [self disableMASLoginItem:bundleId error:&error];
    return flag;
}

-(void) setupMASXpcWhenLogItemRunning{
    NSString *bundleId = MAS_MONITOR_BUNDLE_ID;
    if(bundleId == nil){
        NSLog(@"%s Failed to get bundle identifier", __FUNCTION__);
        return ;
    }
    
    if ([self isMASLoginItemRunning]){
        [self setupMASMonitorXpcConnection:bundleId];
    }
    
}

//通知托盘自动退出
-(void) notiMonitorExit{
    __weak MasLoginItemManager *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.connection == nil) {
            [self buildXPCConnection];
        }
        self->_agent = [weakSelf.connection remoteObjectProxyWithErrorHandler:^(NSError *err) {
            NSLog(@"mas loginItem remoteObjectProxyWithErrorHandler error :%@", err);
        }];
        
        [self->_agent sendMessage:MAS_MONITOR_EXIT];
    });
}

// 设置为 LoginItem 并且
-(void) setupMASMonitorXpcConnection:(NSString*)bundleId{
    
    NSLog(@"开始连接");
    __weak MasLoginItemManager *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf buildXPCConnection];
    });
}

-(void)buildXPCConnection{
    NSError *error = nil;
    
    NSString *bundleId = MAS_MONITOR_BUNDLE_ID;
    NSXPCConnection *connection  = [[NSXPCConnection alloc] initWithMachServiceName:bundleId options:0];
    if (connection == nil) {
        NSLog(@"Failed to connect to login item: %@\n", [error description]);
        return;
    }
    
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MASXPCAgent)];
    connection.exportedObject = self;
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MASXPCAgent)];
    [connection resume];
    self.connection = connection;
    
    NSLog(@"连接 = %@", connection);
    
    // Get a proxy DecisionAgent object for the connection.
    self->_agent = [connection remoteObjectProxyWithErrorHandler:^(NSError *err) {
        NSLog(@"mas loginItem remoteObjectProxyWithErrorHandler error :%@", err);
    }];
    
    NSLog(@"连接结束");
    [self->_agent sendMessage:@"start"];
}

-(void)sendMessage:(NSString *)message{
    if ([message isEqualToString:@"show_pref_setting"]) {
        NSLog(@"开始显示设置页面");
        __weak MasLoginItemManager *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:OPEN_LOGIN_ITEM_PREFRENCE object:nil];
            self->_agent = [weakSelf.connection remoteObjectProxyWithErrorHandler:^(NSError *err) {
                NSLog(@"mas loginItem remoteObjectProxyWithErrorHandler error :%@", err);
            }];
            
            [self->_agent sendMessage:@"show_success"];
        });
    }else if ([message isEqualToString:@"show_get_dir_access"]){
        NSLog(@"请求打开文件夹权限");
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_GET_DIR_ACCESS object:nil];
        self->_agent = [self.connection remoteObjectProxyWithErrorHandler:^(NSError *err) {
            NSLog(@"mas loginItem remoteObjectProxyWithErrorHandler error :%@", err);
        }];
        
        [self->_agent sendMessage:@"show_success"];
    }
}

// mas monitor 是否正在运行
-(BOOL)isMASLoginItemRunning{
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAS_MONITOR_BUNDLE_ID].count == 0)
    {
        return NO;
    }else{
        return YES;
    }
}

- (BOOL) enableMASLoginItem:(NSString *)loginItemBundleId error:(NSError **)errorp{
    
    // Enable the login item.
    // This will start it running if it wasn't already running.
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)loginItemBundleId, true)) {
        if (errorp != NULL) {
            *errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
                                                                                NSLocalizedFailureReasonErrorKey: @"enableMASLoginItem SMLoginItemSetEnabled() failed"
                                                                                         }];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL) disableMASLoginItem:(NSString *)loginItemBundleId  error:(NSError **)errorp{
    
    // Enable the login item.
    // This will start it running if it wasn't already running.
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)loginItemBundleId, false)) {
        if (errorp != NULL) {
            *errorp = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{
                                                                                NSLocalizedFailureReasonErrorKey: @"disableMASLoginItem SMLoginItemSetEnabled() failed"
                                                                                         }];
        }
        return FALSE;
    }
    
    return YES;
}
@end
