//
//  QMBaseScan.h
//  LemonClener
//
//  Created by Yvan Peng on 2023/11/8.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol QMScanDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface QMBaseScan : NSObject

@property (weak) id<QMScanDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
