//
//  COSwitch.h
//  SlideControl
//
//  
//  Copyright (c) 2014 stcui. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Availability.h>

@interface COSwitch : NSView
@property (strong) NSColor *onBorderColor;
@property (strong) NSColor *offBorderColor;
@property (strong) NSColor *onToggleColor;
@property (strong) NSColor *offToggleColor;
@property (strong) NSColor *offFillColor;
@property (assign, nonatomic, getter=isOn) BOOL on;
@property (assign, nonatomic) BOOL isEnable;
@property (assign, nonatomic) BOOL isAnimator;
@property (copy) void(^onValueChanged)(COSwitch *button);
// 暴露出点击事件,已经点击状态已经改变
@property (copy) void(^onDidClicked)(COSwitch *button);

// 仅修改UI开关状态，不传播
- (void)updateSwitchState:(BOOL)on;
@end
