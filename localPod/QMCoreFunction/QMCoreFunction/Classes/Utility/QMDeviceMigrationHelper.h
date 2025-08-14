//
//  QMDeviceMigrationHelper.h
//  QMCoreFunction
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMDeviceMigrationHelper : NSObject
// 通过serial变化检查是否换机
+ (void)checkForDeviceMigrationWithCompletion:(void(^)(BOOL didSwitchDevice))completion;
@end

NS_ASSUME_NONNULL_END
