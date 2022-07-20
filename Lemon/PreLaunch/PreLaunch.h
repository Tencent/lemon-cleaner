//
//  PreLaunch.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreLaunch : NSObject

// 是否需要进行安装操作
+ (BOOL)needToInstall:(int*)installType;

// 返回已安装的版本号
+ (NSString *)oldInstalledVersion;

// 开始安装
+ (int)startToInstall;

// 开始卸载
+ (BOOL)startToUnInstall;

+ (int)copySelfToApplication;
@end
