//
//  BrowserApp.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrivacyData.h"

@interface BrowserApp : NSObject

@property(assign) PRIVACY_APP_TYPE appType;
@property(strong) NSString *appName;
@property(strong) NSString *bundleIdentifier;
@property(assign) BOOL isRunning;
@property(strong) NSArray *runningApps;  //NSRunningApplication
@end
