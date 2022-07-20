//
//  McLocalSoft.h
//  QMApplication
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    kMcLocalFlagAll            =   (1 << 0),
    kMcLocalFlagApplication    =   (1 << 1),
    kMcLocalFlagInternet       =   (1 << 2),
    kMcLocalFlagWidget         =   (1 << 3),
    kMcLocalFlagScreenSaver    =   (1 << 4),
    kMcLocalFlagPreferencePane =   (1 << 5),
    kMcLocalFlagInputMethod    =   (1 << 6),

    kMcLocalFlagSpotlight      =   (1 << 7),
    kMcLocalFlagQuickLook      =   (1 << 8),
    kMcLocalFlagDictionary     =   (1 << 9),
};
typedef NSInteger McLocalType;

@interface McLocalSoft : NSObject

@property (nonatomic, strong) NSString  *bundleID;
@property (nonatomic, strong) NSString  *appName;
@property (nonatomic, strong) NSString  *showName;
@property (nonatomic, strong) NSString  *executableName;
@property (nonatomic, strong) NSString  *version;
@property (nonatomic, strong) NSString  *buildVersion;
@property (nonatomic, strong) NSString  *copyright;
@property (nonatomic, strong) NSString  *bundlePath;
@property (nonatomic, strong) NSString  *minSystem;
@property (nonatomic, strong) NSNumber  *bundleSize;
@property (nonatomic, strong) NSDate    *modifyDate;
@property (nonatomic, strong) NSDate    *createDate;
@property (nonatomic, strong) NSImage   *icon;
@property (nonatomic, assign) McLocalType type;

+ (id)softWithPath:(NSString *)filePath;
+ (id)softWithBundle:(NSBundle *)bundle;

- (BOOL)needUpdateWithNetVersion:(NSString *)netVersion;
- (NSComparisonResult)compareVersion:(McLocalSoft *)localSoft;

@end
