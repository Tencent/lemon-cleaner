//
//  HardwareInfoModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareInfoModel.h"

@implementation HardwareInfoModel

-(void)updateValueWithNewModel:(HardwareInfoModel *)infoModel{
    self.value1 = infoModel.value1;
    self.value2 = infoModel.value2;
    self.value3 = infoModel.value3;
    self.name1 = infoModel.name1;
    self.name2 = infoModel.name2;
    self.name3 = infoModel.name3;
}

@end
