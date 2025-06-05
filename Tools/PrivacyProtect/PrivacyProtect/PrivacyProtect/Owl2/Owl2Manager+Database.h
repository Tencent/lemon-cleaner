//
//  Owl2Manager+Database.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <PrivacyProtect/PrivacyProtect.h>
#import "Owl2Manager.h"
#import "OwlConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2Manager (Database)

- (void)loadDB;
- (void)closeDB;

- (void)updateAllWatch;
- (void)addAppWhiteItemToDB:(NSDictionary*)dic;
- (void)removeAppWhiteItemToDB:(NSDictionary*)dic;
- (void)addLogItemWithUuid:(NSString *)uuid
                   appName:(NSString *)appName
                   appPath:(NSString *)appPath
                 appAction:(Owl2LogThirdAppAction)appAction
                userAction:(Owl2LogUserAction)userAction
                  hardware:(Owl2LogHardware)hardware;
- (void)updateLogItemWithUuid:(NSString *)uuid
                      appName:(NSString *)appName
                      appPath:(NSString *)appPath
                    appAction:(Owl2LogThirdAppAction)appAction
                   userAction:(Owl2LogUserAction)userAction
                     hardware:(Owl2LogHardware)hardware;

// 获取白名单
- (NSArray *)getWhiteList;

@end

NS_ASSUME_NONNULL_END
