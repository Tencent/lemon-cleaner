//
//  LMCleanerDataCenter+LMCleanPatch.h
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "LMCleanerDataCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMCleanerDataCenter (LMCleanPatch)
/// 重置下载的勾选状态
- (void)lmClean_resetDownloadSelectStatus;

@end

NS_ASSUME_NONNULL_END
