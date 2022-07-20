//
//  LMVersionHelper.m
//  
//

//

#import "LMVersionHelper.h"
#import "LemonDaemonConst.h"

@implementation LMVersionHelper

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

@end
