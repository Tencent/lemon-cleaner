//
// 
// Copyright (c) 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QMCoreFunction/NSColor+Extension.h>


typedef enum
{
    LMFontTypeLight,
    LMFontTypeMedium,
    LMFontTypeRegular,
}LMFontType;

@interface LMViewHelper : NSObject

+ (NSTextField *)createNormalLabel:(int)fontSize fontColor:(NSColor *)color;

+ (NSTextField *)createNormalLabel:(int)fontSize fontColor:(NSColor *)color fonttype:(LMFontType)fontType;

+ (NSTextField *)createAcceptsFirstMouseLabel:(int)fontSize fontColor:(NSColor *)color fonttype:(LMFontType)fontType;

+ (NSButton *)createNormalTextButton:(int)fontSize title:(NSString *)title  textColor:(NSColor*)color;

+ (NSButton *)createNormalTextButton:(int)fontSize title:(NSString *)title  textColor:(NSColor*)color alignment:(NSTextAlignment) alignment;

+ (NSButton *)createNormalGreenButton:(int)fontSize title:(NSString *)title;

+ (NSButton *)createSmallGreenButton:(int)fontSize title:(NSString *)title;

+ (NSImage *)getImageFromSelfBundle:(NSString *)imageName;

+ (NSImage *)getImageFromBundleWithObject:(NSObject*)obj imageName:(NSString *)imageName ;

+ (NSButton *)createCheckButtonWithMixedState:(BOOL)mixed;

+ (NSImageView *)createNormalImageView;

+ (NSView *)createPureColorView:(NSColor *)color;

+ (NSButton *)createNormalButton;

@end
