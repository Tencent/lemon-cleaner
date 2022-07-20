//
//  LMBorderButton.h
//  QMUICommon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMBorderButton : NSButton

@property (nonatomic, strong) NSColor * titleNormalColor;
@property (nonatomic, strong) NSColor * titleHoverColor;
@property (nonatomic, strong) NSColor * titleDownColor;
@property (nonatomic, strong) NSColor * titleDisableColor;
@property (nonatomic, strong) NSColor * borderNormalColor;
@property (nonatomic, strong) NSColor * borderHoverColor;
@property (nonatomic, strong) NSColor * borderDownColor;
@property (nonatomic, strong) NSColor * borderDisableColor;
@property (assign) float radius;
@property (assign) float borderWidth;
@property (assign) float fontSize;
@property (assign) float isFontLight;

@end
