//
//  MicrosoftEdgePrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MicrosoftEdgePrivacyDataManager.h"

@implementation MicrosoftEdgePrivacyDataManager


+(MicrosoftEdgePrivacyDataManager *)sharedManager{
    static MicrosoftEdgePrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MicrosoftEdgePrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *defaultPath = [path stringByAppendingString:@"/Library/Application Support/Microsoft Edge/Default"];
    return defaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_MICROSOFT_EDGE;
}

@end
