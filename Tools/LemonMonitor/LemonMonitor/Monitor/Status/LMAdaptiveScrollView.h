//
//  LMAdaptiveScrollView.h
//  LemonMonitor
//
//  Created on 2025-10-23.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMAdaptiveScrollView : NSScrollView

/// 最小高度（默认 60）
@property (nonatomic, assign) CGFloat minHeight;

/// 最大高度（默认 120）
@property (nonatomic, assign) CGFloat maxHeight;

/// 高度变化回调
@property (nonatomic, copy, nullable) void(^heightDidChange)(CGFloat newHeight);

/// 手动触发高度更新
- (void)updateHeight;

@end

NS_ASSUME_NONNULL_END
