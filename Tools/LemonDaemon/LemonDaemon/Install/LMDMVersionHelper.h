//
//  LMDMVersionHelper.h
//  
//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMDMVersionHelper : NSObject
+ (NSString *)mainVersionFromVersionLogFile;
+ (NSString *)buildVersionFromVersionLogFile;
+ (NSString *)fullVersionFromVersionLogFile;
+ (void)writeVersionToVersionLogFileWithMainVersion:(NSString *)mainVersion andBuildVersion:(NSString *)buildVersion;

+ (NSString *)fullVersionFromBundle:(NSBundle *)bundle;
+ (NSString *)mainVersionFromBundle:(NSBundle *)bundle;
+ (NSString *)buildVersionFromBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
