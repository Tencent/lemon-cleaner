//
//  MacthineModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//
// 机器信息
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface MachineModel : BaseModel

@property (nonatomic, strong) NSString *machineName;
@property (nonatomic, strong) NSString *yearString;
@property (nonatomic, strong) NSString *systemVersion;
@property (nonatomic, assign) NSInteger thunderbolts;
@property (nonatomic, assign) NSInteger ports;
@property (nonatomic, strong) NSString *cpuName;
@property (nonatomic, strong) NSString *cpuSpeed;
@property (nonatomic, strong) NSString *cpuCores;//cpu核心数
@property (nonatomic, strong) NSString *L2Cache;//二级缓存
@property (nonatomic, strong) NSString *L3Cache;//三级缓存


@end

@interface MachineModel (LHScreen)

// 刘海屏
+ (BOOL)isLiquidScreen;

@end
