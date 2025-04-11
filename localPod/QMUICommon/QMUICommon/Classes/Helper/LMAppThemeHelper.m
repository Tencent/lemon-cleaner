//
//  LMAppThemeHelper.m
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAppThemeHelper.h"

@implementation LMAppThemeHelper

+(void)setTitleColorForTextField:(NSTextField *)textField{
    [self setTextColorName:@"title_color" defaultColor:[NSColor colorWithHex:0x515151] for:textField];
}

+(void)setTextColorName: (NSString *)colorName defaultColor: (NSColor *) defaultColor for: (NSTextField *)textField{
    if (@available(macOS 10.14, *)) {
        [textField setTextColor:[NSColor colorNamed:colorName bundle:[NSBundle bundleForClass:[self class]] ]];
    } else {
        [textField setTextColor:defaultColor];
    }
}

+(Boolean)isDarkMode{
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance;
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    } else {
        return false;
    }
    return false;
}

+(NSColor *)getTableViewRowSelectedColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"tableview_selector_bg_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0xE8E8E8 alpha:0.6];
    }
}

+(void)setDivideLineColorFor:(NSView*) view{
    view.wantsLayer = YES;
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            view.layer.backgroundColor = [NSColor colorWithHex:0xFFFFFF alpha:0.05].CGColor;
        }else{
            view.layer.backgroundColor = [NSColor colorWithHex:0xEDEDED alpha:1].CGColor;
        }
        
    } else {
        view.layer.backgroundColor = [NSColor colorWithHex:0xEDEDED alpha:1].CGColor;
    }
}

+(void)setLayerBackgroundWithMainBgColorFor:(NSView *) view{
    view.wantsLayer = YES;
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            view.layer.backgroundColor = [NSColor colorWithHex:0x242633].CGColor;
        }else{
            view.layer.backgroundColor = [NSColor whiteColor].CGColor;
        }
    } else {
        view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
}

+(NSColor *)getDivideLineColor {
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0xFFFFFF alpha:0.05];
        }
    }
    return [NSColor colorWithHex:0xEDEDED alpha:1];
}

+(NSColor *)getMainBgColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"main_bg_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor whiteColor];
    }
}

+(NSColor *)getTitleColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"title_color" bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0x515151];
    }
}

+(NSColor *)getMonitorTabBottomBgColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0x3F404C];
        }else{
            return [NSColor colorWithHex:0xf5f5f5];
        }
    } else {
        return [NSColor colorWithHex:0xf5f5f5];
    }
}

+(NSColor *)getMonitorMemoryViewFillColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0x3F404C];
        }else{
            return [NSColor colorWithHex:0xF1F1F1];
        }
    } else {
        return [NSColor colorWithHex:0xF1F1F1];
    }
}

+(NSColor *)getTipsTextColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"tips_text_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0x94979B];
    }
}

+(NSColor *)getTipsViewBgColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"tips_bg_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0xffffff];
    }
}

+(NSColor *)getThirdTextColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"third_text_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0x000000 alpha:0.85];
    }
}

+(NSColor *)getSecondTextColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"second_text_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0x7E7E7E];
    }
}

+(NSColor *)getFixedTitleColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0xffffff];
        }else{
            return [NSColor colorWithHex:0x515151];
        }
    } else {
        return [NSColor colorWithHex:0x515151];
    }
}

+(NSColor *)getFixedMainBgColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0x242633];
        }else{
            return [NSColor colorWithHex:0xFFFFFF];
        }
    } else {
        return [NSColor colorWithHex:0xFFFFFF];
    }
}

+(NSColor *)getRectangleBtnDisabledBgColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"rectangle_button_disabled_bg_color" bundle:[NSBundle bundleForClass:[self class]] ];
    } else {
        return [NSColor colorWithHex:0xD1FAEF];
    }
}

+(NSColor *)getRectangleBtnDisabledTextColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"rectangle_button_disabled_text_color"  bundle:[NSBundle bundleForClass:[self class]]];
    } else {
        return [NSColor colorWithHex:0xFFFFFF];
    }
}

