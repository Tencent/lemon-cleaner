//
// 
// Copyright (c) 2018 tencent. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "LMViewHelper.h"
#import "NSImage+LMImageAdditions.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMImageButton.h"
#import "LMRectangleButton.h"
#import "NSFontHelper.h"
#import "ClickableTextField.h"

@implementation LMViewHelper

+ (NSTextField *)createNormalLabel:(int)fontSize fontColor:(NSColor *)color {
    return [self createNormalLabel:fontSize fontColor:color fonttype:LMFontTypeRegular];
}

+ (NSTextField *)createNormalLabel:(int)fontSize fontColor:(NSColor *)color fonttype:(LMFontType)fontType{
    NSTextField *label = [[NSTextField alloc] init];
    return [self innerSetLabel:label size:fontSize fontColor:color fonttype:fontType];
}

+ (NSTextField *)createAcceptsFirstMouseLabel:(int)fontSize fontColor:(NSColor *)color fonttype:(LMFontType)fontType{
    ClickableTextField *label = [[ClickableTextField alloc] init];
    return [self innerSetLabel:label size:fontSize fontColor:color fonttype:fontType];
}

+ (NSTextField *)innerSetLabel:(NSTextField *)label  size:(int)fontSize fontColor:(NSColor *)color fonttype:(LMFontType)fontType{
    label.bordered = NO;
    label.editable = NO;
    label.drawsBackground = NO;
    NSFont *font;
    switch (fontType) {
        case LMFontTypeLight:
            font = [NSFontHelper getLightSystemFont:fontSize];
            break;
        case LMFontTypeRegular:
            font = [NSFontHelper getRegularSystemFont:fontSize];
            break;
        case LMFontTypeMedium:
            font = [NSFontHelper getMediumSystemFont:fontSize];
            break;
        default:
            font =  [NSFontHelper getRegularSystemFont:fontSize];
            break;
    }
    label.font = font;
    label.textColor = color;
    return label;
}


+ (NSButton *)createNormalTextButton:(int)fontSize title:(NSString *)title  textColor:(NSColor*)color{
    NSButton *button = [[NSButton alloc] init];
    [button setBezelStyle:NSTexturedSquareBezelStyle];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bordered = NO;
    button.focusRingType = NSFocusRingTypeNone;
    // button 不绘制背景.
    button.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    NSFont *font = [NSFontHelper getRegularSystemFont:fontSize];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    button.alignment = NSTextAlignmentCenter;
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName:color};
    NSAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:attributes];
    button.attributedTitle = titleString;
    return button;
}

+ (NSButton *)createNormalTextButton:(int)fontSize title:(NSString *)title  textColor:(NSColor*)color alignment:(NSTextAlignment) alignment{
    NSButton *button = [[NSButton alloc] init];
    [button setBezelStyle:NSTexturedSquareBezelStyle];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bordered = NO;
    button.focusRingType = NSFocusRingTypeNone;
    // button 不绘制背景.
    button.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    NSFont *font = [NSFontHelper getRegularSystemFont:fontSize];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    button.alignment = alignment;
    style.alignment = alignment;
    NSDictionary *attributes = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: style, NSForegroundColorAttributeName:color};
    NSAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:attributes];
    button.attributedTitle = titleString;
    return button;
}

// 普通 button(图片)
+ (NSButton *)createNormalButton
{
    NSButton * button = [[NSButton alloc] init];
    [button setButtonType:NSButtonTypeMomentaryChange];
    [button setBezelStyle:NSRecessedBezelStyle];
    [button setFocusRingType:NSFocusRingTypeNone];
    button.bordered = NO;
    // 图片的缩放由自己决定, 因为可能 button 图片较小,但响应区域较大,不能自动伸缩.
//    button.imagePosition = NSImageOverlaps;
//    button.imageScaling = NSImageScaleProportionallyUpOrDown;
    return button;
}

+ (NSButton *)createNormalGreenButton:(int)fontSize title:(NSString *)title {
    LMRectangleButton *button = [[LMRectangleButton alloc] initWithFrame:NSZeroRect];    button.imageScaling = NSImageScaleProportionallyUpOrDown;
    [button setBezelStyle:NSTexturedSquareBezelStyle];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.imagePosition = NSImageOverlaps;
    button.bordered = NO;  //特别注意 cornerRadius 设置时别忘了这里
    button.font = [NSFont systemFontOfSize:fontSize];
    button.alignment = NSTextAlignmentCenter;
    button.title = title;
    return button;
}

+ (NSButton *)createSmallGreenButton:(int)fontSize title:(NSString *)title {
    LMRectangleButton *button = [[LMRectangleButton alloc] initWithFrame:NSZeroRect];
    button.imageScaling = NSImageScaleProportionallyUpOrDown;
    [button setBezelStyle:NSTexturedSquareBezelStyle];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bordered = NO;  //特别注意 cornerRadius 设置时别忘了这里
    button.imagePosition = NSImageOverlaps;
    
    NSColor *initColor = [NSColor whiteColor];
    NSFont *font = [NSFont systemFontOfSize:fontSize];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    button.alignment = NSTextAlignmentCenter;
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: initColor,
                                 NSParagraphStyleAttributeName: style};
    NSAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:attributes];
    button.attributedTitle = titleString;
    
    return button;
}

+ (NSImage *)getImageFromSelfBundle:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSImage *image = [bundle imageForResource:imageName];
    return image;
}

+ (NSImage *)getImageFromBundleWithObject:(NSObject*)obj imageName:(NSString *)imageName{
    if(!obj){
        return nil;
    }
    NSBundle *bundle = [NSBundle bundleForClass:obj.class];
    NSImage *image = [bundle imageForResource:imageName];
    return image;
}

+ (NSButton *)createCheckButtonWithMixedState:(BOOL)mixed {
    NSButton *checkButton = [[NSButton alloc] init];
    checkButton.title = @"";
    [checkButton setButtonType:NSButtonTypeSwitch];
    checkButton.allowsMixedState = mixed;
    return checkButton;
}


+ (NSImageView *)createNormalImageView {
    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    // Proportionally 按比例的
    // Axes: 轴  Independent: 独立的
    
    // scaleAxesIndependently : AspectFill
    // scaleProportionallyUpOrDown: AspectFit
    // scaleProportionallyDown: CenterTop
    
    
    // 可以通过特殊方法 更改 image 的大小     //  self.image!.size.width  = newWidth;self.image!.size.height = newHeight
    
    // 另外的方法, 更改 Layer
    //    self.layer = [[CALayer alloc] init];
    //    self.layer.contentsGravity = kCAGravityResizeAspectFill;
    //    self.layer.contents = image;
    //    self.wantsLayer = YES;
    
    imageView.imageAlignment = NSImageAlignCenter;
    return imageView;
}

+ (NSView *)createPureColorView:(NSColor *)color
{
    NSView *view = [[NSView alloc]init];
    view.wantsLayer = YES;
    view.layer.backgroundColor = color.CGColor;
    return view;
}
@end
