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
@end
