//
//  LMBubbleProtocol.h
//  QMUICommon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

typedef NS_ENUM(NSUInteger, LMBubbleStyle) {
    LMBubbleStyleCustom     = 0,    // 仅充当容器，内部自定义处理
    
    LMBubbleStyleText       = 1,    // 纯文本
    LMBubbleStyleTextButton = 2,    // 文本 + 按钮
};

typedef NS_ENUM(NSUInteger, LMBubbleArrowDirection) {
    LMBubbleArrowDirectionNone          = 0,
    LMBubbleArrowDirectionTopLeft       = 1,
    LMBubbleArrowDirectionTopRight      = 2,
    LMBubbleArrowDirectionBottomLeft    = 3,
    LMBubbleArrowDirectionBottomRight   = 4,
    // 其他方向暂无规范示例
};

@protocol LMBubbleProtocol <NSObject>

@required

/// Bubble 样式
@property (nonatomic, assign) LMBubbleStyle style;
/// 箭头方向
@property (nonatomic, assign) LMBubbleArrowDirection arrowDirection;

/// 箭头距离 view 左右间距。如果 ArrowDirection 是 Left 则为左间距，Right 则为右边距。默认0
/// 无论 arrowOffset 是多少，showInView:pointAtView: 时箭头都会指向 pointAtView
@property (nonatomic, assign) CGFloat arrowOffset;

/// 是否适配暗黑模式，默认YES
@property (nonatomic, assign) BOOL isDarkModeSupported;

/// 初始化
/// - Parameters:
///   - style: see LMBubbleStyle
///   - direction: see LMBubbleArrowDirection
+ (instancetype)bubbleWithStyle:(LMBubbleStyle)style arrowDirection:(LMBubbleArrowDirection)direction;

/// 设置 bubble 文本内容
/// - Parameter title: 文本
- (void)setBubbleTitle:(NSString *)title;

/// 设置 bubble 按钮部分的文本、及点击回调
/// - Parameters:
///   - text: 按钮文本
///   - buttonClickCallback: 点击按钮回调
- (void)setBubbleButtonText:(NSString *)text clickCallback:(dispatch_block_t)buttonClickCallback;

@end