+(NSColor *)getDragShadowViewBgColor{
    if (@available(macOS 10.14, *)) {
        if([LMAppThemeHelper isDarkMode]){
            return [NSColor colorWithHex:0x2C2E3F alpha:0.8];
        }else{
            return [NSColor colorWithHex:0xD2E3FD alpha:0.75];
        }
        
    } else {
        return [NSColor colorWithHex:0xD2E3FD alpha:0.75];
    }
}

+(NSColor *)getSmallBtnBorderColor{
    if (@available(macOS 10.14, *)) {
           return [NSColor colorNamed:@"small_btn_border_color"  bundle:[NSBundle bundleForClass:[self class]]];
       } else {
           return [NSColor colorWithHex:0xe5e5e5];
       }
}

+(NSColor *)getScrollbarColor{
    if (@available(macOS 10.14, *)) {
           return [NSColor colorNamed:@"scrollbar_color"  bundle:[NSBundle bundleForClass:[self class]]];
       } else {
           return [NSColor colorWithHex:0x000000 alpha:0.3];
       }
}

#pragma mark - 5.2.0

+ (NSColor *)getColor:(LMColor)color {
    return [self getColor:color lightModeOnly:NO];
}

+ (NSColor *)getColor:(LMColor)color lightModeOnly:(BOOL)lightModeOnly {
    if (@available(macOS 10.14, *)) {
        if (lightModeOnly) {
            return [self _getLightColor:color];
        } else {
            NSString *colorName = [self _getColorName:color];
            return [NSColor colorNamed:colorName bundle:[NSBundle bundleForClass:[self class]]];
        }
    }
    
    return [self _getLightColor:color];
}

+ (CGColorRef)getCGColorRef:(LMColor)color {
    if ([LMAppThemeHelper isDarkMode]) {
        return [self _getDarkColor:color].CGColor;
    } else {
        return [self _getLightColor:color].CGColor;
    }
}

+ (NSString *)_getColorName:(LMColor)color {
    switch (color) {
        case LMColor_Theme: {
            return @"LMColor_Theme";
        }
        case LMColor_Yellow: {
            return @"LMColor_Yellow";
        }
        case LMColor_Gray_Hover: {
            return @"LMColor_Gray_Hover";
        }
        case LMColor_Green_Normal: {
            return @"LMColor_Green_Normal";
        }
        case LMColor_Green_Hover: {
            return @"LMColor_Green_Hover";
        }
        case LMColor_Green_Disable: {
            return @"LMColor_Green_Disable";
        }
        case LMColor_Green_Text: {
            return @"LMColor_Green_Text";
        }
        case LMColor_Blue_Normal: {
            return @"LMColor_Blue_Normal";
        }
        case LMColor_Red_Normal: {
            return @"LMColor_Red_Normal";
        }
        case LMColor_Title_Black: {
            return @"LMColor_Title_Black";
        }
        case LMColor_MainText_Black: {
            return @"LMColor_MainText_Black";
        }
        case LMColor_SubText_Dark: {
            return @"LMColor_SubText_Dark";
        }
        case LMColor_SubText_Light: {
            return @"LMColor_SubText_Light";
        }
        case LMColor_Text_Gray: {
            return @"LMColor_Text_Gray";
        }
        case LMColor_Border1: {
            return @"LMColor_Border1";
        }
        case LMColor_Border2: {
            return @"LMColor_Border2";
        }
            
        case LMColor_DefaultBackground: {
            return @"LMColor_DefaultBackground";
        }
        case LMColor_White: {
            return @"LMColor_White";
        }
        case LMColor_ButtonBackground_Hover: {
            return @"LMColor_ButtonBackground_Hover";
        }
        case LMColor_ButtonBackground_Press: {
            return @"LMColor_ButtonBackground_Press";
        }
        case LMColor_NavigationBackground: {
            return @"LMColor_NavigationBackground";
        }
    }
}

