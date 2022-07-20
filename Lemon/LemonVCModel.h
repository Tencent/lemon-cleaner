//
//  LemonVCModel.h
//  Lemon
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LemonVCModel : NSObject

@property (nonatomic, strong) NSMutableDictionary *toolConMap;
+(LemonVCModel *)shareInstance;

@end

NS_ASSUME_NONNULL_END
