//
//  OperaPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "OperaPrivacyDataManager.h"

@implementation OperaPrivacyDataManager

+(OperaPrivacyDataManager *)sharedManager{
    static OperaPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[OperaPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *qqBrowserDefaultPath = [path stringByAppendingString:@"/Library/Application Support/com.operasoftware.Opera"];
    return qqBrowserDefaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_OPERA;
}

@end
