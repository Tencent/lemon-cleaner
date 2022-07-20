//
//  LMCheckboxButton.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMCheckboxButton : NSButton

@property BOOL changeToMixStateNotOnStateWhenClick;  // 点击时,off => mix, 并且 mix/on => off. 主要用于智能选择模块
@end
