//
//  ScanDelegate.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrivacyData.h"

typedef NS_ENUM(NSInteger, ScanType) {
    ScanTypeClean = 1,
    ScanTypeGet = 2
};

@protocol ScanDelegate <NSObject>
- (void)scanStart;

- (void)scanProcess:(double)processValue text:(NSString *)progressText;

- (void)scanEnd:(PrivacyData *)privacyData;
@end
