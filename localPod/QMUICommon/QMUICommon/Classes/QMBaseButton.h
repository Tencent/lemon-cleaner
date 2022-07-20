//
//  QMBaseButton.h
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    QMState_on      =   1<<0,
    QMState_off     =   1<<1,
    QMState_mixed   =   1<<2,
};

enum
{
    QMState_normal  = 1<<3,
    QMState_hover   = 1<<4,
    QMState_pressed = 1<<5,
    QMState_disable = 1<<6
};

typedef NSInteger QMStateType;

@interface QMBaseButton : NSButton
{
    BOOL mouseEnter;
    BOOL mouseDown;
}

- (void)setUp;
- (QMStateType)buttonState;


@end

#pragma mark - QMStateButton

@interface QMStateButton : QMBaseButton

- (void)setImage:(NSImage *)image forState:(QMStateType)st;
- (NSImage *)imageForState:(QMStateType)st;

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle forState:(QMStateType)st;
- (NSAttributedString *)attributedTitleForState:(QMStateType)st;

@end
