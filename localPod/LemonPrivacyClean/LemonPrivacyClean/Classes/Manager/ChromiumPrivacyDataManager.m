//
//  ChromiumPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2020 tencent. All rights reserved.
//

#import "ChromiumPrivacyDataManager.h"

@implementation ChromiumPrivacyDataManager

+(ChromiumPrivacyDataManager *)sharedManager{
    static ChromiumPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ChromiumPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *defaultPath = [path stringByAppendingString:@"/Library/Application Support/Chromium/Default"];
    return defaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_CHROMIUM;
}
@end
