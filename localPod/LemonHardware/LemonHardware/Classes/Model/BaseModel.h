//
//  BaseModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>

@interface BaseModel : NSObject

@property (nonatomic, assign) BOOL isInit;

-(BOOL)getHardWareInfo;

-(NSString *)getHardWareInfoPathByName:(NSString *)hardWareName;

-(NSString *)getValueForkey:(NSString *)key withString:(NSString *)configStr;

@end
