//
//  LMFileMoveCommonDefines.h
//  LemonFileMove
//
//  
//

#ifndef LMFileMoveCommonDefines_h
#define LMFileMoveCommonDefines_h

#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>

#import <Masonry/Masonry.h>
#import "NSTextAttachment+Addition.h"

#define LM_COLOR_GRAY           [NSColor colorWithHex:0x989A9E]
#define LM_COLOR_YELLOW         [NSColor colorWithHex:0xFFAA00]
#define LM_COLOR_BLUE           [NSColor colorWithHex:0x057CFF]

#define LM_IMAGE_NAMED(name) [NSImage imageNamed:name withClass:[self class]]
#define LM_LOCALIZED_STRING(key) NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], @"")
#define LM_IS_CHINESE_LANGUAGE (([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) ? YES: NO)

// 拼接AttributedString
#define LM_APPEND_ATTRIBUTED_STRING(_text, _string, _color, _fontSize) \
[_text appendAttributedString:[[NSAttributedString alloc] initWithString:_string attributes:@{NSForegroundColorAttributeName: _color, NSFontAttributeName: [NSFont systemFontOfSize:_fontSize]}]]

// 拼接icon和文案
#define LM_APPEND_ICON_AND_STRING(_text, _icon, _iconSize, _string, _font, _fontColor) \
    [_text appendAttributedString:[NSAttributedString attributedStringWithAttachment:[NSTextAttachment mqqAttachmentWithImage:_icon size:_iconSize font:_font]]]; \
    [_text appendAttributedString:[[NSAttributedString alloc] initWithString:_string attributes:@{NSForegroundColorAttributeName: _fontColor, NSFontAttributeName: _font}]];

static inline NSColor * lm_backgroundColor() {
    if ([LMAppThemeHelper isDarkMode]) {
        return [NSColor colorWithHex:0x242633];
    } else {
        return [NSColor whiteColor];
    }
}

static inline CGFloat lm_localizedCGFloat(CGFloat chineseCGFloat, CGFloat englishCGFloat) {
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        return chineseCGFloat;
    } else {
        return englishCGFloat;
    }
}

#endif /* LMFileMoveCommonDefines_h */
