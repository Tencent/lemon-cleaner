//
//  LMXpcClientManager.m
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMXpcClientManager.h"
#import "LMDaemonXPCProtocol.h"
#import "LMLemonXPCClient.h"
#import "LMMonitorXPCClient.h"
#import "LMDaemonStartupHelper.h"

@interface LMXpcClientManager ()

@property (nonatomic, strong, readwrite) NSXPCConnection *connectionToService;
@property (nonatomic, strong, readwrite) LMLemonXPCClient *lemonDelegate;
@property (nonatomic, strong, readwrite) LMMonitorXPCClient *monitorDelegate;
@property (nonatomic, strong, readwrite) dispatch_semaphore_t async_semaphore_3;
@property (nonatomic, assign) BOOL isWantRetryDaemonActive;
@end

@implementation LMXpcClientManager

+ (LMXpcClientManager*)sharedInstance
{
    static LMXpcClientManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    

    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _strLemonName = @"Tencent Lemon";
        _strLemonMonitorName = @"LemonMonitor";
        _lemonDelegate = [LMLemonXPCClient new];
        _monitorDelegate = [LMMonitorXPCClient new];
        self.async_semaphore_3 = dispatch_semaphore_create(3);

        self.isWantRetryDaemonActive = YES;
    }
    return self;
}

- (NSXPCConnection *)connectionToService{
    @synchronized(self)
    {
        if (!_connectionToService) {
            //_connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.tencent.TestAgrent"];
            _connectionToService = [[NSXPCConnection alloc] initWithMachServiceName:@"com.tencent.LemonDaemon" options:NSXPCConnectionPrivileged];
            _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMDaemonXPCProtocol)];
            if ([[[NSProcessInfo processInfo] processName] containsString:_strLemonName]) {
                _connectionToService.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMLemonXPCProtocol)];
                _connectionToService.exportedObject = _lemonDelegate;
            } else if ([[[NSProcessInfo processInfo] processName] containsString:_strLemonMonitorName]) {
                _connectionToService.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(LMMonitorXPCProtocol)];
                _connectionToService.exportedObject = _monitorDelegate;
            }
            __weak typeof(self) weakSelf = self;
            // invalid xpc connection must to rebuid connection
            _connectionToService.invalidationHandler =
            ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf){
                    strongSelf->_connectionToService = nil;
                    if (strongSelf.isWantRetryDaemonActive) {
                        [[LMDaemonStartupHelper shareInstance] activeDaemon];
                        strongSelf.isWantRetryDaemonActive = NO;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * 5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            strongSelf.isWantRetryDaemonActive = YES;
                        });
                    }
                }
                NSLog(@"Lemon corefuction xpc connection has been invalidated");
            };
            // interruption xpc connection not want to rebuid connection
            _connectionToService.interruptionHandler =
            ^{
                //__strong typeof(weakSelf) strongSelf = weakSelf;
                //strongSelf->_connectionToService = nil;
                NSLog(@"Lemon corefuction xpc connection has been interruptionHandler");
            };
            [_connectionToService resume];
        }
    }
    return _connectionToService;
}

#pragma mark XPC
// build xpc channel
- (void)buildXPCConnectChannel{
    if ([[self.connectionToService remoteObjectProxy] respondsToSelector:@selector(buildXPCConnectChannel)]) {
        [[self.connectionToService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            NSLog(@"self.connectionToService buildXPCConnectChannel remoteObjectProxyWithErrorHandler error: %@", error);
        }] buildXPCConnectChannel];
    } else {
        NSLog(@"Lemon corefuction xpc connection buildXPCConnectChannel no selector");
    }
}

