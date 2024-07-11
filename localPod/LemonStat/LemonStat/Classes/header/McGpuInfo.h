//
//  McGpuInfo.h
//  LemonStat
//
//

#import <Foundation/Foundation.h>
@class McGpuCore;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, McGpuInfoType) {
    McGpuInfoTypeDefault, // all
    McGpuInfoTypeUsage, // 使用率
};

@interface McGpuInfo : NSObject

- (void)updateInfoType:(McGpuInfoType)type;

// properties
@property (nonatomic, strong) NSArray *cores;

@end

@interface McGpuCore : NSObject <NSCopying>
// gup ID
@property (nonatomic, assign) NSInteger ID;
// gpu使用率
@property (nonatomic, assign) CGFloat usage;

@end

NS_ASSUME_NONNULL_END
