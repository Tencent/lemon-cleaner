//
//  LMVersionHelper.h
//
//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMVersionHelper : NSObject
+ (NSString *)fullVersionFromVersionLogFile;
+ (void)writeVersionToVersionLogFileWithMainVersion:(NSString *)mainVersion andBuildVersion:(NSString *)buildVersion;

+ (NSString *)fullVersionFromBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
