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

- (id)init{
    self = [super init];
    if (self) {
        _concurrentQueue = dispatch_queue_create("com.tencent.lemonFileScan", DISPATCH_QUEUE_CONCURRENT);
        _scanGroup = dispatch_group_create();
        _maxConcurrentCount =  [[NSProcessInfo processInfo] processorCount];
        _usedDiskSize = [self getAllBytes] - [self getAllUsableBytes];
        _hadScanDiskSize = 0;
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
    if ([self.delegate respondsToSelector:@selector(progressRate:progressStr:)]) {
        [self.delegate progressRate:self.hadScanDiskSize/(self.usedDiskSize*1.0) progressStr:self.searchPath];
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
    
//    dispatch_group_async(self.scanGroup,self.concurrentQueue, ^{
        pthread_mutex_lock(&self->lock);
        self.isCancel = YES;
        [self.taskStack removeAllObjects];
        if (self.time) {
            [self.time invalidate];
            self.time = nil;
        }
        pthread_mutex_unlock(&self->lock);
//    });

    
}

- (void)loop{
    @autoreleasepool {
    start:
        pthread_mutex_lock(&lock);
        NSInteger taskStackCount = [[self taskStack] count];
        NSInteger runningTasksCount = [[self runningTasks] count];
        if ((taskStackCount != 0) || (runningTasksCount != 0)) {
            if (taskStackCount != 0) {
                _currentNum ++;
                LMFileScanTask *removeTask = [self taskStack].lastObject;
                removeTask.delegate = self;
                self.searchPath = removeTask.dirItem.fullPath;
                [[self runningTasks] addObject:removeTask];
                [[self taskStack] removeObject:removeTask];
                pthread_mutex_unlock(&lock);
                NSMutableArray *arr = [NSMutableArray array];
                [removeTask starTaskWithBlock:^(LMItem *item) {
                    @autoreleasepool {
                        LMFileScanTask *addTask = [[LMFileScanTask alloc] initWithRootDirItem:item];
                        [arr addObject:addTask];
                    }
                }];
                pthread_mutex_lock(&lock);
                if([arr count] > 0){
                    if (self.isCancel == YES) {
                        
                    }else{
                        [self.taskStack addObjectsFromArray:arr];
                    }
                }
                [self.runningTasks removeObject:removeTask];
                pthread_mutex_unlock(&lock);
                goto start;
            }else{
                pthread_mutex_unlock(&lock);
                goto start;
            }
        }else{
            pthread_mutex_unlock(&lock);
        }
    }
}

@end