+ (NSColor *)_getLightColor:(LMColor)color {
    switch (color) {
        case LMColor_Theme: {
            return [NSColor colorWithHex:0xFFAA00];
        }
        case LMColor_Yellow: {
            return [NSColor colorWithHex:0xFFD500];
        }
        case LMColor_Gray_Hover: {
            return [NSColor colorWithHex:0xF5F5F5];
        }
        case LMColor_Green_Normal: {
            return [NSColor colorWithHex:0x00D991];
        }
        case LMColor_Green_Hover: {
            return [NSColor colorWithHex:0x57D9A3];
        }
        case LMColor_Green_Disable: {
            return [NSColor colorWithHex:0x9EEAD4];
        }
        case LMColor_Green_Text: {
            return [NSColor colorWithHex:0x20C57D];
        }
        case LMColor_Blue_Normal: {
            return [NSColor colorWithHex:0x057CFF];
        }
        case LMColor_Red_Normal: {
            return [NSColor colorWithHex:0xF25B3D];
        }
        case LMColor_Title_Black: {
            return [NSColor colorWithHex:0x28283C];
        }
        case LMColor_MainText_Black: {
            return [NSColor colorWithHex:0x515151];
        }
        case LMColor_SubText_Dark: {
            return [NSColor colorWithHex:0x696969];
        }
        case LMColor_SubText_Light: {
            return [NSColor colorWithHex:0x989A9E];
        }
        case LMColor_Text_Gray: {
            return [NSColor colorWithHex:0xDBD0C4];
        }
        case LMColor_Border1: {
            return [NSColor colorWithHex:0x909090 alpha:0.3];
        }
        case LMColor_Border2: {
            return [NSColor colorWithHex:0x9A9A9A alpha:0.2];
        }
            
        case LMColor_DefaultBackground: {
            return [NSColor colorWithHex:0xFAF9F7];
        }
        case LMColor_White: {
            return [NSColor colorWithHex:0xFFFFFF];
        }
        case LMColor_ButtonBackground_Hover: {
            return [NSColor colorWithHex:0 alpha:0.04];
        }
        case LMColor_ButtonBackground_Press: {
            return [NSColor colorWithHex:0 alpha:0.1];
        }
        case LMColor_NavigationBackground: {
            return [NSColor colorWithHex:0xFFF1D7];
        }
    }
}

+ (NSColor *)_getDarkColor:(LMColor)color {
    switch (color) {
        case LMColor_Theme: {
            return [NSColor colorWithHex:0xFFAA00];
        }
        case LMColor_Yellow: {
            return [NSColor colorWithHex:0xFFD500];
        }
        case LMColor_Gray_Hover: {
            return [NSColor colorWithHex:0x464646];
        }
        case LMColor_Green_Normal: {
            return [NSColor colorWithHex:0x00D991];
        }
        case LMColor_Green_Hover: {
            return [NSColor colorWithHex:0x57D9A3];
        }
        case LMColor_Green_Disable: {
            return [NSColor colorWithHex:0x9EEAD4];
        }
        case LMColor_Green_Text: {
            return [NSColor colorWithHex:0x1DB472];
        }
        case LMColor_Blue_Normal: {
            return [NSColor colorWithHex:0x057CFF];
        }
        case LMColor_Red_Normal: {
            return [NSColor colorWithHex:0xF25B3D];
        }
        case LMColor_Title_Black: {
            return [NSColor colorWithHex:0xFFFFFF];
        }
        case LMColor_MainText_Black: {
            return [NSColor colorWithHex:0xE6E6E6];
        }
        case LMColor_SubText_Dark: {
            return [NSColor colorWithHex:0xE6E6E6];
        }
        case LMColor_SubText_Light: {
            return [NSColor colorWithHex:0x989A9E];
        }
        case LMColor_Text_Gray: {
            return [NSColor colorWithHex:0xDBD0C4];
        }
        case LMColor_Border1: {
            return [NSColor colorWithHex:0x909090 alpha:0.3];
        }
        case LMColor_Border2: {
            return [NSColor colorWithHex:0x9A9A9A alpha:0.2];
        }
            
        case LMColor_DefaultBackground: {
            return [NSColor colorWithHex:0x272835];
        }
        case LMColor_White: {
            return [NSColor colorWithHex:0xFFFFFF];
        }
        case LMColor_ButtonBackground_Hover: {
            return [NSColor colorWithHex:0xFFFFFF alpha:0.1];
        }
        case LMColor_ButtonBackground_Press: {
            return [NSColor colorWithHex:0xFFFFFF alpha:0.3];
        }
        case LMColor_NavigationBackground: {
            return [NSColor colorWithHex:0x9A9A9A alpha:0.2];
        }
    }
}

@end
