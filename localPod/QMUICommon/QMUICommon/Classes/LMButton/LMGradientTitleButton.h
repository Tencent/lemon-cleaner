//
//  LMGradientTitleButton.h
//  Lemon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMGradientTitleButton : NSButton
@property (nonatomic, strong) NSColor * titleNormalColor;
@property (nonatomic, strong) NSColor * titleHoverColor;
@property (nonatomic, strong) NSColor * titleDownColor;
@property (nonatomic, strong) NSColor * titleDisableColor;
@property (nonatomic, strong) NSColor * normalColor;
@property (nonatomic, strong) NSColor * hoverColor;
@property (nonatomic, strong) NSColor * downColor;
@property (nonatomic, strong) NSColor * disableColor;
@property (nonatomic, strong) NSColor * fillColor;
@property (nonatomic, strong) NSArray * normalColorArray;
@property (nonatomic, strong) NSArray * hoverColorArray;
@property (nonatomic, strong) NSArray * downColorArray;
@property (nonatomic, strong) NSArray * disableColorArray;
@property (assign) BOOL isGradient;
@property (assign) BOOL isBorder;
@property (assign) float radius;
@property (assign) float lineWidth;
@property (assign) float angle;
@end
