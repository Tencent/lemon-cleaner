//
//  LMDMVersionHelper.m
//  
//

//

#import "LMDMVersionHelper.h"
#import "LemonDaemonConst.h"

@implementation LMDMVersionHelper
+ (NSString *)mainVersionFromVersionLogFile{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *path = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *fullVersion = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return [fullVersion stringByDeletingLastPathComponent];
}

+ (NSString *)buildVersionFromVersionLogFile{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *path = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *fullVersion = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return [fullVersion lastPathComponent];
}

+ (NSString *)fullVersionFromVersionLogFile{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *path = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    NSString *fullVersion = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return fullVersion;
}

+ (void)writeVersionToVersionLogFileWithMainVersion:(NSString *)mainVersion andBuildVersion:(NSString *)buildVersion{
    NSString *supportPath = APP_SUPPORT_PATH;
    NSString *path = [supportPath stringByAppendingPathComponent:INST_VERSION_NAME];
    
    NSString *fullVersion = [mainVersion stringByAppendingPathComponent:buildVersion];
    [fullVersion writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


+ (NSString *)fullVersionFromBundle:(NSBundle *)bundle{
    NSString *curVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *fullVersion = [curVersion stringByAppendingPathComponent:buildVersion];
    return fullVersion;
}

+ (NSString *)mainVersionFromBundle:(NSBundle *)bundle{
    NSString *mainVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return mainVersion;
}

+ (NSString *)buildVersionFromBundle:(NSBundle *)bundle{
    NSString *buildVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    return buildVersion;
}

@end
