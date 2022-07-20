//
//  DiskModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

//硬盘信息

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface DiskZoneModel : BaseModel

@property (nonatomic, strong) NSString *diskName;
@property (nonatomic, assign) long long maxSize;
@property (nonatomic, assign) long long leftSize;
@property (nonatomic) BOOL isMainDisk;

@end

@interface DiskModel : BaseModel

@property (nonatomic, strong) NSMutableArray *diskZoneArr;

@end
