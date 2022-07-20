//
//  LMOpenButton.m
//  LemonMonitor
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMOpenButton.h"
#import "LMAppThemeHelper.h"

@implementation LMOpenButton

- (void)setDefault{
    
    self.bordered = NO;
    
    self.isGradient = YES;
    self.radius = 2;
    self.titleNormalColor = [LMAppThemeHelper getTitleColor];
    self.titleHoverColor = [NSColor colorWithHex:0x94979b];
    self.titleDownColor = [LMAppThemeHelper getTitleColor];
    self.titleDisableColor = [LMAppThemeHelper getTitleColor];
    
    self.normalColorArray = [self getColorArray];
    self.hoverColorArray = [self getColorArray];
    self.downColorArray = [self getColorArray];
    self.disableColorArray = [self getColorArray];
    
}

-(NSArray *)getColorArray{
    return [NSArray arrayWithObjects:[LMAppThemeHelper getMainBgColor],
            [LMAppThemeHelper getMainBgColor], nil];
}

@end
