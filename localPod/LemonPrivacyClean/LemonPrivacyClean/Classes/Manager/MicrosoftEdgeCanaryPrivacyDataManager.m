//
//  MicrosoftEdgeCanaryPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MicrosoftEdgeCanaryPrivacyDataManager.h"

@implementation MicrosoftEdgeCanaryPrivacyDataManager

+(MicrosoftEdgeCanaryPrivacyDataManager *)sharedManager{
    static MicrosoftEdgeCanaryPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MicrosoftEdgeCanaryPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *defaultPath = [path stringByAppendingString:@"/Library/Application Support/Microsoft Edge Canary/Default"];
    return defaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_MICROSOFT_EDGE_CANARY;
}

@end
