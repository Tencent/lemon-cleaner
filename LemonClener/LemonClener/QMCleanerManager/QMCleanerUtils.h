//
//  QMCleanerUtils.h
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFirstShowCleanView     0
#define kStartScanCategory      1
#define kScanCategoryEndNoJunck 2
#define kScanCategoryEnd        3
#define kUserCancelScan         4
#define kCleanJunck             8
#define kCleanEnd               5
#define kCleanNowEnd            6
#define kCleanNowEndLeftFile    7


@interface QMCleanerUtils : NSObject

+ (BOOL)checkLanguageCanRemove:(NSString *)path;

+ (void)removeUserLoginItem:(NSString *)loginName;

+ (NSString *)getPathWithRunProcess:(NSString *)bundleID appName:(NSString *)name pid:(pid_t *)pid;

+ (void)saveCurrentCleanSize:(NSUInteger)size;

+ (NSImage *)iconWithCategoryID:(NSString *)categoryID highlight:(BOOL)highlight;

@end
