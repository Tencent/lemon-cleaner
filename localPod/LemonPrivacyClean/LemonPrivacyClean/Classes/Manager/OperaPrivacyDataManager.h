//
//  OperaPrivacyDataManager.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChromePrivacyDataManager.h"


@interface OperaPrivacyDataManager  : ChromePrivacyDataManager

+(OperaPrivacyDataManager *)sharedManager;

@end
