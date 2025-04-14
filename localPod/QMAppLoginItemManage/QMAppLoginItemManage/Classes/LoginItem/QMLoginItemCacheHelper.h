//
//  QMLoginItemCacheHelper.h
//  QMAppLoginItemManage
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMLoginItemCacheHelper : NSObject

+ (QMLoginItemCacheHelper *)sharedInstance;

- (NSMutableDictionary *)dictForCacheKey:(NSString *)key;
- (void)updateUserDefaultsWithCacheKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
