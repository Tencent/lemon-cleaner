//
//  BaseModel.h
//  LemonHardware
//
//  Created by tencent on 2019/5/9.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef APPSTORE_VERSION
#import <QMCoreFunction/QMShellExcuteHelper.h>
#endif

@interface BaseModel : NSObject

#ifndef APPSTORE_VERSION
@property (nonatomic, assign) BOOL isInit;

-(BOOL)getHardWareInfo;

-(NSString *)getHardWareInfoPathByName:(NSString *)hardWareName;

-(NSString *)getValueForkey:(NSString *)key withString:(NSString *)configStr;

#endif

@end
