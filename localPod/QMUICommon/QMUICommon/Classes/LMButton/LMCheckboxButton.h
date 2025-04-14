//
//  LMCheckboxButton.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^LMValueDidChangeBlock)(BOOL value);

@interface LMCheckboxButton : NSButton

@property BOOL changeToMixStateNotOnStateWhenClick;  // 点击时,off => mix, 并且 mix/on => off. 主要用于智能选择模块

@property (nonatomic, readonly) BOOL isHoveredBubble; // 为气泡准备的hover
@property (nonatomic, copy) LMValueDidChangeBlock hoverBubbleHandler; // 为气泡准备的hover态发生变化

@end
