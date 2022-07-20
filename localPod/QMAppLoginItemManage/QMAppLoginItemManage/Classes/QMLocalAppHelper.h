//
//  QMLocalAppHelper.h
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMLocalApp.h"

NS_ASSUME_NONNULL_BEGIN

/*
 Helper for getting app info
 */
@interface QMLocalAppHelper : NSObject

+ (instancetype)shareInstance;

- (NSArray<NSString*> *)getAppsFromSystem;

- (NSArray *)getAppsByEnumDir;

- (NSArray<QMLocalApp *> *)getLocalAppData;

@end

NS_ASSUME_NONNULL_END
