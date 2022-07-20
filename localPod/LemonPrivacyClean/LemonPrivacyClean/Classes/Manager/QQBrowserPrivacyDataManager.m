//
//  QQBrowserPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "QQBrowserPrivacyDataManager.h"

@implementation QQBrowserPrivacyDataManager


+(QQBrowserPrivacyDataManager *)sharedManager{
    static QQBrowserPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[QQBrowserPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *qqBrowserDefaultPath = [path stringByAppendingString:@"/Library/Application Support/QQBrowser2/Default"];
    return qqBrowserDefaultPath;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_QQ_BROWSER;
}
@end

