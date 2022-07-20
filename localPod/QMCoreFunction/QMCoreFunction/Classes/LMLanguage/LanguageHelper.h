//
//  LanguageHelper.h
//  AFNetworking
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SystemLanguageType) {
    SystemLanguageTypeEnglish,
    SystemLanguageTypeChinese,
    SystemLanguageTypeOther,
};

#define USER_DEFAULTS_LANGUAGE_KEY @"user_defaults_language_key"
#define LANGUAGE_KEY @"language"
#define LANGUAGE_CH @"zh-Hans"
#define LANGUAGE_EN @"en"

@interface LanguageHelper : NSObject

//设置多语言
+(void)setCurrentUserLanguage:(NSString *)userLanguage;

//获取多语言 --- 主应用
+(NSString *)getCurrentUserLanguage;

//获取多语言 --- 读取主工程的pref 主要是升级程序和托盘来使用
+(NSString *)getCurrentUserLanguageByReadFile;

+(SystemLanguageType)getCurrentSystemLanguageType;
    
@end
