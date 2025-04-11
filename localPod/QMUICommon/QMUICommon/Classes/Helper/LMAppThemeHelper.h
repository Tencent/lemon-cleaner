//
//  LMAppThemeHelper.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LMColor) {
    LMColor_Theme = 0,
    LMColor_Yellow,
    LMColor_Gray_Hover,
    LMColor_Green_Normal,
    LMColor_Green_Hover,
    LMColor_Green_Disable,
    LMColor_Green_Text,
    LMColor_Blue_Normal,
    LMColor_Red_Normal,
    LMColor_Title_Black,
    LMColor_MainText_Black,
    LMColor_SubText_Dark,
    LMColor_SubText_Light,
    LMColor_Text_Gray,
    LMColor_Border1,
    LMColor_Border2,
    
    LMColor_DefaultBackground,
    LMColor_White,
    LMColor_ButtonBackground_Hover,
    LMColor_ButtonBackground_Press,
    LMColor_NavigationBackground,
};

@interface LMAppThemeHelper : NSObject
/**
 设置NSTextFields的文字颜色
 
 colorName : title_color
 @param textField textField
 */
+(void)setTitleColorForTextField:(NSTextField *)textField;

/**
 设置NSTextField text的颜色

 @param colorName colorAsset中的name
 @param defaultColor 10.14版本以下显示的颜色
 @param textField textField
 */
+(void)setTextColorName: (NSString *)colorName defaultColor: (NSColor *) defaultColor for: (NSTextField *)textField;

/**
 判断当前是否是暗黑主题
 
 @return true: 是
 */
+(Boolean)isDarkMode;


/**
 获取TableView中item鼠标hover时的颜色
 
 colorName : tableview_selector_bg_color

 @return color
 */
+(NSColor *)getTableViewRowSelectedColor;

/**
 设置分割线的颜色
 @param view divideView
 */
+(void)setDivideLineColorFor:(NSView*) view;


/**
 设置View layer的背景

 colorName : main_bg_color
 
 注意：该方法需要在系统回调的方法中设置比如“viewWillLayout”,否则切换mode不会立即生效
 @param view view
 */
+(void)setLayerBackgroundWithMainBgColorFor:(NSView *) view;

// 获取分割线颜色
+(NSColor *)getDivideLineColor;

/**
 colorName : main_bg_color

 @return color
 */
+(NSColor *)getMainBgColor;

/**
 colorName : title_color

 @return color
 */
+(NSColor *)getTitleColor;


/**
 获取Monitor Tab底部view的背景颜色

 colorName : monitor_tab_bottom_bg_color

 @return color
 */
+(NSColor *)getMonitorTabBottomBgColor;


/**
 获取Monitor中Memory占用view的背景

 colorName : monitor_memory_fill_color
 @return light_bg_color
 */
+(NSColor *)getMonitorMemoryViewFillColor;

/**
 获取提示文本的颜色
 
 colorName : tips_text_color
 @return color
 */
+(NSColor *)getTipsTextColor;

/**
 获取提示文本的颜色
 
 colorName : tips_bg_color
 @return color
 */
+(NSColor *)getTipsViewBgColor;

/**
 colorName : third_text_color

 @return color
 */
+(NSColor *)getThirdTextColor;

/**
 colorName : second_text_color
 
 @return color
 */
+(NSColor *)getSecondTextColor;


/**
 获取颜色值为title_color的颜色
 
 该方法获取的颜色值不会跟随模式改变而变化，所以需要在回调方法中更新颜色

 @return fixed color
 */
+(NSColor *)getFixedTitleColor;

/**
 获取颜色值为main_bg_color的颜色
 
 该方法获取的颜色值不会跟随模式改变而变化，所以需要在回调方法中更新颜色

 @return fixed color
 */
+(NSColor *)getFixedMainBgColor;

/**
 获取LMRectangleButton 在disable 状态下的背景颜色

 colorName : rectangle_button_disabled_bg_color
 @return color
 */
+(NSColor *)getRectangleBtnDisabledBgColor;

/**
 获取LMRectangleButton 在disable 状态下Text的颜色
 
 colorName : rectangle_button_disabled_text_color
 @return color
 */
+(NSColor *)getRectangleBtnDisabledTextColor;

/**
 获取拖拽view的背景颜色

 @return fixed color
 */
+(NSColor *)getDragShadowViewBgColor;

/**
获取button的边框颜色

@return colorName : small_btn_border_color
*/
+(NSColor *)getSmallBtnBorderColor;

/**
获取Scrollbar 颜色值

@return colorName : scrollbar_color
*/
+(NSColor *)getScrollbarColor;

#pragma mark - 5.2.0

/// 获取适配了暗黑模式的色值
/// - Parameter color: see LMColor
+ (NSColor *)getColor:(LMColor)color;

/// 获取色值，可不适配暗黑模式
/// - Parameters:
///   - color: see LMColor
///   - lightModeOnly: 是否仅返回浅色模式
+ (NSColor *)getColor:(LMColor)color lightModeOnly:(BOOL)lightModeOnly;

/// 获取CGColorRef的非动态色值
/// 因 layer.backgroundColor 不支持动态色值，故提供此方法。适配暗黑模式时需同时在 -[NSView viewDidChangeEffectiveAppearance] 方法中更新CGColor
/// - Parameter color: see LMColor
+ (CGColorRef)getCGColorRef:(LMColor)color;

@end

NS_ASSUME_NONNULL_END
