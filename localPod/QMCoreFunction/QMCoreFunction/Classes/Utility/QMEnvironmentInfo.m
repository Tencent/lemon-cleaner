//
//  QMEnvironmentInfo.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMEnvironmentInfo.h"
#import "QMCryptUtility.h"
#include <IOKit/IOKitLib.h>

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

NSString * const kQMDarkModeKey = @"AppleInterfaceStyle";

@implementation QMEnvironmentInfo

+ (void)systemVersion:(SInt*)major :(SInt*)minor :(SInt*)bugFix
{
    static SInt32 versionMajor = 0;
    static SInt32 versionMinor = 0;
    static SInt32 versionBugFix = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Gestalt( gestaltSystemVersionMajor, &versionMajor );
        Gestalt( gestaltSystemVersionMinor, &versionMinor );
        Gestalt( gestaltSystemVersionBugFix, &versionBugFix );
    });
    if (major != NULL) *major = versionMajor;
    if (minor != NULL) *minor = versionMinor;
    if (bugFix != NULL) *bugFix = versionBugFix;
}

+ (QMSystemVersion)systemVersion
{
    SInt32 major = 0;
    SInt32 minor = 0;
    [self systemVersion:&major :&minor :NULL];
    
    if (major < 10)
        return QMSystemVersionLower;
    
    if (major == 10)
    {
        if (minor < 7)
            return QMSystemVersionLower;
        else if (minor == 7)
            return QMSystemVersionLion;
        else if (minor == 8)
            return QMSystemVersionMountainLion;
        else if (minor == 9)
            return QMSystemVersionMavericks;
        else if (minor == 10)
            return QMSystemVersionYosemite;
    }
    return QMSystemVersionHigher;
}

+ (NSString *)systemVersionString
{
    static NSString *versionString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SInt32 major = 0;
        SInt32 minor = 0;
        SInt32 bugFix = 0;
        [self systemVersion:&major :&minor :&bugFix];
        versionString = [NSString stringWithFormat:@"%d.%d",major,minor];
        if (bugFix > 0) {
            versionString = [versionString stringByAppendingFormat:@".%d",bugFix];
        }
    });
    return versionString;
}

+ (NSString *)machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len)
    {
        char *model = (char *)malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    
    return @"Just an Apple Computer"; //incase model name can't be read
}
+ (CGFloat)backingScaleFactor
{
    static CGFloat scaleFactor = 1.0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    });
    return scaleFactor;
}

+ (NSString *)deviceSerialNumber
{
    static NSString *serialNumber = nil;
    if (!serialNumber)
    {
        io_service_t platform;
        CFStringRef serial;
        
        // get IOPlatformExpertDevice service object
        platform = IOServiceGetMatchingService(kIOMasterPortDefault,
                                               IOServiceMatching("IOPlatformExpertDevice"));
        if (platform == 0)
        {
            return nil;
        }
        
        // get serial value
        serial = IORegistryEntryCreateCFProperty(platform,
                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                 kCFAllocatorDefault,
                                                 kNilOptions);
        if (serial == NULL)
        {
            IOObjectRelease(platform);
            return nil;
        }
        IOObjectRelease(platform);
        serialNumber = (__bridge_transfer NSString *)serial;
    }
    return serialNumber;
}

+ (NSString *)deviceSerialNumberMD5
{
    static NSString *hashValue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *serialNumber = [self deviceSerialNumber];
        if (serialNumber) {
            hashValue = [QMCryptUtility hashString:serialNumber with:QMHashKindMd5];
        }
    });
    return hashValue;
}

+ (BOOL)isDarkMode
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kQMDarkModeKey] isEqualTo:@"Dark"];
}
@end
