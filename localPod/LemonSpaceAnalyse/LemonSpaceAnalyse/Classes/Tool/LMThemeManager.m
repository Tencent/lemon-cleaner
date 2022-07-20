//
//  LMThemeManager.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMThemeManager.h"
#import <AppKit/AppKit.h>
@implementation LMThemeManager
+ (CurrentTheme)cureentTheme{
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance; // only 10.14
        NSString *str = [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]];
        BOOL isDark = (str == NSAppearanceNameDarkAqua);
        return isDark;
    } else {
        return false;
    }
    return false;
}


// 判断隐藏文件
+ (BOOL)isHiddenItemForPath:(NSString *)path {
    if ([[path lastPathComponent] hasPrefix:@"."])
        return YES;
    
    NSNumber * isHidden = nil;
    NSError *error;
    [[NSURL fileURLWithPath:path] getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:&error];
    return [isHidden boolValue];
}
@end
