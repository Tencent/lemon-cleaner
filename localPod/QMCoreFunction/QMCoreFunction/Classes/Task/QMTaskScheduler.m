//
//  QMTaskScheduler.m
//  QMCoreFunction
//
//  Created on 2024
//

#import "QMTaskScheduler.h"

@interface QMTaskScheduler ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void (^taskBlock)(void);
@property (nonatomic, assign) NSTimeInterval lastScheduleInterval;

@end

@implementation QMTaskScheduler

#pragma mark - 初始化方法

- (instancetype)initWithDelay:(NSTimeInterval)delayInterval task:(void(^)(void))task {
    self = [super init];
    if (self) {
        _delayInterval = delayInterval;
        _taskBlock = [task copy];
        _ignoreScheduleInterval = 0.1;
        _lastScheduleInterval = 0;
    }
    return self;
}

#pragma mark - 析构方法

- (void)dealloc {
    [self cancel];
}

#pragma mark - 公共方法

- (void)schedule {
    // 获取当前时间
    NSTimeInterval currentInterval = [[NSDate date] timeIntervalSince1970];
    
    // 如果距离上次触发的时间小于忽略间隔，则忽略此次调用
    if (currentInterval - self.lastScheduleInterval < self.ignoreScheduleInterval) {
        return;
    }
    
    // 更新最后触发时间
    self.lastScheduleInterval = currentInterval;
    
    // 如果当前有等待执行的任务，则取消并重新创建
    if (self.timer) {
        [self cancel];
    }
    
    [self scheduleTimer];
}

- (void)executeImmediately {
    // 取消当前等待中的计时器
    [self cancel];
    
    // 立即执行任务
    [self executeTask];
}

- (void)cancel {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (BOOL)isPending {
    return (self.timer != nil);
}

#pragma mark - 私有方法

- (void)scheduleTimer {
    // 确保在主线程创建和执行定时器
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scheduleTimer];
        });
        return;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.delayInterval 
                                                 target:self 
                                               selector:@selector(executeTask) 
                                               userInfo:nil 
                                                repeats:NO];
}

- (void)executeTask {
    // 执行任务前先将定时器置空
    self.timer = nil;
    
    if (self.taskBlock) {
        self.taskBlock();
    }
}

@end
