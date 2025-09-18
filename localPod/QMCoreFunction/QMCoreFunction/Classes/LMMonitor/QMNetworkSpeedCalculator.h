//
//  QMNetworkSpeedCalculator.h
//  QMCoreFunction
//
//  Copyright (c) 2025年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMNetworkSpeedCalculator : NSObject

/**
 * 计算网络速度 (线程安全)
 * 外部需要定期调用此方法，该方法会自动计算与上次调用的时间差和流量差来得出网速
 * @return 字典格式：{进程号: {上传速度, 下载速度}}，与processNetInfoWithNetTop()格式相同
 */
+ (NSDictionary<NSNumber *, NSDictionary *> *)calculateNetworkSpeed;

/**
 * 重置计算器状态
 * 清除历史数据，下次调用calculateNetworkSpeed时将重新开始计算
 */
+ (void)reset;

@end
