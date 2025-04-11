//
//  LMToastView.h
//  QMUICommon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMToastContentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMToastView : NSView

/// toast 样式
@property (nonatomic, assign) LMToastViewStyle style;
/// toast 标题
@property (nonatomic, copy) NSString *title;
/// 展示时间。默认3秒
@property (nonatomic, assign) NSTimeInterval duration;

/// 距离 view 顶部间距，优先级高于 bottomOffset，默认 0
@property (nonatomic, assign) CGFloat topOffset;
/// 距离 view 底部间距，默认0
@property (nonatomic, assign) CGFloat bottomOffset;

@property (nonatomic, strong, readonly) LMToastContentView *contentView;

+ (instancetype)toastViewWithStyle:(LMToastViewStyle)style title:(NSString *)title;

/// 显示 toast。如不设置duration，默认3秒后消失
/// - Parameter view: 显示在哪个 view 上
- (void)showInView:(NSView *)view;

/// 显示 toast
/// - Parameters:
///   - view: 显示在哪个 view 上
///   - duration: 显示时间
- (void)showInView:(NSView *)view duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
