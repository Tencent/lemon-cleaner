//
//  LMRectangleButton.m
//  QMUICommon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMRectangleButton.h"
#import "NSFontHelper.h"
#import "LMAppThemeHelper.h"
@implementation LMRectangleButton

- (void)setDefault{
    
    self.bordered = NO;
    
    
    self.isGradient = YES;
    self.radius = 2;
    self.titleNormalColor = [NSColor colorWithHex:0xffffff];
    self.normalColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x64DFA7],
                             [NSColor colorWithHex:0x00D899], nil];
    self.hoverColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x69E8AE],
                            [NSColor colorWithHex:0x00E9A5], nil];
    self.downColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x61CE9C],
                           [NSColor colorWithHex:0x00D093], nil];
    self.disableColorArray = [NSArray arrayWithObjects:[LMAppThemeHelper getRectangleBtnDisabledBgColor],
                              [LMAppThemeHelper getRectangleBtnDisabledBgColor], nil];
    self.titleDisableColor = [LMAppThemeHelper getRectangleBtnDisabledTextColor];
    //默认使用light字体
    self.font = [NSFontHelper getLightSystemFont:self.font.pointSize];
}

@end
