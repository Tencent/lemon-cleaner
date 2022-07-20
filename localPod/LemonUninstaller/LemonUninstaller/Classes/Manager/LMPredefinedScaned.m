//
//  LMPredefinedScaned.m
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMPredefinedScaned.h"
#import "LMSearchPath.h"

#define PATH_TYPE_SUPPORT           @"support"
#define PATH_TYPE_CACHES            @"caches"
#define PATH_TYPE_PREFS             @"prefs"
#define PATH_TYPE_STATE             @"state"
#define PATH_TYPE_CRASH_REPORT      @"crash"
#define PATH_TYPE_LOG               @"log"
#define PATH_TYPE_SANDBOX           @"sandbox"
#define PATH_TYPE_OTHER             @"other"
#define PATH_TYPE_LAUNCHCTL         @"launchctl"
#define PATH_TYPE_SIGNAL            @"signal"
#define PATH_TYPE_KEXT              @"kext"
#define PATH_TYPE_LOGIN_ITEM        @"login_item"


@interface LMPredefinedScaned () {
    NSString *_curScanApp;
    NSDictionary *_curAppSettings;
    NSMutableDictionary *_appPathsSortedByType;
}

@end

@implementation LMPredefinedScaned

- (void)setScanApp:(NSString *)appName {
    _curScanApp = appName;
    _appPathsSortedByType = [self sortPathsFromSettings:_curAppSettings];
    if (_curAppSettings) {
        NSLog(@"setScanApp:%@ ", appName);
    }
}

- (NSArray *)scanSupports {
    return [self scanWithType:PATH_TYPE_SUPPORT];
}

- (NSArray *)scanCaches {
    return [self scanWithType:PATH_TYPE_CACHES];
}

- (NSArray *)scanPreferences {
    return [self scanWithType:PATH_TYPE_PREFS];
}

- (NSArray *)scanStates {
    return [self scanWithType:PATH_TYPE_STATE];
}

- (NSArray *)scanCrashReporters {
    return [self scanWithType:PATH_TYPE_CRASH_REPORT];
}

- (NSArray *)scanLogs {
    return [self scanWithType:PATH_TYPE_LOG];
}

- (NSArray *)scanSandboxs {
    return [self scanWithType:PATH_TYPE_SANDBOX];
}

- (NSArray *)scanLaunchDaemons {
    return [self scanWithType:PATH_TYPE_LAUNCHCTL];
}

- (NSArray *)scanSignal{
    // 需要判断是否存在

    NSMutableSet *returnSet = [NSMutableSet set];
    
    NSArray *array = _appPathsSortedByType[PATH_TYPE_SIGNAL];
    for(NSString* identifier in array){
        NSArray<NSRunningApplication *>  *selectedApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];
        
        if (selectedApps || selectedApps.count > 0) {
            [returnSet addObject:identifier];
        }
    }

    return [returnSet allObjects];
}


- (NSArray *)scanLoginItem{
    NSArray *loginItemArray = _appPathsSortedByType[PATH_TYPE_LOGIN_ITEM];
    
    // 用 osscript 扫描太慢,直接返回结果
    return loginItemArray;
}

-(NSArray *)scanKext{
    NSArray *loginItemArray = _appPathsSortedByType[PATH_TYPE_KEXT];
    // 直接返回结果
    return loginItemArray;

}

//扫描其它文件
- (NSArray *)scanOthers
{
    return [self scanWithType:PATH_TYPE_OTHER];
}

- (void)test {
    NSArray *supports= [self scanSupports];
    NSArray *prefs = [self scanPreferences];
    NSArray *states = [self scanStates];
    NSArray *carsh = [self scanCaches];
    NSArray *logs = [self scanLogs];
    NSArray *sandbox = [self scanSandboxs];
    NSArray *daemon = [self scanLaunchDaemons];
    NSArray *others = [self scanOthers];
    NSLog(@"%@",supports);
    NSLog(@"%@",prefs);
    NSLog(@"%@",states);
    NSLog(@"%@",carsh);
    NSLog(@"%@",logs);
    NSLog(@"%@",sandbox);
    NSLog(@"%@",daemon);
    NSLog(@"%@",others);
}
    
