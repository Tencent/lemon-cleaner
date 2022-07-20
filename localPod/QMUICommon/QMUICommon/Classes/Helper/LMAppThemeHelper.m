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
@end
