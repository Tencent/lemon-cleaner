//
//  HardwareModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HardwareInfoModel.h"

typedef NS_ENUM(NSUInteger, HardwareType) {
    HardwareTypeDisk,
    HardwareTypeProcessor,
    HardwareTypeDisplay,
    HardwareTypeMemory,
    HardwareTypeElectroic,
};

@interface HardwareModel : HardwareBaseModel

@property (nonatomic, assign) HardwareType hardwareType;
@property (nonatomic, strong) NSString *iconName;
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSMutableArray *infoArr;//包含所有的展示信息数组
//以下两项属性为电池项提供
@property (nonatomic, assign) BOOL isCharge;//为电池数据提供 是否正在充电展示不同样式
@property (nonatomic, assign) BOOL isExternalCharge;//是否连接充电线
@property (nonatomic, strong) NSString *elecPercentage;//电池电量百分比

-(void)addHardwareInfoModel:(HardwareInfoModel *)infoModel;

//更新信息 支持定时器刷新硬件信息
-(void)updateValueWithHardwareModel:(HardwareModel *)hardwareModel;

@end

