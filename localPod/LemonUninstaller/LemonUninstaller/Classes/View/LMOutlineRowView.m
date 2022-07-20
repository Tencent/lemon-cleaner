//
//  LMOutlineRowView.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMOutlineRowView.h"
#import "NSColor+Extension.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <Masonry/Masonry.h>

@implementation LMOutlineRowView
{
    NSView *_aView;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        m_selectedColor =  [LMAppThemeHelper getTableViewRowSelectedColor]; 
    }
    return self;
}

- (void)addSubview:(NSView *)aView;
{
    [super addSubview:aView];
    if ([aView isKindOfClass:[NSButton class]])
    {
        _aView = aView;
        NSImage * _triangleImage = [NSImage imageNamed:@"triangleButton"];
        NSImage * _triangleAlternateImage = [NSImage imageNamed:@"triangleButtonSelected"];
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
            [aView setFrameOrigin:NSMakePoint(688.0, aView.frame.origin.y)];
        }
//        [self adjustAViewPosition];
    } else {
        NSRect oldRect = aView.frame;
        aView.frame = NSMakeRect(0, 0, 700, oldRect.size.height);
    }
}


//-(void)didAddSubview:(NSView *)subview
//{
//    [super didAddSubview:subview];
//}
//
//- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
//    if(!_aView)
//        return;
//    [self adjustAViewPosition];
//}
//
//- (void)adjustAViewPosition {
//    NSPoint point = _aView.frame.origin;
////    if(_rowViewDelegate.isPreviewing) {
////        point.x = 335;
////    } else {
////        point.x = 688;
////    }
//    [_aView setFrameOrigin:point];
//}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
    //    if ([self isFloating])
    //    {
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[LMAppThemeHelper getMainBgColor] set];
    [path fill];
    //    }
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [m_selectedColor set];
    [path fill];
}


@end
