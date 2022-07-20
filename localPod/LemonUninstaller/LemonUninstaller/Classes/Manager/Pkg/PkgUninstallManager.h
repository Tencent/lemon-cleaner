//
// 
// Copyright (c) 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PkgUninstallProvider.h"


@interface PkgUninstallManager : NSObject

+ (instancetype)shared;

- (PkgUninstallProvider *)getProviderWithAppBundleId:(NSString *)appBundleId;

+ (NSArray<NSString *> *)pkgList;

+ (void)searchAllPkgList;

+ (void)clearAfterFinish;
@end
