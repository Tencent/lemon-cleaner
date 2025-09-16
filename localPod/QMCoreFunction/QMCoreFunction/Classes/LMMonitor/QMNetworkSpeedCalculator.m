//
//  QMNetworkSpeedCalculator.m
//  QMCoreFunction
//
//  Copyright (c) 2025年 Tencent. All rights reserved.
//

#import "QMNetworkSpeedCalculator.h"
#import "QMNetTopHelp.h"

@interface QMNetworkSpeedCalculator ()

@property (nonatomic, copy) NSDictionary *previousNetData;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, strong) NSLock *dataLock;

@end

@implementation QMNetworkSpeedCalculator

static QMNetworkSpeedCalculator *sharedInstance = nil;

+ (instancetype)sharedCalculator {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QMNetworkSpeedCalculator alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dataLock = [[NSLock alloc] init];
    }
    return self;
}

+ (NSDictionary *)calculateNetworkSpeed {
    QMNetworkSpeedCalculator *calculator = [QMNetworkSpeedCalculator sharedCalculator];
    return [calculator calculateSpeed];
}

+ (void)reset {
    QMNetworkSpeedCalculator *calculator = [QMNetworkSpeedCalculator sharedCalculator];
    [calculator resetData];
}

#pragma mark - Private Methods

- (NSDictionary *)calculateSpeed {
    [self.dataLock lock];
    
    // 获取当前网络流量数据
    NSDictionary *currentNetData = processNetInfoWithNetTop();
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 如果没有历史数据，保存当前数据作为基准，返回空字典
    if (!self.previousNetData || self.lastUpdateTime == 0) {
        self.previousNetData = currentNetData;
        self.lastUpdateTime = currentTime;
        [self.dataLock unlock];
        return @{};
    }
    
    // 计算时间间隔
    NSTimeInterval timeInterval = currentTime - self.lastUpdateTime;
    if (timeInterval <= 0) {
        [self.dataLock unlock];
        return @{};
    }
    
    // 计算网速
    NSMutableDictionary *speedResult = [NSMutableDictionary dictionary];
    
    for (NSNumber *pidKey in currentNetData) {
        NSDictionary *currentProcessData = currentNetData[pidKey];
        NSDictionary *previousProcessData = self.previousNetData[pidKey];
        
        if (!currentProcessData || !previousProcessData) {
            // 如果是新进程或者之前没有数据，跳过这次计算
            continue;
        }
        
        // 获取当前和之前的流量数据
        NSNumber *currentUp = currentProcessData[kUpNetKey];
        NSNumber *currentDown = currentProcessData[kDownNetKey];
        NSNumber *previousUp = previousProcessData[kUpNetKey];
        NSNumber *previousDown = previousProcessData[kDownNetKey];
        
        if (!currentUp || !currentDown || !previousUp || !previousDown) {
            continue;
        }
        
        // 计算流量差值
        double upDiff = [currentUp doubleValue] - [previousUp doubleValue];
        double downDiff = [currentDown doubleValue] - [previousDown doubleValue];
        
        // 计算速度 (字节/秒)
        double upSpeed = upDiff / timeInterval;
        double downSpeed = downDiff / timeInterval;
        
        // 确保速度不为负数
        upSpeed = MAX(0, upSpeed);
        downSpeed = MAX(0, downSpeed);
        
        // 只有有网络活动的进程才添加到结果中
        if (upSpeed > 0 || downSpeed > 0) {
            speedResult[pidKey] = @{
                kUpNetKey: @(upSpeed),
                kDownNetKey: @(downSpeed)
            };
        }
    }
    
    // 更新历史数据
    self.previousNetData = currentNetData;
    self.lastUpdateTime = currentTime;
    
    [self.dataLock unlock];
    return [speedResult copy];
}

- (void)resetData {
    [self.dataLock lock];
    self.previousNetData = nil;
    self.lastUpdateTime = 0;
    [self.dataLock unlock];
}

@end
