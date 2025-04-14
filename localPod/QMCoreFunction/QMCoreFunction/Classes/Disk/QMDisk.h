//
//  QMDisk.h
//  AFNetworking
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMDisk : NSObject

+ (BOOL)isReadOnly:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
