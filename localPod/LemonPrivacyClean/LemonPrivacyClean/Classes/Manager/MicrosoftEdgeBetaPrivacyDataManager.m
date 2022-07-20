//
//  MicrosoftEdgeBetaPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MicrosoftEdgeBetaPrivacyDataManager.h"

@implementation MicrosoftEdgeBetaPrivacyDataManager

+(MicrosoftEdgeBetaPrivacyDataManager *)sharedManager{
    static MicrosoftEdgeBetaPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MicrosoftEdgeBetaPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *defaultPath = [path stringByAppendingString:@"/Library/Application Support/Microsoft Edge Beta/Default"];
    return defaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_MICROSOFT_EDGE_BETA;
}

@end
