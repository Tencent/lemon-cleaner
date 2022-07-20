//
//  PrivacyDataManager.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyData.h"
#import "ScanDelegate.h"

static BOOL debugFlag = NO; //  MARK: oc 没有类变量, static 只能修饰 局部变量/全局变量,不能修饰成员变量

@interface PrivacyDataManager : NSObject

@property(readwrite, weak) id <ScanDelegate> delegate;

- (void)killAppAndCleanWithData:(PrivacyData *)privacyData runningApps:(NSArray *)runningApps needKill:(BOOL)killFlag;

- (void)killAppsAndToScan:(NSArray *)apps needKill:(BOOL)killFlag;

+ (NSImage *)getBrowserIconByType:(PRIVACY_APP_TYPE)type;

+ (NSArray *)getInstalledAndRunningBrowserApps;

@end

