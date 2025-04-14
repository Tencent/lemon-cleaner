//
//  LemonMonitroHelpParams.m
//  LemonMonitor
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LemonMonitroHelpParams.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <sys/sysctl.h>
#import <libproc.h>

@interface LemonMonitroHelpParams ()
@property (nonatomic, strong) NSTimer *memTopTimer;
@end

@implementation LemonMonitroHelpParams
+ (LemonMonitroHelpParams*)sharedInstance
{
    static LemonMonitroHelpParams* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
- (void)startStatMemory
{
    self.memTopTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(memoryTopRepeater) userInfo:nil repeats:YES];
    [self.memTopTimer fire];
}
- (void)stopStatMemory
{
    [self.memTopTimer invalidate];
    self.memTopTimer = nil;
}

// 对应活动监视器里面的 实际内存 （反映了进程真正占用的物理内存空间，不包括那些已被换出到磁盘交换空间的部分，正好有用户提了建议）
- (void)memoryTopRepeater {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSDate *beginTime = [NSDate date];
            
            // 1. 通过 sysctl 获取所有进程的 PID 和 PPID（替代 ps 命令）
            NSMutableDictionary<NSNumber *, NSNumber *> *pidToPpid = [NSMutableDictionary new];
            NSMutableDictionary<NSNumber *, NSNumber *> *pidToRss = [NSMutableDictionary new];
            int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
            size_t len = 0;
            
            // 动态计算缓冲区大小
            if (sysctl(mib, 4, NULL, &len, NULL, 0) != 0) {
                NSLog(@"Failed to get buffer size: %s", strerror(errno));
                return;
            }
            
            struct kinfo_proc *procs = malloc(len);
            if (!procs) {
                NSLog(@"Memory allocation failed");
                return;
            }
            
            if (sysctl(mib, 4, procs, &len, NULL, 0) != 0) {
                free(procs);
                NSLog(@"Failed to retrieve process info: %s", strerror(errno));
                return;
            }
            
            // 2. 填充进程数据
            int count = (int)(len / sizeof(struct kinfo_proc));
            for (int i = 0; i < count; i++) {
                pid_t pid = procs[i].kp_proc.p_pid;
                pid_t ppid = procs[i].kp_eproc.e_ppid;
                pidToPpid[@(pid)] = @(ppid);
                
                struct proc_taskinfo taskInfo;
                if (proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, sizeof(taskInfo)) > 0) {
                    pidToRss[@(pid)] = @(taskInfo.pti_resident_size);
                }
            }
            free(procs);
            
            // 3. 构建父-子进程树
            NSMutableDictionary<NSNumber *, NSMutableArray<NSNumber *> *> *parentChildMap = [NSMutableDictionary new];
            for (NSNumber *pid in pidToPpid.allKeys) {
                NSNumber *ppid = pidToPpid[pid];
                NSMutableArray *children = parentChildMap[ppid] ?: [NSMutableArray new];
                [children addObject:pid];
                parentChildMap[ppid] = children;
            }
            
            // 4. 后序遍历优化
            NSMutableDictionary<NSNumber *, NSNumber *> *aggregatedMemory = [NSMutableDictionary new];
            NSMutableArray<NSArray<NSNumber *> *> *stack = [NSMutableArray new];
            NSMutableSet<NSNumber *> *visited = [NSMutableSet new];
            
            // 初始化栈：所有未访问的 PID
            for (NSNumber *pid in pidToRss) {
                if (![visited containsObject:pid]) {
                    [stack addObject:@[pid, @(NO)]];
                }
            }
            
            // 栈模拟后序遍历
            while (stack.count > 0) {
                NSArray *currentElement = stack.lastObject;
                NSNumber *currentPid = currentElement[0];
                BOOL isProcessed = [currentElement[1] boolValue];
                
                if (!isProcessed) {
                    // 标记为已处理，并替换栈顶元素
                    [stack removeLastObject];
                    [stack addObject:@[currentPid, @(YES)]];
                    
                    // 添加子进程到栈（反向保证顺序）
                    NSArray<NSNumber *> *children = parentChildMap[currentPid];
                    for (NSNumber *childPid in [children reverseObjectEnumerator]) {
                        if (![visited containsObject:childPid]) {
                            [stack addObject:@[childPid, @(NO)]];
                        }
                    }
                } else {
                    // 计算当前进程的总内存（子进程已处理）
                    [stack removeLastObject];
                    [visited addObject:currentPid];
                    
                    NSUInteger totalRSS = [pidToRss[currentPid] unsignedLongLongValue];
                    NSArray<NSNumber *> *children = parentChildMap[currentPid];
                    for (NSNumber *childPid in children) {
                        totalRSS += [aggregatedMemory[childPid] unsignedLongLongValue];
                    }
                    aggregatedMemory[currentPid] = @(totalRSS);
                }
            }
            
            // 5. 生成最终数据
            NSMutableArray<McProcessInfoData *> *resArray = [NSMutableArray array];
            for (NSNumber *pid in aggregatedMemory) {
                McProcessInfoData *data = [McProcessInfoData new];
                data.pid = pid.intValue;
                data.resident_size = [aggregatedMemory[pid] unsignedLongLongValue];
                [resArray addObject:data];
            }
            
            // 6. 主线程回调
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Process count: %ld, Time cost: %.2fms", resArray.count, [[NSDate date] timeIntervalSinceDate:beginTime] * 1000);
                weakSelf.topMemoryArray = resArray;
            });
        }
    });
}

@end
