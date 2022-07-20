//
//  MicrosoftEdgeDevPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MicrosoftEdgeDevPrivacyDataManager.h"

@implementation MicrosoftEdgeDevPrivacyDataManager

+(MicrosoftEdgeDevPrivacyDataManager *)sharedManager{
    static MicrosoftEdgeDevPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MicrosoftEdgeDevPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *defaultPath = [path stringByAppendingString:@"/Library/Application Support/Microsoft Edge Dev/Default"];
    return defaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_MICROSOFT_EDGE_DEV;
}

@end
