//
//  LMToastWindow.h
//  LemonGetText
//
//

#import <Cocoa/Cocoa.h>
#import "LMToastContentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMToastWindow : NSWindowController

/// toast 样式
@property (nonatomic, assign) LMToastViewStyle style;
/// toast 标题
@property (nonatomic, copy) NSString *title;
/// 展示时间。默认3秒
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, strong, readonly) LMToastContentView *contentView;

+ (instancetype)toastViewWithStyle:(LMToastViewStyle)style title:(NSString *)title;

/// 显示 toast。如不设置duration，默认3秒后消失
/// - Parameter point: 显示在哪个位置
- (void)showAtPoint:(NSPoint)point;

/// 显示 toast
/// - Parameters:
///   - point: 显示在哪个位置
///   - duration: 显示时间
- (void)showAtPoint:(NSPoint)point duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
