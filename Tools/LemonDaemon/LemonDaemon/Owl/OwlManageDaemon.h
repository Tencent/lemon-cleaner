//
//  OwlManageDaemon.h
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McPipeStruct.h"

@interface OwlManageDaemon : NSObject
+ (OwlManageDaemon *)shareInstance;

//the device is point camera and audio device
- (void)changeDeviceWatchState:(owl_watch_device_param*)param;
- (int)getDeviceWitchProcess:(owl_watch_device_param*)param pInfo:(lemon_com_process_info **)pInfo_t;
@end
