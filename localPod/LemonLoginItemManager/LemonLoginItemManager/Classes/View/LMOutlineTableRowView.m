//
//  LMOutlineTableRowView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMOutlineTableRowView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <Masonry/Masonry.h>

@interface LMOutlineTableRowView ()

@property (nonatomic) NSColor * m_selectedColor;

@end

@implementation LMOutlineTableRowView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _m_selectedColor = [LMAppThemeHelper getTableViewRowSelectedColor];
    }

    return self;
}

- (void)addSubview:(NSView *)view {

    [super addSubview:view];

    if ([view isKindOfClass:NSButton.class]) {
//        [super addSubview:view positioned:NSWindowBelow relativeTo:nil];
        NSImage *_triangleImage = [NSImage imageNamed:@"triangleButton" withClass:self.class];
        NSImage *_triangleAlternateImage = [NSImage imageNamed:@"triangleButtonSelected" withClass:self.class];
        [(NSButton *) view setImage:_triangleImage];
        [(NSButton *) view setAlternateImage:_triangleAlternateImage];
        // 在低版本机器上显示不正常.(左移了) 所以这里设置为固定值.
//        [view setFrameOrigin:NSMakePoint(self.frame.origin.x + self.frame.size.width - view.frame.size.width - 40, view.frame.origin.y)];  //50 时 scrollBar 的宽度.
        if (@available(macOS 12.0, *)) {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(view.superview.mas_right).offset(-50);
                make.centerY.equalTo(view.superview);
                make.height.mas_equalTo(64);
                make.width.mas_equalTo(13);
            }];
        } else {
            if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish) {
                [view setFrameOrigin:NSMakePoint(720, view.frame.origin.y)];
            } else {
                [view setFrameOrigin:NSMakePoint(705, view.frame.origin.y)];
            }
        }
        NSButton *button = (NSButton *)view;
        button.enabled = NO;
    }

}

// 当 outlineView reloadItem 时, 会触发 outlineView viewForTableColumn 重新调用,并重新调用 tableView 的 addSubView 方法. 这时会触发 expand button 位于 cellView 后面的问题.
// 如果不移动 expand button 没事(cell view 和 expand view 没有重合) 但移动 expand button 后就会有button 被遮挡的问题. 造成 button 无法响应事件.
// rowViw 可能会重新添加 cellView, 这时需要将 expand Button 置于最前面.

- (void)moveExpandButtonToFront {
    [self sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *)) compareViews context:nil];
}

NSComparisonResult compareViews(id firstView, id secondView, void *context) {

    if ([firstView isKindOfClass:NSButton.class]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedAscending;
    }
}

// MARK: 可以复写这个方法 , 提供背景的绘制 ,不然cell 背景可能是黑色的
- (void)drawBackgroundInRect:(NSRect)dirtyRect {

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[LMAppThemeHelper getMainBgColor] set];
    [path fill];
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [_m_selectedColor set];
    [path fill];
}


@end
