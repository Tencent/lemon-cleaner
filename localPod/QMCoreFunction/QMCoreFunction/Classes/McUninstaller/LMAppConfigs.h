//
//  LMAppConfigs.h
//  AFNetworking
//
//  
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMAppConfigs : NSObject
- (NSDictionary *) getConfigsOfApp:(NSString *)bundleId;
- (nonnull NSArray *) getPathsOfApp:(NSString *)bundleId withTypeKey:(NSString *)key;
- (nonnull NSArray *)getDaemonsOfApp:(NSString *)bundleId;
- (nonnull NSArray *)getUserAgnetOfApp:(NSString *)bundleId;
@end

NS_ASSUME_NONNULL_END
