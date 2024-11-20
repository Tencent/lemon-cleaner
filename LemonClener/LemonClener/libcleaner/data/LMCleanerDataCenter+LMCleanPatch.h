//
//  LMCleanerDataCenter+LMCleanPatch.h
//  LemonClener
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "LMCleanerDataCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMCleanerDataCenter (LMCleanPatch)
// 重置下载的勾选状态
- (void)lmClean_resetDownloadSelectStatus;
// 重置sketch缓存勾选状态 5.1.11
- (void)lmClean_resetSketchCacheSelectStatus;
@end

NS_ASSUME_NONNULL_END