#pragma mark -
#pragma mark private
- (NSArray *)scanWithType:(NSString *)type {
    NSArray *array = _appPathsSortedByType[type];
//    NSMutableArray *paths = [NSMutableArray array]; //使用 NSSet 防止重复
    NSMutableSet *pathSet = [NSMutableSet set];
    for (NSString *settingPath in array) {
        NSArray *pathsArray = [self scanPathsFromSettingPath:settingPath Parent:@"/"];
        [pathSet addObjectsFromArray:pathsArray];
        //注意:setByAddingObjectsFromArray :Returns a new set formed by adding the objects in a given array to the receiving set.
    }
//    NSLog(@"%s,app:%@, type:%@, %@", __FUNCTION__,  _curScanApp, type, pathSet);
    if([type isEqual: PATH_TYPE_LAUNCHCTL]){
        NSString * result = [[array valueForKey:@"description"] componentsJoinedByString:@", "];
        NSLog(@"launchctl app is %@ ,array is %@", _curScanApp, result );
    }
//    return paths;
    return [pathSet allObjects];
}


// 根据settingPath匹配存在的路径
// 使用递归方法，逐级路径搜索。
// 原理  每次方法调用只匹配一级目录,然后通过递归匹配剩余的目录.
// 比如匹配 $parent/*a/*b/*c,首先找出$parent目录下符合*a规则的路径, 作为 newParent.
// 然后在进行递归调用,匹配  $newParent目录下符合 *b 的,同理继续递归匹配*c.
- (NSArray *)scanPathsFromSettingPath:(NSString *)settingPath Parent:(NSString *)parent{
    NSArray *pathComponents = [settingPath pathComponents];
    NSString *firstComponent = pathComponents[0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 判断是否一个模糊匹配的路径
    BOOL isRegexPath = [self isVarPath:firstComponent];
    
    if (!isRegexPath && [pathComponents count] == 1) {
        if ([fm fileExistsAtPath:[parent stringByAppendingPathComponent:firstComponent]]) {
            return [NSArray arrayWithObject:firstComponent];
        } else {
            return [NSArray array];
        }
    }
    
    NSArray *matchPaths = nil;
    if (isRegexPath){
        // 获取所有的子路径
        NSArray *subPaths =  [fm contentsOfDirectoryAtPath:parent error:nil];
        // 将模糊路径转成正则表达式进行匹配
        NSString *regexString = [self regexFromSettingPath:firstComponent];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
        matchPaths = [subPaths filteredArrayUsingPredicate:filter];
    } else  {
        matchPaths = [NSArray arrayWithObject:firstComponent];
    }
    
    // 子目录只有一级,不需要继续匹配剩余部分,直接反馈.
    if ([pathComponents count] == 1) {
        return matchPaths;
    }
    
    
    // 获取剩余部分的子目录, 用于剩下的匹配.
    NSString *remain= pathComponents[1];
    if ([pathComponents count] > 2) {
        for (int i = 2; i < [pathComponents count]; i++) {
            remain = [remain stringByAppendingPathComponent:pathComponents[i]];
        }
    }
    
    
    //   $parent/*a/bb 可以匹配  $parent/aaa/bb 也可以匹配 $parent/abc/bb,所以可能有多个结果
    
    NSMutableArray *possiblePaths = [NSMutableArray array];
    for (NSString* macthPath in matchPaths) {
        
        NSArray *possibleSubPaths = [self scanPathsFromSettingPath:remain Parent:[parent stringByAppendingPathComponent:macthPath]];

        
        for (NSString *subPath in possibleSubPaths) {
            NSString *path = [macthPath stringByAppendingPathComponent:subPath];
            [possiblePaths addObject: path];
        }
    }
    return possiblePaths;
}


// 判断是否一个模糊匹配的路径（不是一个确定的路径），即含有‘*’和#{xxx} 和$(xxx)
- (BOOL) isVarPath:(NSString *)path {
    if ([path containsString:@"#"] || [path containsString:@"*"] || [path containsString:@"$"]) {
        return YES;
    } else {
        return NO;
    }
}


// 将path转成一个正则表达式进行匹配。 path中含有‘*’和#{xxx}（变量）$(xxx)，分别转成\S*和\S+匹配
- (NSString *)regexFromSettingPath:(NSString *)path {
    NSError *error = NULL;
    
    NSRegularExpression *regexDot = [NSRegularExpression regularExpressionWithPattern:@"\\."
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];
    
    NSRegularExpression *regexStar = [NSRegularExpression regularExpressionWithPattern:@"\\*"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
    
    NSRegularExpression *regexVar = [NSRegularExpression regularExpressionWithPattern:@"#\\{.*\\}"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];
    
    NSRegularExpression *regexVar2 = [NSRegularExpression regularExpressionWithPattern:@"\\$\\(.*\\)"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];

    NSString *replaceDot = [regexDot stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, [path length]) withTemplate:@"\\\\."];
    NSString *replaceStar = [regexStar stringByReplacingMatchesInString:replaceDot options:0 range:NSMakeRange(0, [replaceDot length]) withTemplate:@"\\\\S*"];
    NSString *replaceVar = [regexVar stringByReplacingMatchesInString:replaceStar options:0 range:NSMakeRange(0, [replaceStar length]) withTemplate:@"\\\\S+"];
    NSString *replaceVar2 = [regexVar2 stringByReplacingMatchesInString:replaceVar options:0 range:NSMakeRange(0, [replaceVar length]) withTemplate:@"\\\\S+"];
    [replaceVar2 stringByAppendingString:@"$"];
    return replaceVar2;
}



#pragma mark -
// 将路径按PATH_TYPE分类
- (NSMutableDictionary* ) sortPathsFromSettings:(NSDictionary *)appSettings {
    NSMutableDictionary * pathsSorts = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        [NSMutableArray array], PATH_TYPE_SIGNAL,
                                        [NSMutableArray array], PATH_TYPE_KEXT,
                                        [NSMutableArray array], PATH_TYPE_LOGIN_ITEM,
                                        [NSMutableArray array], PATH_TYPE_SUPPORT,
                                        [NSMutableArray array], PATH_TYPE_CACHES,
                                        [NSMutableArray array], PATH_TYPE_PREFS,
                                        [NSMutableArray array], PATH_TYPE_STATE,
                                        [NSMutableArray array], PATH_TYPE_CRASH_REPORT,
                                        [NSMutableArray array], PATH_TYPE_LOG,
                                        [NSMutableArray array], PATH_TYPE_SANDBOX,
                                        [NSMutableArray array], PATH_TYPE_OTHER,
                                        [NSMutableArray array], PATH_TYPE_LAUNCHCTL,
                                        nil];
    
    // json 中设置的路径可能有通配符.
    NSArray *pathsInSettings = [self getPathsFromSettings:appSettings];
    
    NSArray *supportSearchPaths = [LMSearchPath supportPaths];
    NSArray *cachesPaths = [LMSearchPath cachesPaths];
    NSArray *prefsPaths = [LMSearchPath preferencesPaths];
    NSArray *statePaths = [LMSearchPath statePaths];
    NSArray *crashPaths = [LMSearchPath crashReportPaths];
    NSArray *logPaths = [LMSearchPath logPaths];
    NSArray *sandboxPaths = [LMSearchPath sandboxsPaths];
    NSArray *launchctlPaths = [LMSearchPath daemonPaths];
    
    for (NSString *path in pathsInSettings) {
        NSString *pathExpand = [path stringByExpandingTildeInPath];
        if ([self isPath:pathExpand inArray:supportSearchPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_SUPPORT];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:cachesPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_CACHES];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:prefsPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_PREFS];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:statePaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_STATE];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:crashPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_CRASH_REPORT];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:logPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_LOG];
            [array addObject:pathExpand];
        } else if ([self isPath:pathExpand inArray:sandboxPaths]) {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_SANDBOX];
            [array addObject:pathExpand];
        } else {
            NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_OTHER];
            [array addObject:pathExpand];
        }
    }
    
    //launchctl
    NSArray *launchctls = [self getLaunchctlsFromSettings:appSettings];
    NSMutableArray *launchctlFilePaths = [NSMutableArray array];
    for (NSString *path in launchctlPaths){
        NSString *pathExpand = [path stringByExpandingTildeInPath];
        for (NSString *launchctlFile in launchctls) {
            
            NSString *filePaths = [pathExpand stringByAppendingPathComponent:launchctlFile];
            if (![filePaths hasSuffix:@".plist"]) {
                filePaths = [filePaths stringByAppendingString:@".plist"];
            }
            [launchctlFilePaths addObject:filePaths];
        }
    }
    NSMutableArray *array = [pathsSorts objectForKey:PATH_TYPE_LAUNCHCTL];
    [array addObjectsFromArray:launchctlFilePaths];
    
    
    // signal
    NSArray *signals = [self getSignalFromSettings:appSettings];
    NSMutableArray *signalsAppNames = [pathsSorts objectForKey:PATH_TYPE_SIGNAL];
    [signalsAppNames addObjectsFromArray:signals];

    // kext
    NSArray *kexts = [self getKextFromSettings:appSettings];
    NSMutableArray *kextsNames = [pathsSorts objectForKey:PATH_TYPE_KEXT];
    [kextsNames addObjectsFromArray:kexts];
    
    // login_item
    NSArray *login_items = [self getLoginItemFromSettings:appSettings];
    NSMutableArray *loginItemNames = [pathsSorts objectForKey:PATH_TYPE_LOGIN_ITEM];
    [loginItemNames addObjectsFromArray:login_items];
    
    return pathsSorts;
}

