//
//  McCpuInfoSMC.m
//  LemonDaemon
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "McCpuInfoSMC.h"
#include <sys/sysctl.h>

@implementation McCpuInfoSMC

+ (McCpuType)getCpuType {
    static McCpuType cpuType = McCpuTypeUnknown;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cpuType = [self __getCpuType];
    });
    return cpuType;
}

+ (McCpuType)__getCpuType {
    size_t sizeOfName = 0;
    sysctlbyname("machdep.cpu.brand_string", NULL, &sizeOfName, NULL, 0);
    char nameChars[sizeOfName];
    sysctlbyname("machdep.cpu.brand_string", nameChars, &sizeOfName, NULL, 0);
    NSString *name = [NSString stringWithCString:nameChars encoding:NSUTF8StringEncoding];
    
    if (name.length == 0) {
        return McCpuTypeUnknown;
    }

    name = [name stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
    name = name.lowercaseString;
    
    if ([name containsString:@"intel"]) {
        return McCpuTypeIntel;
    }
    
    if ([name containsString:@"m1"]) {
        if ([name containsString:@"pro"]) {
            return McCpuTypeM1Pro;
        }
        if ([name containsString:@"max"]) {
            return McCpuTypeM1Max;
        }
        if ([name containsString:@"ultra"]) {
            return McCpuTypeM1Ultra;
        }
        return McCpuTypeM1;
    }
    
    if ([name containsString:@"m2"]) {
        if ([name containsString:@"pro"]) {
            return McCpuTypeM2Pro;
        }
        if ([name containsString:@"max"]) {
            return McCpuTypeM2Max;
        }
        if ([name containsString:@"ultra"]) {
            return McCpuTypeM2Ultra;
        }
        return McCpuTypeM2;
    }
    
    if ([name containsString:@"m3"]) {
        if ([name containsString:@"pro"]) {
            return McCpuTypeM3Pro;
        }
        if ([name containsString:@"max"]) {
            return McCpuTypeM3Max;
        }
        if ([name containsString:@"ultra"]) {
            return McCpuTypeM3Ultra;
        }
        return McCpuTypeM3;
    }
    
    return McCpuTypeUnknown;
}

@end
