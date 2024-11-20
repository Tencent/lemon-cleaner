//
//  McCpuInfoSMC.h
//  LemonDaemon
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, McCpuType) {
    McCpuTypeUnknown = 0,
    
    McCpuTypeIntel,
    
    McCpuTypeM1,
    McCpuTypeM1Pro,
    McCpuTypeM1Max,
    McCpuTypeM1Ultra,
    
    McCpuTypeM2,
    McCpuTypeM2Pro,
    McCpuTypeM2Max,
    McCpuTypeM2Ultra,
    
    McCpuTypeM3,
    McCpuTypeM3Pro,
    McCpuTypeM3Max,
    McCpuTypeM3Ultra,
    
    McCpuTypeM4,
    McCpuTypeM4Pro,
    McCpuTypeM4Max,
    McCpuTypeM4Ultra, // 截止2024-11-12还未发行
    
};

@interface McCpuInfoSMC : NSObject

+ (McCpuType)getCpuType;

@end

NS_ASSUME_NONNULL_END
