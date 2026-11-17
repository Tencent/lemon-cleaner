//
//  LMFileScanManager.m
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//
#import "LMFileScanManager.h"
#import <pthread.h>
#import "LMItem.h"
#import "LMFileScanTask.h"
#include <assert.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <sys/attr.h>
#include <sys/errno.h>
#include <unistd.h>
#include <sys/vnode.h>
#import <QMCoreFunction/LMReferenceDefines.h>



@interface LMFileScanManager () <LMFileScanTaskDelegate>
{
    pthread_mutex_t lock;
    pthread_cond_t  loopCondition;
}

@property(nonatomic, strong) NSMutableArray *runningTasks;
@property(nonatomic, strong) NSMutableArray *taskStack;
@property(nonatomic, strong) dispatch_group_t scanGroup;
@property(nonatomic, strong) dispatch_queue_t concurrentQueue;
@property(nonatomic, strong) NSTimer *time;
@property(nonatomic, strong) NSString *searchPath;
@property(nonatomic, assign) long long maxConcurrentCount;

@property(nonatomic, assign) long long usedDiskSize;
@property(nonatomic, assign) long long hadScanDiskSize;
@property(nonatomic, assign) double currentNum;

@end


@implementation LMFileScanManager

- (void)dealloc {
    // 保底清理：正常流程应在 cancel 或扫描结束时已 invalidate
    // 若外部未调用 cancel 直接释放对象，此处确保 Timer 不会成为悬空定时器
    [self stopProgressTimer];
    pthread_mutex_destroy(&lock);
    pthread_cond_destroy(&loopCondition);
    NSLog(@"__%s__", __PRETTY_FUNCTION__);
}

- (id)init{
    self = [super init];
    if (self) {
        pthread_mutex_init(&lock, NULL);
        pthread_cond_init(&loopCondition, NULL);
        _concurrentQueue = dispatch_queue_create("com.tencent.lemonFileScan", DISPATCH_QUEUE_CONCURRENT);
        _scanGroup = dispatch_group_create();
        _maxConcurrentCount =  [[NSProcessInfo processInfo] processorCount];
        _usedDiskSize = [self getAllBytes] - [self getAllUsableBytes];
        _hadScanDiskSize = 0;
        _searchPath = @"";
        _skipICloudFiles = YES; // 默认跳过iCloud未下载文件以避免卡顿
        _specialFileExtensions = [NSSet setWithObjects:@"simruntime", @"app", @"bundle",  nil];
    }
    return self;
}

- (void)fileScanTaskFinishOneFile:(long long)size {
    self.hadScanDiskSize =  self.hadScanDiskSize + size;
}
#pragma mark - private

- (void)onTrashScan{
    if (self.usedDiskSize <= self.hadScanDiskSize) {
        self.usedDiskSize = self.hadScanDiskSize;
    }
    
    // 获取delegate的强引用，防止在方法调用过程中被释放。MacOS 26特有，可能修改了weak释放时机
    id<LMFileScanManagerDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(progressRate:progressStr:)]) {
        // atomic getter 已线程安全；再 copy 一份交给 UI，避免回调期间被替换
        NSString *searchPath = [self.searchPath copy] ?: @"";
        long long used = self.usedDiskSize;
        long long scanned = self.hadScanDiskSize;
        CGFloat rate = 0.0;
        if (used != 0) {
            rate = scanned / (used * 1.0);
        }
        [strongDelegate progressRate:rate progressStr:searchPath];
    }
}
#pragma mark - Timer

/// 启动进度上报定时器（必须在主线程调用）
/// Timer 使用 block + weak self 形式，避免强持有 self 导致 UAF；
/// 由 stopProgressTimer 在以下三条路径统一释放：
/// 扫描结束(group_notify) / 主动取消(cancel) / 页面释放(VC dealloc -> cancel)
- (void)startProgressTimer {
    NSAssert([NSThread isMainThread], @"startProgressTimer must be called on main thread");
    if (self.time != nil) {
        return;
    }
    if (@available(macOS 10.12, *)) {
        // 10.12+：block + weak self。避免 timer 强持有 self 后，delegate 释放时 self 被续命、
        // 仍 fire 去访问已 dealloc 的 delegate（macOS 26 weak 清零时序变化）导致 UAF（SIGSEGV）
        __weak typeof(self) weakSelf = self;
        self.time = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                    repeats:YES
                                                      block:^(NSTimer *timer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf onTrashScan];
            }
        }];
    } else {
        // 10.11 兼容：target/self 形式（10.11 无 macOS 26 的 weak 时序问题）
        self.time = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                    target:self
                                                  selector:@selector(onTrashScan)
                                                  userInfo:nil
                                                   repeats:YES];
    }
    [[NSRunLoop currentRunLoop] addTimer:self.time forMode:NSRunLoopCommonModes];
    [self.time fire];
}

/// 停止并清理定时器（线程安全：可在任意线程调用，自动派发到主线程执行）
- (void)stopProgressTimer {
    if (self.time == nil) {
        return;
    }
    if ([NSThread isMainThread]) {
        [self.time invalidate];
        self.time = nil;
    } else {
        // NSTimer 必须在创建它的线程（主线程）invalidate，跨线程调用是未定义行为
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.time invalidate];
            self.time = nil;
        });
    }
}

