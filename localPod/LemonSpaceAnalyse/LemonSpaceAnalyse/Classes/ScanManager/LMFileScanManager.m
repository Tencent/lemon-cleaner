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
    NSLog(@"__%s__", __PRETTY_FUNCTION__);
}

- (id)init{
    self = [super init];
    if (self) {
        _concurrentQueue = dispatch_queue_create("com.tencent.lemonFileScan", DISPATCH_QUEUE_CONCURRENT);
        _scanGroup = dispatch_group_create();
        _maxConcurrentCount =  [[NSProcessInfo processInfo] processorCount];
        _usedDiskSize = [self getAllBytes] - [self getAllUsableBytes];
        _hadScanDiskSize = 0;
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
        // 配合delegate强引用做的保护
        NSString *searchPath = self.searchPath ?: @"";
        CGFloat rate = 0.0;
        if (self.usedDiskSize != 0) {
            rate = self.hadScanDiskSize/(self.usedDiskSize*1.0);
        }
        [strongDelegate progressRate:rate progressStr:searchPath];
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
    _searchPath = @"";
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
            self.time = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onTrashScan) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.time forMode:NSRunLoopCommonModes];
            [self.time fire];
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
        pthread_mutex_init(&lock, NULL);
        pthread_cond_init(&loopCondition, NULL);
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
        if (self.time) {
            [self.time invalidate];
            self.time = nil;
        }
        pthread_mutex_destroy(&self->lock);
        pthread_cond_destroy(&self->loopCondition);
        
        if ([self.delegate respondsToSelector:@selector(progressRate:progressStr:)]) {
            [self.delegate progressRate:1 progressStr:self.searchPath];
        }
        
        if ([self.delegate respondsToSelector:@selector(end)]) {
            [self.delegate end];
        }
        
//        NSLog(@"end==>%f",_currentNum);
    });
}

- (void)cancel{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        pthread_mutex_lock(&self->lock);
    
        self.isCancel = YES;
        // 让正在扫描中的任务取消
        for (LMFileScanTask *task in self.runningTasks) {
            [task cancel];
        }
        [self.taskStack removeAllObjects];
        if (self.time) {
            [self.time invalidate];
            self.time = nil;
        }
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
