//
//  LMBigResultTableRowView.m
//  QMCleaner
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "LMBigResultTableRowView.h"
#import <QuartzCore/QuartzCore.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@implementation LMBigResultTableRowView
{
    NSView *_aView;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
       m_selectedColor = [LMAppThemeHelper getTableViewRowSelectedColor];
//        if (@available(macOS 10.13, *)) {
//            m_selectedColor =  [NSColor colorNamed:@"tableview_selector_bg_color" bundle:[NSBundle mainBundle]];
//        } else {
//            m_selectedColor =  [NSColor colorWithHex:0xE8E8E8 alpha:0.6];
//        }
    }
    return self;
}

- (void)addSubview:(NSView *)aView;
{
    [super addSubview:aView];
    if ([aView isKindOfClass:[NSButton class]])
    {
        _aView = aView;
        NSImage * _triangleImage = [NSImage imageNamed:@"triangleButton" withClass:self.class];
        NSImage * _triangleAlternateImage = [NSImage imageNamed:@"triangleButtonSelected" withClass:self.class];
        [(NSButton*)aView setImage:_triangleImage];
        [(NSButton*)aView setAlternateImage:_triangleAlternateImage];
        
        if (@available(macOS 12.0, *)) {
            [aView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(aView.superview.mas_right).offset(-25);
                make.centerY.equalTo(aView.superview);
                make.height.mas_equalTo(64);
                make.width.mas_equalTo(13);
            }];
        } else {
            [aView setFrameOrigin:NSMakePoint(self.frame.size.width - aView.frame.size.width - 40, aView.frame.origin.y)];
            [self adjustAViewPosition];
        }
        
        
    }
}
-(void)didAddSubview:(NSView *)subview
{
    [super didAddSubview:subview];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    if(!_aView)
        return;
    [self adjustAViewPosition];
}

- (void)adjustAViewPosition {
    NSPoint point = _aView.frame.origin;
    if(_rowViewDelegate.isPreviewing) {
        point.x = 325;
    } else {
        point.x = 726;
    }
    [_aView setFrameOrigin:point];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[LMAppThemeHelper getMainBgColor] set];
        [path fill];
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [m_selectedColor set];
    [path fill];
}


@end
