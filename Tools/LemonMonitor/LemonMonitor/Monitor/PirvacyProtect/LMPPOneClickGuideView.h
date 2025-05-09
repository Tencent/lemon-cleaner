//
//  LMPPOneClickGuideView.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMPPOneClickGuideView : NSView

// 一键开启按钮回调
@property (nonatomic, copy) void(^oneClickBlock)(void);

@end

NS_ASSUME_NONNULL_END
