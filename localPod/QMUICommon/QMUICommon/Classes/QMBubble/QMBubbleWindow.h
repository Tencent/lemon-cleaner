//
//  QMBubbleWindow.h
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Availability.h>

@interface QMBubbleWindow : NSWindow

@property (nonatomic, assign) BOOL keyWindowMode;

- (id)initWithContentRect:(NSRect)contentRect;

@end
