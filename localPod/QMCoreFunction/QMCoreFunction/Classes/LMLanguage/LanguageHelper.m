//
//  LanguageHelper.m
//  AFNetworking
//
//

#import "LanguageHelper.h"

@implementation LanguageHelper

//设置多语言
+(void)setCurrentUserLanguage:(NSString *)userLanguage{
    if(userLanguage == nil){
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userLanguage forKey:USER_DEFAULTS_LANGUAGE_KEY];
    [defaults synchronize];
}

//获取多语言
+(NSString *)getCurrentUserLanguage{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value = [defaults objectForKey:USER_DEFAULTS_LANGUAGE_KEY];
    return value;
}

//获取多语言 --- 读取主工程的pref 主要是升级程序和托盘来使用
+(NSString *)getCurrentUserLanguageByReadFile{
//    NSString *filePath = [@"~/Library/Preferences/com.tencent.Lemon.plist" stringByStandardizingPath];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if(![fileManager fileExistsAtPath:filePath]){
//        return nil;
//    }
//
//    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:filePath];
//    if(dic == nil){
//        return nil;
//    }
//
//    NSString *language = [dic objectForKey:USER_DEFAULTS_LANGUAGE_KEY];
//    return language;
    CFPreferencesAppSynchronize((__bridge CFStringRef)(@"com.tencent.Lemon"));
    NSString *language = (__bridge_transfer NSString *)CFPreferencesCopyAppValue((__bridge CFStringRef)(USER_DEFAULTS_LANGUAGE_KEY), (__bridge CFStringRef)(@"com.tencent.Lemon"));
    return language;
}

+(SystemLanguageType)getCurrentSystemLanguageType{
    NSString *lanStr = NSLocalizedString(@"LEMON_LANGUAGE", @"");
    if ([lanStr isEqualToString:@"EN"]) {
        return SystemLanguageTypeEnglish;
    }else if([lanStr isEqualToString:@"中文"]){
        return SystemLanguageTypeChinese;
    }else{
        return SystemLanguageTypeOther;
    }
//    NSString *languageStr = [[NSLocale preferredLanguages] firstObject];
//    if([languageStr hasPrefix:@"en"]){
//        return SystemLanguageTypeEnglish;
//    }else if([languageStr hasPrefix:@"zh-Hans"]){
//        return SystemLanguageTypeChinese;
//    }else{
//        return SystemLanguageTypeOther;
//    }
}
    
@end
