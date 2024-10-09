//
//  BatteryModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

//电池信息

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface BatteryModel : BaseModel

#ifndef APPSTORE_VERSION
@property (nonatomic, strong) NSString *maxCapacity;
@property (nonatomic, strong) NSString *currentCapacity;
@property (nonatomic, strong) NSString *loopCount;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *percentage;//当前电池百分比
@property (nonatomic, assign) BOOL ischarge;//当前电池是否还在充电
@property (nonatomic, assign) BOOL batExternalCharge;//ac充电线是否连接
@property (nonatomic, strong) NSString *isFullyCharged;//是否充满
@property (nonatomic, assign) BOOL haveBattery;//是否有电池
//苹果M1机器，不显示最大容量和剩余容量信息，显示电池健康状态栏（最大容量比例，如：100%）
@property (nonatomic) NSString *healthMaxCapacity;
#endif

//电池是否存在
-(BOOL)isExistBattery;

@end
