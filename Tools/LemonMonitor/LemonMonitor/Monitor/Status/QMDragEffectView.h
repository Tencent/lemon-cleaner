//
//  QMDragFloatView.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, QMEffectMode)
{
    /// 菜单栏模式
    QMEffectStatusMode,
    /// 浮窗模式
    QMEffectFloatMode
};

@class QMDragEffectView;
@protocol QMDragEffectViewDelegate <NSObject>

- (void)dragEffectViewBegin:(QMDragEffectView *)effectView;
- (NSImage *)dragEffectViewReplaceImage:(QMDragEffectView *)effectView;
- (void)dragEffectView:(QMDragEffectView *)effectView endByMode:(QMEffectMode)endMode;

@end

@interface QMDragEffectView : NSView
@property (nonatomic, readonly) QMEffectMode effectMode;
@property (nonatomic, assign) IBOutlet id<QMDragEffectViewDelegate> dragDelegate;
@end
