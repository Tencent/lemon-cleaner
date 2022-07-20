//
//  HardwareDataCenter.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiskModel.h"
@class HardwareModel;

@interface HardwareDataCenter : NSObject

//infoArr用来渲染tbleview  infoDic渲染header
typedef void(^InfoBlock)(NSMutableArray *infoArr, NSDictionary *infoDic);
typedef void(^GetBattInfoBlock)(BOOL status, HardwareModel *model);

+(HardwareDataCenter *)shareInstance;

//获取机器是否有电池
-(BOOL)getIsHaveBattery;

//获取所有的总信息
-(void)getAllHardwareInfoWithBlock:(InfoBlock) infoBlock;

//获取机器信息
-(BOOL)getMachineInfo;

//获取显卡-显示器信息
-(BOOL)getDisplayInfo;

//获取内存信息
-(BOOL)getMemoryInfo;

//获取电池信息
-(void)getBatteryInfo:(GetBattInfoBlock) infoBlock;

@end
