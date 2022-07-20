//
//  QMBubble.h
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMUICommon/QMBubbleViewTypes.h>

enum
{
    QMBubbleAutoCloseNone = 0,
    QMBubbleAutoCloseLocal = 1<<0,
    QMBubbleAutoCloseOutside = 1<<1,
    QMBubbleAutoCloseGlobal = QMBubbleAutoCloseLocal|QMBubbleAutoCloseOutside
};
typedef NSInteger QMBubbleAutoCloseType;

@interface QMBubble : NSObject
@property (nonatomic, readonly) NSWindow *bubbleWindow;
/*
 显示的方向
 */
@property (nonatomic, assign) QMArrowDirection direction;
/*
 是否画箭头
 */
@property (nonatomic, assign) BOOL drawArrow;
/*
 箭头的宽度
 */
@property (nonatomic, assign) double arrowHeight;
/*
 箭头的高度
 */
@property (nonatomic, assign) double arrowWidth;
/*
 箭头相对于边缘的距离
 */
@property (nonatomic, assign) double arrowDistance;
/*
 箭头相对于参照点的偏移距离
 */
@property (nonatomic, assign) double arrowOffset;
/*
 气泡的圆角半径
 */
@property (nonatomic, assign) double cornerRadius;
/*
 气泡的边宽
 */
@property (nonatomic, assign) double borderWidth;
/*
 气泡的边框颜色
 */
@property (nonatomic, strong) NSColor *borderColor;
/*
 气泡的背景色
 */
@property (nonatomic, strong) NSColor *backgroudColor;
/*
 气泡在显示/消失时是否有淡入淡出动画,默认YES
 */
@property (nonatomic, assign) BOOL animation;
/*
 气泡是否以KeyWindow方式显示
 */
@property (nonatomic, assign) BOOL keyWindow;
/**
 自动关闭的触发条件
 QMBubbleAutoCloseNone:不自动关闭(默认)
 QMBubbleAutoCloseLocal:程序内点击了气泡外的区域
 QMBubbleAutoCloseOutside:当点击了程序外的任何区域
 QMBubbleAutoCloseGlobal:满足以上两者任一条件
 */
@property (nonatomic, assign) QMBubbleAutoCloseType autoCloseMask;
/**
 气泡内容View
 */
@property (nonatomic, strong) NSView *contentView;
/**
 气泡显示的内容ViewController
 */
@property (nonatomic, strong) NSViewController *viewController;

/// 内容的边距
@property (nonatomic, assign) NSEdgeInsets edgeInsets;

/// 箭头所在的点(屏幕坐标系)
@property (nonatomic, readonly) NSPoint arrowPoint;

@property (nonatomic, assign) double distance;
/// 是否可拖拽
@property (nonatomic) BOOL draggable;
@property (nonatomic, readonly) BOOL attachedToParentWindow;
/// 标题栏模式
@property (nonatomic, assign) QMBubbleTitleMode titleMode;

- (void)detatchFromParentWindow;
- (void)attachToParentWindow;

- (void)showToPoint:(NSPoint)positioningPoint ofView:(NSView *)positioningView;
- (void)showToPoint:(NSPoint)positioningPoint ofWindow:(NSWindow *)positioningWindow;

- (void)dismiss;
- (void)dismissWithCompletion:(void(^)(QMBubble *))completion;
- (BOOL)isVisible;

@end

@interface QMBubble (Proxy)
- (void)resetDragStartToCurrentPosition;
@end
