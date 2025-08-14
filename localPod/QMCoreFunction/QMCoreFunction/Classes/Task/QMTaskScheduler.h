//
//  QMTaskScheduler.h
//  QMCoreFunction
//
//  Created on 2024
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * QMTaskScheduler - 任务调度器
 * 当接收到触发信号时，延迟指定时间后执行任务
 * 如果在等待期间再次接收到信号，则重置延迟时间
 */
@interface QMTaskScheduler : NSObject

/**
 * 延迟执行的时间（秒）
 */
@property (nonatomic, assign) NSTimeInterval delayInterval;

/**
 * 在间隔时间内调用schedule会被忽略掉，防止高频下重复创建释放timer空耗性能
 * 默认值为0.1秒
 */ 
@property (nonatomic, assign) NSTimeInterval ignoreScheduleInterval;

/**
 * 初始化方法，使用block作为任务
 * @param delayInterval 延迟执行的时间（秒）
 * @param task 要执行的任务block
 * @return QMTaskScheduler实例
 */
- (instancetype)initWithDelay:(NSTimeInterval)delayInterval task:(void(^)(void))task;

/**
 * 触发任务调度 - 开始计时或重置计时器
 * 如果任务已经在等待执行，则取消并重新开始计时
 * 如果距离上次触发时间小于忽略间隔，则忽略此次调用
 */
- (void)schedule;

/**
 * 立即执行任务，不等待延迟时间
 * 会取消当前等待中的计时器
 */
- (void)executeImmediately;

/**
 * 取消当前等待执行的任务
 */
- (void)cancel;

/**
 * 当前是否有任务在等待执行
 * @return 如果有任务在等待执行则返回YES，否则返回NO
 */
- (BOOL)isPending;

@end

NS_ASSUME_NONNULL_END
