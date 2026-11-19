//
//  LMTrashCodeSign.h
//  LemonUninstaller
//
//  只读 Team ID，不做 SecStaticCodeCheckValidity。DEBUG 也不放行。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMTrashCodeSign : NSObject
+ (nullable NSString *)teamIDOfCodeAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