-(long long)getAllUsableBytes {
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        return [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] longLongValue];
    }else{
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        return [[results objectForKey:NSURLVolumeAvailableCapacityKey] longLongValue];
    }
}

-(long long)getAllBytes {
    NSError *error = nil;
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
    NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeTotalCapacityKey] error:&error];
    if (!results) {
        NSLog(@"Error retrieving resource keys");
        return 0;
    }
    return [[results objectForKey:NSURLVolumeTotalCapacityKey] longLongValue];
}

- (void)initData:(NSString *)path{
    self.searchPath = @"";
    _hadScanDiskSize = 0;
    _taskStack = [NSMutableArray array];
    _runningTasks = [NSMutableArray array];
    _isCancel = NO;
    _currentNum = 0;
    if (_maxConcurrentCount == 0) {
        _maxConcurrentCount = 2;
    }
    if (self.time == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startProgressTimer];
        });
    }
    LMItem *item = [[LMItem alloc] initWithFullPath:path];

    self.topItem = item;
    self.topItem.isDirectory = YES;
    LMFileScanTask *task = [[LMFileScanTask alloc] initWithRootDirItem:item];
    task.delegate = self;
    [self.taskStack addObject:task];
}

- (void)startWithRootPath:(NSString *)path{
    [self initData:path];
    unsigned long long count = [[self taskStack] count];
    if (count != 0) {
        if (self.maxConcurrentCount > 0) {
            NSUInteger num = 0;
            do {
                dispatch_group_async(self.scanGroup,self.concurrentQueue, ^{
                    [self loop];
                });
                num ++;
            } while ([self maxConcurrentCount] > num);
        }
    }
    
    dispatch_group_notify(self.scanGroup,self.concurrentQueue, ^{
        [self stopProgressTimer];

        // 结束回调保持在扫描队列：VC 的 end 会在调用线程上做整树 size 计算，不能切主线程。
        // progressRate: VC 内部会再 hop 到主线程刷 UI。
        NSString *path = [self.searchPath copy] ?: @"";
        id<LMFileScanManagerDelegate> strongDelegate = self.delegate;
        if ([strongDelegate respondsToSelector:@selector(progressRate:progressStr:)]) {
            [strongDelegate progressRate:1 progressStr:path];
        }
        pthread_mutex_destroy(&self->lock);
        pthread_cond_destroy(&self->loopCondition);
        
        if ([self.delegate respondsToSelector:@selector(progressRate:progressStr:)]) {
            [self.delegate progressRate:1 progressStr:self.searchPath];
        }
        
        if ([self.delegate respondsToSelector:@selector(end)]) {
            [self.delegate end];
        }
    });
}

- (void)cancel{
    // Timer 必须在主线程 invalidate，先于后台任务取消执行
    [self stopProgressTimer];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        pthread_mutex_lock(&self->lock);
    
        self.isCancel = YES;
        // 让正在扫描中的任务取消
        for (LMFileScanTask *task in self.runningTasks) {
            [task cancel];
        }
        [self.taskStack removeAllObjects];
        pthread_mutex_unlock(&self->lock);
    });
}

- (void)loop{
    while (YES) {
        @autoreleasepool {
            // 检查取消状态
            pthread_mutex_lock(&lock);
            if (self.isCancel) {
                pthread_mutex_unlock(&lock);
                break;
            }
            
            NSInteger taskStackCount = [[self taskStack] count];
            NSInteger runningTasksCount = [[self runningTasks] count];
            
            // 如果没有任务且没有运行中的任务，退出循环
            if (taskStackCount == 0 && runningTasksCount == 0) {
                pthread_mutex_unlock(&lock);
                break;
            }
            
            // 如果有待处理的任务
            if (taskStackCount > 0) {
                _currentNum++;
                LMFileScanTask *removeTask = [self taskStack].lastObject;
                removeTask.delegate = self;
                removeTask.skipICloudFiles = self.skipICloudFiles;
                removeTask.specialFileExtensions = self.specialFileExtensions;
                self.searchPath = removeTask.dirItem.fullPath;
                [[self runningTasks] addObject:removeTask];
                [[self taskStack] removeObject:removeTask];
                pthread_mutex_unlock(&lock);
                
                NSMutableArray *arr = [NSMutableArray array];
                [removeTask starTaskWithBlock:^(LMItem *item) {
                    LMFileScanTask *addTask = [[LMFileScanTask alloc] initWithRootDirItem:item];
                    [arr addObject:addTask];
                }];
                
                pthread_mutex_lock(&lock);
                // 再次检查取消状态
                if (!self.isCancel && [arr count] > 0) {
                    [self.taskStack addObjectsFromArray:arr];
                }
                [self.runningTasks removeObject:removeTask];

                pthread_mutex_unlock(&lock);
            } else {
                // 没有新任务但有运行中的任务，短暂等待
                pthread_mutex_unlock(&lock);
                usleep(1000); // 1毫秒，避免忙等待
            }
        }
    }
}

@end