- (BOOL) isPath:(NSString *)path inArray:(NSArray *)array {
    path = [path lowercaseString];
    for (NSString *pathInArray in array) {
        if ([path hasPrefix:[pathInArray lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)getPathsFromSettings:(NSDictionary *)settings {
    NSMutableArray *pathsInSettings = [NSMutableArray array];
    //经分析，每个应用主要包含两个标签zap和uninstall
    // uninstall标签下包括 (['quit', 'pkgutil', 'signal', 'kext', 'login_item', 'rmdir', 'launchctl', 'zap', 'delete'])
    // zap标签下包括 (['pkgutil', 'kext', 'rmdir', 'launchctl', 'trash', 'delete'])
    // 其中对删除有意义的子标签是：rmdir, delete, trash， zap（有极少数app中，uninstall下包含zap子标签）。
    // daemon和agent在launchctl中。
    
    NSDictionary *zap = settings[@"zap"];
    if (zap) {
        NSArray *trash = zap[@"trash"];
        [self addStringOrArray:trash ToArray:pathsInSettings];
        
        NSArray *rmdir = zap[@"rmdir"];
        [self addStringOrArray:rmdir ToArray:pathsInSettings];

        NSArray *delete = zap[@"delete"];
        [self addStringOrArray:delete ToArray:pathsInSettings];
    }
    
    NSDictionary *uninstall = settings[@"uninstall"];
    if (uninstall) {
        NSArray *trash = zap[@"trash"];
        [self addStringOrArray:trash ToArray:pathsInSettings];
        
        NSArray *rmdir = zap[@"rmdir"];
        [self addStringOrArray:rmdir ToArray:pathsInSettings];
        
        NSArray *delete = zap[@"delete"];
        [self addStringOrArray:delete ToArray:pathsInSettings];
    }
    return pathsInSettings;
}
            
- (NSArray *)getLaunchctlsFromSettings:(NSDictionary *)settings {
    
    NSMutableArray *launchctlArray = [NSMutableArray array];
    
    NSDictionary *zap = settings[@"zap"];
    if (zap) {
        id launchctl = zap[@"launchctl"];
        if (launchctl) {
            [self addStringOrArray:launchctl ToArray:launchctlArray];
        }
    }
    
    NSDictionary *uninstall = settings[@"uninstall"];
    if (uninstall) {
        id launchctl = uninstall[@"launchctl"];
        [self addStringOrArray:launchctl ToArray:launchctlArray];
    }
    return launchctlArray;
}

- (NSArray *)getSignalFromSettings:(NSDictionary *)settings {
    
    NSMutableArray *killAppArr = [NSMutableArray array];

    NSArray *typeArray = @[@"zap", @"uninstall"];
    for (NSString* typeStr in typeArray){
        NSDictionary *tempConfigure = settings[typeStr];
        if (tempConfigure) {
            id signal = tempConfigure[@"signal"];
            if (signal && [signal isKindOfClass:NSArray.class]){
                NSArray *signalArr = signal;
                if(signalArr.count == 2){
                    NSString *killAppName = signalArr[1];
                    [killAppArr addObject:killAppName];
                }
            }
            
            id quit = tempConfigure[@"quit"];
            if (quit && [quit isKindOfClass:NSString.class]){
                [killAppArr addObject:(NSString*)quit];
            }
        }
    }
    
    return killAppArr;
}


- (NSArray *)getLoginItemFromSettings:(NSDictionary *)settings {
    NSMutableSet *loginItemSet = [[NSMutableSet alloc]init];
    
    NSArray *typeArray = @[@"zap", @"uninstall"];
    for (NSString* typeStr in typeArray){
        NSDictionary *tempConfigure = settings[typeStr];
        if (tempConfigure) {
            id login_item = tempConfigure[@"login_item"];
            if (login_item && [login_item isKindOfClass:NSString.class]){
                [loginItemSet addObject:(NSString*)login_item];
            }
        }
    }
    
    return [loginItemSet allObjects];
}


// kext : kernel extension
- (NSArray *)getKextFromSettings:(NSDictionary *)settings {
    NSMutableSet *KextSet = [[NSMutableSet alloc]init];
    
    NSArray *typeArray = @[@"zap", @"uninstall"];
    for (NSString* typeStr in typeArray){
        NSDictionary *tempConfigure = settings[typeStr];
        if (tempConfigure) {
            id kext = tempConfigure[@"kext"];
            if (kext && [kext isKindOfClass:NSString.class]){
                [KextSet addObject:(NSString*)kext];
            }
        }
    }
    
    return [KextSet allObjects];
}

- (void)addStringOrArray:(id) object ToArray:(NSMutableArray *)array {
    if (!object) return;
    if ([object isKindOfClass:[NSString class]]) {
        [array addObject:object];
    } else {
        [array addObjectsFromArray:object];
    }
}

-(NSString *)replaceRegexVersionMajor:(NSString*)replaceStr versionString:(NSString *)versionStr{
    NSRegularExpression *regexVar = [NSRegularExpression regularExpressionWithPattern:@"#\\{version.major\\}"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                    error:nil];
    if(replaceStr || versionStr || [replaceStr rangeOfString:@"version.major"].location == NSNotFound){
        return replaceStr;
    }
    
    NSArray *versionArr = [versionStr componentsSeparatedByString:@"."];
    NSString *versionMajor = versionArr[0];

    NSString *replaceStrAfter = [regexVar stringByReplacingMatchesInString:replaceStr options:0 range:NSMakeRange(0, [replaceStr length]) withTemplate:versionMajor];
    
    return replaceStrAfter;
}
@end
