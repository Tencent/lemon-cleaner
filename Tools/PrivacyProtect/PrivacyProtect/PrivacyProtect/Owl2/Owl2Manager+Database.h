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

- (void)setWatchVedioToDB:(BOOL)state;
- (void)setWatchAudioToDB:(BOOL)state;
- (void)addAppWhiteItemToDB:(NSDictionary*)dic;
- (void)removeAppWhiteItemToDB:(NSDictionary*)dic;
- (void)addLogItem:(NSString*)log appName:(NSString*)appName; // 废弃
- (void)addLogItemWithUuid:(NSString *)uuid
                   appName:(NSString *)appName
                   appPath:(NSString *)appPath
                 appAction:(Owl2LogAppAction)appAction
                userAction:(Owl2LogUserAction)userAction
                  hardware:(Owl2LogHardware)hardware;
- (void)updateLogItemWithUuid:(NSString *)uuid
                      appName:(NSString *)appName
                      appPath:(NSString *)appPath
                    appAction:(Owl2LogAppAction)appAction
                   userAction:(Owl2LogUserAction)userAction
                     hardware:(Owl2LogHardware)hardware;

// 获取白名单
- (NSArray *)getWhiteList;

@end

NS_ASSUME_NONNULL_END
