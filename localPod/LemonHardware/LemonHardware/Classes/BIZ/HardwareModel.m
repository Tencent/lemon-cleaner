//
//  HardwareModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareModel.h"

@implementation HardwareModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.infoArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)addHardwareInfoModel:(HardwareInfoModel *)infoModel{
    [self.infoArr addObject:infoModel];
}

//更新信息 支持定时器刷新硬件信息
-(void)updateValueWithHardwareModel:(HardwareModel *)hardwareModel{
    self.infoArr = hardwareModel.infoArr;
    if (hardwareModel.hardwareType == HardwareTypeElectroic) {
        self.elecPercentage = hardwareModel.elecPercentage;
        self.isCharge = hardwareModel.isCharge;
        self.isExternalCharge = hardwareModel.isExternalCharge;
    }
}

@end
