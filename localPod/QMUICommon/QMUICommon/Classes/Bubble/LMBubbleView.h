//
//  LMBubbleView.h
//  LemonAIAssistant
//
//

#import <Cocoa/Cocoa.h>
#import "QMBubbleView.h"
#import "LMBubbleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMBubbleView : NSView <LMBubbleProtocol>

/// 鼠标移开时是否自动隐藏，设置为 NO 时需手动 removeFromSuperview 以隐藏 bubble。默认 YES
@property (nonatomic, assign) BOOL autoHide;

/// 气泡框
@property (nonatomic, strong, readonly) QMBubbleView *bubbleBGView;

/// 在 superview 上展示 bubble，使其箭头指向 pointAtView 的水平方向中心。pointAtView 必须是 inView 的 subview
/// - Parameters:
///   - inView: 将 bubble 添加到该 view
///   - pointAtView: bubble 的箭头指向该 view。pointAtView 必须是 inView 的 subview
- (void)showInView:(NSView *)inView pointAtView:(NSView *)pointAtView;

/// 在 superview 上展示 bubble，使其箭头指向 pointAtView，并基于水平方向中心偏移一段距离。pointAtView 必须是 inView 的 subview
/// - Parameters:
///   - inView: 将 bubble 添加到该 view
///   - pointAtView: bubble 的箭头指向该 view。pointAtView 必须是 inView 的 subview
///   - horizontalOffset: 水平中心向右的偏移量
- (void)showInView:(NSView *)inView pointAtView:(NSView *)pointAtView horizontalOffset:(CGFloat)horizontalOffset;

/// 在 superview 的 position 位置上展示 bubble
/// - Parameters:
///   - inView: 将 bubble 添加到该 view
///   - position: 相对 inView 的位置
- (void)showInView:(NSView *)inView atPosition:(CGPoint)position;

/// 计算 LMBubbleStyleText、LMBubbleStyleTextButton 的气泡 size
- (CGSize)calculateViewSize;

@end

NS_ASSUME_NONNULL_END
