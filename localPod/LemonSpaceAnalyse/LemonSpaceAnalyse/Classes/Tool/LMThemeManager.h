//
//  LMThemeManager.h
//  LemonSpaceAnalyse
//
//  
//

#import <Foundation/Foundation.h>

#define V_LIGHT_MODE    1       //light mode
#define V_DARK_MODE     2       //dark mode
#define V_FOLLOW_SYSTEM 0       //随系统变化

typedef NS_ENUM(NSUInteger, CurrentTheme) {
    CurrentThemeFollowSystem = 0,
    CurrentThemeLightMode = 1,
    CurrentThemeDarkMode = 2 ,
};

@interface LMThemeManager : NSObject

+ (CurrentTheme)cureentTheme;

+ (BOOL)isHiddenItemForPath:(NSString *)path;

@end

