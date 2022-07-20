//
//  LMInstallerUtil.h
//  LemonInstaller
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMInstallerHelper : NSObject

+ (NSString *)oldInstalledVersion;
+ (NSString *)versionOfApp:(NSString *)appPath;
+ (void)moveToApplicationForApp:(NSString *)appPath;
+ (int)startToInstall;
+ (void)unlinkOldSem;

@end
