//
//  HardwareInfoModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HardwareBaseModel.h"

@interface HardwareInfoModel : HardwareBaseModel

@property (nonatomic, strong) NSString *name1;
@property (nonatomic, strong) NSString *value1;
@property (nonatomic, strong) NSString *name2;
@property (nonatomic, strong) NSString *value2;
@property (nonatomic, strong) NSString *name3;
@property (nonatomic, strong) NSString *value3;

-(void)updateValueWithNewModel:(HardwareInfoModel *)infoModel;

@end
