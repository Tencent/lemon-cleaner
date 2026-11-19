//
//  LMLoopTrigger.h
//  QMCoreFunction
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, LMLoopTriggerRunModes) {
    LMLoopTriggerRunModeSupportRightNow      = 1 << 0, // 支持runModeRightNowForKey调用触发。
    LMLoopTriggerRunModeWhenAppLaunch        = 1 << 1, // app启动时拉取
#ifdef DEBUG
    LMLoopTriggerRunModeEveryFiveSeconds     = 1 << 2, // 每隔5秒拉取，用于测试
#endif
    LMLoopTriggerRunModeEveryFiveMinutes     = 1 << 3, // 每隔5分钟拉取
    LMLoopTriggerRunModeEveryOneHour         = 1 << 4, // 每隔1小时
};

/// 回调 block，参数为本次触发的模式
typedef void(^LMLoopTriggerCallback)(LMLoopTriggerRunModes triggerMode);

// 主线程中调用
@interface LMLoopTrigger : NSObject

+ (instancetype)sharedInstance;

- (void)applicationDidFinishLaunching;

- (void)runModeRightNowForKey:(NSString *)key;

- (void)runModes:(LMLoopTriggerRunModes)runModes key:(NSString *)key callback:(LMLoopTriggerCallback)callback;

@end

NS_ASSUME_NONNULL_END
