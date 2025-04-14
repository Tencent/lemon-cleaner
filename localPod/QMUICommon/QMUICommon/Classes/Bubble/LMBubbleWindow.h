//
//  LMBubbleWindow.h
//  LemonGetText
//
//

#import <Cocoa/Cocoa.h>
#import "LMBubbleView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMBubbleWindow : NSWindowController <LMBubbleProtocol>

/// 气泡框
@property (nonatomic, strong, readonly) LMBubbleView *bubbleView;

/// 展示 bubble，使其箭头指向 pointAtView 的水平方向中心
/// - Parameter pointAtView: bubble 的箭头指向该 view
- (void)showAndPointAtView:(NSView *)pointAtView;

/// 展示 bubble，使其箭头指向 pointAtView 的水平方向中心，并基于垂直方向偏移一段距离。
/// - Parameters:
///   - pointAtView: bubble 的箭头指向该 view
///   - verticalOffset: 垂直方向向上的偏移量。为负则向下偏移
- (void)showAndPointAtView:(NSView *)pointAtView verticalOffset:(CGFloat)verticalOffset;

/// 在 position 位置上展示 bubble
/// - Parameter position: 相对屏幕的位置
- (void)showAtPosition:(CGPoint)position;

/// 隐藏 bubble
- (void)hide;

@end

NS_ASSUME_NONNULL_END
