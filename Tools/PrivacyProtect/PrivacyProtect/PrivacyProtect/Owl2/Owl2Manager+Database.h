//
//  Owl2Manager+Database.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <PrivacyProtect/PrivacyProtect.h>
#import "Owl2Manager.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2Manager (Database)

- (void)loadDB;
- (void)closeDB;

- (void)setWatchVedioToDB:(BOOL)state;
- (void)setWatchAudioToDB:(BOOL)state;
- (void)addAppWhiteItemToDB:(NSDictionary*)dic;
- (void)resaveWhiteListToDB;
- (void)removeAppWhiteItemToDB:(NSDictionary*)dic;
- (void)addLogItem:(NSString*)log appName:(NSString*)appName;

@end

NS_ASSUME_NONNULL_END