// execute a command through xpc
- (NSData *)executeXPCCommandSync:(NSData *)paramData magic:(int)magic overtime:(int)MaxTime{
    
    // 同步的都是 单sequence queue + 阻塞的模式.
    // 这里的 semaphore 是阻塞式的,保证是同步方法调用. 而sequence queue 调用 block 也是同步的, 这里不需要一个外部变量dispatch_semaphore_t 就能保证 executeXPCCommandSync 方法是 依次调用的.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *rpdata = nil;
    __block BOOL isComplete = NO;
    typeof (void (^)(NSData*)) complete = ^(NSData* replayData){
        rpdata = replayData;
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    };
    NSLog(@"connectionToService-->");
    if ([self.connectionToService remoteObjectProxy]) {
        [[self.connectionToService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            NSLog(@"self.connectionToService executeXPCCommandSync remoteObjectProxyWithErrorHandler error: %@", error);
        }] sendDataToDaemon:paramData withReply:^(NSData *rdata) {
            complete(rdata);
            NSLog(@"connectionToService complete-->");
        }];
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MaxTime * NSEC_PER_SEC)));
    } else {
        NSLog(@"Lemon corefuction xpc connection executeXPCCommandSync self.connectionToService is nil");
    }
    if (!isComplete) {
        int total_size = sizeof(mc_pipe_result);
        mc_pipe_result *presult = (mc_pipe_result *)malloc(total_size);
        presult->cmd_magic = magic;
        presult->size = total_size;
        presult->cmd_ret = -1;
        rpdata = [NSData dataWithBytes:(void*)presult length:presult->size];
        NSLog(@"Lemon corefuction xpc connection command is timeout");
    }
    return rpdata;
}
- (void)executeXPCCommand:(NSData *)paramData overtime:(int)MaxTime withReply:(void (^)(NSData *))replyBlock;
{
    // 最多允许有三个异步访问同时进行. 因为放在 sequence queue 中运行
    // 假如有四个请求同时执行, 前三个请求会直接通过,而第四个请求会阻塞在 dispatch_semaphore_wait 处,等到任一请求 callback 回来后调用
    // dispatch_semaphore_signal才会继续执行. (阻塞的是sequence queue,使其他的 block 无法执行). 所以这里的dispatch_semaphore_t 必须是一个 外部变量,每次方法调用共享同一个 dispatch_semaphore_t
    
    __weak typeof(self) weakSelf = self;
    __block long sem_return = 0;
    typeof (void (^)(NSData* replayData)) complete = ^(NSData* replayData){
        replyBlock(replayData);
        if(sem_return == 0 ){  // 超时的时候,不需要额外唤醒了.否则会使得 sem 不断增大.(因为超时的时候 wait 并没有使的 sem -1).
            dispatch_semaphore_signal(weakSelf.async_semaphore_3);
        }
    };
    if ([self.connectionToService remoteObjectProxy]) {
        [[self.connectionToService remoteObjectProxy] sendDataToDaemon:paramData withReply:^(NSData *rdata) {
            complete(rdata);
        }];
    }else {
        NSLog(@"Lemon corefuction xpc connection executeXPCCommand self.connectionToService is nil");
    }
    //    dispatch_semaphore_wait() has only decremented the semaphore value if it returns 0.
    //    If the timeout expired (i.e. it returns non-zero), the semaphore value has NOT been decremented.
    //    Think of the decrement in the success case as taking ownership of one of the resources managed by the counting semaphore, if you signaled right after a successful wait, you would indicate that you have stopped using that resource right away, which is presumably not what you want.
    
    sem_return = dispatch_semaphore_wait(self.async_semaphore_3, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MaxTime * NSEC_PER_SEC)));
    //  超时的时候
    
    // 当 sem value > 0 时, dispatch_semaphore_wait 会立刻返回,并且 -1. 这时候代码不会阻塞.
    // 当 sem value = 0 时, dispatch_semaphore_wait会阻塞.会分两种情况.
    //   1. 未超时, 由dispatch_semaphore_signal 唤醒. 这时候dispatch_semaphore_wait返回0.
    //   2. 超时, dispatch_semaphore_wait 返回的是, 这时候dispatch_semaphore_wait返回非0. 这时候dispatch_semaphore_wait 对应的 sem 并不会-1.也就不需要signal
    
    // dispatch_semaphore_signal 会使得 sem +1.特别注意dispatch_semaphore_wait超时的时候,回自动唤醒,

    
}

@end
