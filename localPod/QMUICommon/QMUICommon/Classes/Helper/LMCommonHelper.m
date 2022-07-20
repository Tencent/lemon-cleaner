//
//  LMCommonHelper.m
//  QMUICommon
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMCommonHelper.h"

@implementation LMCommonHelper

+ (BOOL)isMacOS11 {
    NSLog(@"NSAppKitVersionNumber: %f",NSAppKitVersionNumber);
    if (NSAppKitVersionNumber > 1900) {
        NSLog(@"VersionNumber is 11");
        return YES;
    }
    NSLog(@"VersionNumber is less than 11");
    return NO;
}

@end
