//
//  QMEnvironmentInfo.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kQMDarkModeKey;

enum
{
    QMSystemVersionLower,
    QMSystemVersionLion,
    QMSystemVersionMountainLion,
    QMSystemVersionMavericks,
    QMSystemVersionYosemite,
    QMSystemVersionHigher
};
typedef NSInteger QMSystemVersion;

@interface QMEnvironmentInfo : NSObject

+ (void)systemVersion:(SInt*)major :(SInt*)minor :(SInt*)bugFix;
+ (QMSystemVersion)systemVersion;
+ (NSString *)systemVersionString;
+ (NSString *)machineModel;
+ (CGFloat)backingScaleFactor;
+ (NSString *)deviceSerialNumber;
+ (NSString *)deviceSerialNumberMD5;

+ (BOOL)isDarkMode;
@end
