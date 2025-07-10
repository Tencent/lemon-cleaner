//
//  QMCoreFunctionDef.h
//  Pods
//
//

#ifndef QMCoreFunctionDef_h
#define QMCoreFunctionDef_h

#ifdef APPSTORE_VERSION
#define kTXCProductId @"36664" // Lite和官网使用同一个，原Lite为52728
#else
#define kTXCProductId @"36664"
#endif

#define QMFeedbackURL ({ \
    NSString *URLStr = nil; \
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) { \
        URLStr = @"https://www.facebook.com/groups/2270176446528228/"; \
    } else { \
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary]; \
        NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"]; \
        NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];\
        NSString *os_Version = [NSString stringWithFormat:@"%ld.%ld.%ld",osVersion.majorVersion,osVersion.minorVersion,osVersion.patchVersion];\
        URLStr = [NSString stringWithFormat:@"https://support.qq.com/products/%@?clientVersion=%@&os=macOS&osVersion=%@",kTXCProductId,app_Version,os_Version]; \
    } \
    URLStr; \
})

#endif /* QMCoreFunctionDef_h */
