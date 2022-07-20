//
//  MemoryModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

//内存信息

#import <Foundation/Foundation.h>
#import "BaseModel.h"


@interface MemBankModel :BaseModel

@property (nonatomic, strong) NSString *memBankType;//内存条类型
@property (nonatomic, strong) NSString *memSize;
@property (nonatomic, strong) NSString *memSpeed;
@property (nonatomic, strong) NSString *memStatus;

@end

@interface MemoryModel : BaseModel

@property (nonatomic, strong) NSMutableArray *memBankArr;

@end
