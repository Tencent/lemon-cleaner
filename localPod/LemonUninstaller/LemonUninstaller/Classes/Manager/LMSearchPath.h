//
//  LMSearchPath.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMSearchPath : NSObject
+ (NSArray *) supportPaths;
+ (NSArray *) cachesPaths;
+ (NSArray *) preferencesPaths;
+ (NSArray *) statePaths;
+ (NSArray *) crashReportPaths;
+ (NSArray *) logPaths;
+ (NSArray *) sandboxsPaths;
+ (NSArray *) daemonPaths;
@end

NS_ASSUME_NONNULL_END
