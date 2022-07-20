//
//  McSoftwareFileScanner.m
//  QMUnintallDemo
//
//  
//  Copyright (c) 2013年 haotan. All rights reserved.
//

#import "McSoftwareFileScanner.h"
#import "NSString+Extension.h"
#import "NSFileManager+Extension.h"

@implementation McUninstallItemTypeGroup
- (NSControlStateValue) selectedState {
    NSInteger selectedCount = [self selectedCount];
  
    if (selectedCount == 0){
        return NSOffState;
    }
    
    if (selectedCount == self.items.count) {
        return NSOnState;
    }
    
    return NSMixedState;
}

- (NSInteger) selectedCount {
    NSInteger selectedCount = 0;
    for (McSoftwareFileItem *item in self.items) {
        if (item.isSelected){
            selectedCount++;
        }
    }
    return selectedCount;
}
- (NSInteger) selectedSize {
    NSInteger size = 0;
    for (McSoftwareFileItem *item in self.items) {
        if (item.isSelected) {
            size += item.fileSize;
        }
    }
    return size;
}
@end

@implementation McSoftwareFileItem
@synthesize filePath;
@synthesize name;
@synthesize icon;
@synthesize fileSize;
@synthesize type;

+ (McSoftwareFileItem *)itemWithPath:(NSString *)filePath
{
    McSoftwareFileItem *item = [[McSoftwareFileItem alloc] init];
    item.filePath = filePath;
    item.name = [filePath lastPathComponent];
    item.icon = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
    item.fileSize = [[NSFileManager defaultManager] diskSizeAtPath:filePath];
    item.isSelected = YES;
    return item;
}

+ (NSString *)typeName:(McSoftwareFileType)type
{
    switch (type)
    {
        case McSoftwareFileBundle:
            return @"可执行文件";
        case McSoftwareFileCache:
            return @"缓存文件";
        case McSoftwareFileDaemon:
            return @"启动项";
        case McSoftwareFileLog:
            return @"日志文件";
        case McSoftwareFilePreference:
            return @"设置文件";
        case McSoftwareFileReporter:
            return @"崩溃日志";
        case McSoftwareFileSandbox:
            return @"沙盒文件";
        case McSoftwareFileState:
            return @"保存状态";
        case McSoftwareFileSupport:
            return @"支持文件";
        default:
            return @"其它文件";
    }
}

@end

#pragma mark -
#pragma mark McSoftwareFileScanner

@interface McSoftwareFileScanner ()
{
    NSMutableDictionary *pathInfo;
}
@end

@implementation McSoftwareFileScanner
@synthesize soft;
@synthesize items;
@synthesize pathInfo;

+ (id)scannerWithSoft:(McLocalSoft *)soft
{
    if (!soft)
    {
        return nil;
    }
    McSoftwareFileScanner *scanner = [[McSoftwareFileScanner alloc] init];
    scanner.soft = soft;
    return scanner;
}

+ (id)scannerWithPath:(NSString *)filePath
{
    McLocalSoft *soft = [McLocalSoft softWithPath:filePath];
    if (!soft)
    {
        return nil;
    }
    return [self scannerWithSoft:soft];
}

//开始扫描软件的相联文件路径,按不同的类型成为路径的字典pathInfo(此过程耗时长,不要放主线程)
- (void)start
{
    pathInfo = [[NSMutableDictionary alloc] init];
    [pathInfo setObject:[NSMutableArray arrayWithObject:soft.bundlePath]
                 forKey:@(McSoftwareFileBundle)];
    
    [self searchSupports];
    [self searchCaches];
    [self searchPreferences];
    [self searchStates];
    [self searchCrashReporters];
    [self searchLogs];
    [self searchSandboxs];
    [self searchLauchDaemons];
//    [self searchOthers];
    [self searchSpecial];
    [self searchPlugin];
    
    //去除重复或包含的路径(采用倒序的原因是如果出面重复尽量保留前面扫描的路径)
    for (McSoftwareFileType type = McSoftwareFileOther;type>=McSoftwareFileBundle;type--)
    {
        id key = @(type);
        NSArray *searchArray = [pathInfo objectForKey:key];
        NSMutableArray *resultArray = [NSMutableArray array];
        [pathInfo setObject:resultArray forKey:key];
        
        for (NSString *itemPath in searchArray)
        {
            BOOL exists = NO;
            for (NSMutableArray *eachArray in [pathInfo allValues])
            {
                if (filepathExistsArray(itemPath, eachArray))
                {
                    exists = YES;
                    break;
                }
            }
            if (!exists)
            {
                [resultArray addObject:itemPath];
            }
        }
    }
    
    //如果去重时删除了主Bunlde
    NSMutableArray *bundles = [pathInfo objectForKey:@(McSoftwareFileBundle)];
    if ([bundles count] == 0)
    {
        [bundles addObject:soft.bundlePath];
    }
}

//返回软件的子文件对象列表(创建文件对象需要耗时,不要放主线程中)
- (NSArray *)items
{
    if (!items)
    {
        items = [[NSMutableArray alloc] init];
        for (McSoftwareFileType type = McSoftwareFileBundle;type<=McSoftwareFileOther;type++)
        {
            NSArray *pathArray = [pathInfo objectForKey:@(type)];
            if ([pathArray count] == 0) {
                continue;
            }
            McUninstallItemTypeGroup * group = [[McUninstallItemTypeGroup alloc] init];
            NSMutableArray *groupItems = [[NSMutableArray alloc] init];
            group.fileType = type;
            for (NSString *filePath in pathArray)
            {
                McSoftwareFileItem *item = [McSoftwareFileItem itemWithPath:filePath];
                item.type = type;
                [(NSMutableArray*)groupItems addObject:item];
            }
            group.items = groupItems;
            [(NSMutableArray*)items addObject:group];
        }
        
    }
    return items;
}

enum
{
    kMcSearchByName = 1,
    kMcSearchByBundleID = 1<<1,
    kMcSearchByCompany = 1<<2,
};

//扫描应用程序支持文件
- (void)searchSupports
{
    NSArray *searchPaths = @[@"/Library/Application Support",
                             [@"~/Library/Application Support" stringByExpandingTildeInPath]
                             ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID|kMcSearchByCompany suffixRegex:nil];
    [pathInfo setObject:result forKey:@(McSoftwareFileSupport)];
}

//扫描缓存文件
- (void)searchCaches
{
    NSString *tempPathT = NSTemporaryDirectory();
    NSString *tempPathC = [[tempPathT stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"C"];
    NSArray *searchPaths = @[@"/Library/Caches",
                             [@"~/Library/Caches" stringByExpandingTildeInPath],
                             tempPathT,tempPathC];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID|kMcSearchByCompany suffixRegex:nil];
    [pathInfo setObject:result forKey:@(McSoftwareFileCache)];
}

//扫描设置文件
- (void)searchPreferences
{
    NSArray *searchPaths = @[@"/Library/Preferences",
                             [@"~/Library/Preferences" stringByExpandingTildeInPath]
                             ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:nil];
    [pathInfo setObject:result forKey:@(McSoftwareFilePreference)];
}

//扫描保存的状态
- (void)searchStates
{
    NSArray *searchPaths = @[
                             [@"~/Library/Saved Application State" stringByExpandingTildeInPath]
                             ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:nil];
    [pathInfo setObject:result forKey:@(McSoftwareFileState)];
}

//扫描系统崩溃日志
- (void)searchCrashReporters
{
    NSArray *searchPaths = @[@"/Library/Application Support/CrashReporter",
                             @"/Library/Logs/DiagnosticReports",
                             [@"~/Library/Application Support/CrashReporter" stringByExpandingTildeInPath],
                             [@"~/Library/Logs/DiagnosticReports" stringByExpandingTildeInPath]
                             ];
    /*
     ([0-9a-fA-F-]{5,})匹配FF6CC5AF-BAB1-5F5B
     ([0-9]{4}(-[0-9]{1,2}){2})匹配日期
     */
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID|kMcSearchByCompany suffixRegex:@"_(([0-9a-fA-F-]{5,})|([0-9]{4}(-[0-9]{1,2}){2})).*"];
    [pathInfo setObject:result forKey:@(McSoftwareFileReporter)];
}

//扫描日志文件
- (void)searchLogs
{
    NSArray *searchPaths = @[@"/Library/Logs",
                             [@"~/Library/Logs" stringByExpandingTildeInPath]
                             ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID|kMcSearchByCompany suffixRegex:nil];
    [pathInfo setObject:result forKey:@(McSoftwareFileLog)];
}

//扫描沙盒文件
- (void)searchSandboxs
{
    NSArray *searchPaths = @[
                             [@"~/Library/Containers" stringByExpandingTildeInPath]
                             ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:nil];
    
    [result addObjectsFromArray:[self containerFromPlist]];
    [pathInfo setObject:result forKey:@(McSoftwareFileSandbox)];
}

// 通过分析plist过虑用户的沙盒文件。
// 匹配规则：plist的SandboxProfileDataValidationInfo/SandboxProfileDataValidationParametersKey/application_dyld_paths或
// SandboxProfileDataValidationInfo/SandboxProfileDataValidationParametersKey/application_bundle 是以bundlePath开头的
- (NSMutableArray *)containerFromPlist {
    NSMutableArray *result =  [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *containerPath = [@"~/Library/Containers" stringByExpandingTildeInPath];
    NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:containerPath error:NULL];
    for (NSString *subPath in subPaths) {
        NSString* plistPath = [subPath stringByAppendingPathComponent:@"Container.plist"];
        plistPath = [containerPath stringByAppendingPathComponent:plistPath];
        NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        NSDictionary *info = [plistDict objectForKey:@"SandboxProfileDataValidationInfo"];
        NSDictionary *params = [info objectForKey:@"SandboxProfileDataValidationParametersKey"];
        NSString *dyldPath = [params objectForKey:@"application_dyld_paths"];
        NSString *bundlePath = [params objectForKey:@"application_bundle"];
        NSRange range = [dyldPath rangeOfString:soft.bundlePath];
        NSRange rangeBundle = [bundlePath rangeOfString:soft.bundlePath];
        
        // 如果是自己，忽略。因为上文已经通过匹配目录名匹配到。
        if ([bundlePath isEqualToString:soft.bundlePath]){
            continue;
        }
        
        if ((range.location == 0 && range.length > 0) || (rangeBundle.location == 0 && range.length > 0)) {
            [result addObject:[plistPath stringByDeletingLastPathComponent]];
            //            NSLog(@"more %@, path:%@", soft.appName, [plistPath stringByDeletingLastPathComponent]);
        }
    }
    return result;
}

//扫描登录项
- (void)searchLauchDaemons
{
    NSArray *searchPaths = @[@"/Library/LaunchAgents",
                             @"/Library/LaunchDaemons",
                             @"/Library/StartupItems",
                             [@"~/Library/LaunchAgents" stringByExpandingTildeInPath],
                             [@"~/Library/LaunchDaemons" stringByExpandingTildeInPath]];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //找到绝对匹配
    NSArray *searchResult = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:@"\\.plist"];
    [result addObjectsFromArray:searchResult];
    
    //找到模糊匹配,然后根据里面的内容做二次判断
    searchResult = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:@".{1,}\\.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *resultPath in searchResult)
    {
        //找到守护进程的Plist文件，然后再根据该文件找到可执行文件
        NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:resultPath];
        id programInfo = [plistDict objectForKey:@"Program"];
        if (!programInfo)
        {
            programInfo = [plistDict objectForKey:@"ProgramArguments"];
            if (!programInfo)
            {
                continue;
            }
        }
        
        //找到所有出现的路径
        NSMutableArray *exeArray = [[NSMutableArray alloc] init];
        if ([programInfo isKindOfClass:[NSArray class]])
        {
            for (NSString *program in programInfo)
            {
                if ([program isKindOfClass:[NSString class]] &&
                    [fileManager fileExistsAtPath:program])
                {
                    [exeArray addObject:program];
                }
            }
        }
        else if ([programInfo isKindOfClass:[NSString class]])
        {
            if ([fileManager fileExistsAtPath:programInfo])
            {
                [exeArray addObject:programInfo];
            }
        }
        
        //判定路径是否与所有扫描到的路径关联
        for (NSString *exePath in exeArray)
        {
            BOOL find = NO;
            for (id typeKey in pathInfo)
            {
                NSArray *typeArray = [pathInfo objectForKey:typeKey];
                for (NSString *targetItem in typeArray)
                {
                    if ([targetItem isEqualToString:exePath] ||
                        [targetItem isParentPath:exePath])
                    {
                        [result addObject:resultPath];
                        find = YES;
                        break;
                    }
                }
                if (find) break;
            }
            if (find) break;
        }
    }
    
    [pathInfo setObject:result forKey:@(McSoftwareFileDaemon)];
}

//扫描其它文件
- (void)searchOthers
{
    NSArray *searchPaths = @[@"/Library",
                             [@"~/Library" stringByExpandingTildeInPath]
                             ];
    NSArray *array1 = [self searchFiles:searchPaths options:kMcSearchByCompany suffixRegex:nil];
    
    searchPaths = @[[@"~/Pictures/" stringByExpandingTildeInPath],
                    [@"~/Movies" stringByExpandingTildeInPath],
                    [@"~/Music" stringByExpandingTildeInPath],
                    [@"~/Downloads" stringByExpandingTildeInPath],
                    [@"~/Documents" stringByExpandingTildeInPath],
                    [@"~/Desktop" stringByExpandingTildeInPath]];
    NSArray *array2 = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID suffixRegex:nil];
    
    NSMutableArray *resultArray = [[NSMutableArray alloc] initWithCapacity:array1.count+array2.count];
    [resultArray addObjectsFromArray:array1];
    [resultArray addObjectsFromArray:array2];
    [pathInfo setObject:resultArray forKey:@(McSoftwareFileOther)];
}

/*
 paths:检索的目录
 options:检索方式的掩码
 suffixRegex:结尾处的正则
 所有匹配对大小写,空白均不敏感
 */
- (NSMutableArray *)searchFiles:(NSArray *)paths options:(int)options suffixRegex:(NSString *)suffixRegex
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *matchName = [[soft.appName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSString *matchName2 = [[soft.executableName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSString *matchBundle = [[soft.bundleID stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    
    //匹配软件名称的正则表达式
    NSString *nameRegex = nil;
    if (!matchName2 || [matchName isEqualToString:matchName2])
    {
        //(\\..*){0,}表示匹配XXX或XXX.*两种形式
        nameRegex = [NSString stringWithFormat:@"\\b(%@)%@(\\..*){0,}\\b",regexEscape(matchName),suffixRegex?suffixRegex:@""];
    }
    else
    {
        nameRegex = [NSString stringWithFormat:@"\\b((%@)|(%@))%@(\\..*){0,}\\b",regexEscape(matchName),regexEscape(matchName2),suffixRegex?suffixRegex:@""];
    }
    NSPredicate *namePred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
    
    //匹配bundleID的正则表达式
    NSString *bundleIDRegex = [NSString stringWithFormat:@"\\b(%@)%@(\\..*){0,}\\b",regexEscape(matchBundle),suffixRegex?suffixRegex:@""];
    NSPredicate *bundleIDPred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", bundleIDRegex];
    
    //对BundleID有三段的获取到公司名称
    NSString *companyName = nil;
    NSArray *bundleComponents = [soft.bundleID componentsSeparatedByString:@"."];
    if (bundleComponents.count == 3)
    {
        companyName = [bundleComponents objectAtIndex:1];
        companyName = [[companyName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    }
    
    for (NSString *namePath in paths)
    {
        NSArray *subNames = [fileManager contentsOfDirectoryAtPath:namePath error:NULL];
        for (NSString *subName in subNames)
        {
            NSString *subPath = [namePath stringByAppendingPathComponent:subName];
            NSString *matchSubName = [[subName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
            
            //匹配与名字相符的文件(尝试匹配两种文件名)
            if ((options&kMcSearchByName) && [namePred evaluateWithObject:matchSubName])
            {
                [resultArray addObject:subPath];
                continue;
            }
            
            //匹配与BunldeID相符的文件(尝试匹配是否去除后缀)
            if ((options&kMcSearchByBundleID) && [bundleIDPred evaluateWithObject:matchSubName])
            {
                [resultArray addObject:subPath];
                continue;
            }
            
            //匹配公司名目录下面与产品名字或BunldeID相同的文件
            if ((options&kMcSearchByCompany) && companyName && [matchSubName isEqualToString:companyName])
            {
                NSArray *thirdSubs = [fileManager contentsOfDirectoryAtPath:subPath error:NULL];
                for (NSString *thirdItem in thirdSubs)
                {
                    NSString *matchThirdName = [[thirdItem stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
                    if ([namePred evaluateWithObject:matchThirdName] ||
                        [bundleIDPred evaluateWithObject:matchThirdName]
                        )
                    {
                        NSString *thirdPath = [subPath stringByAppendingPathComponent:thirdItem];
                        [resultArray addObject:thirdPath];
                        continue;
                    }
                }
            }
        }
    }
    
    return resultArray;
}

//特殊搜索(还不知道名字的项目)
- (void)searchSpecial
{
    NSDictionary *pluginRelativeInfo = @{@"com.google.Chrome":
                                             @{@(McSoftwareFileUnname):@[@"~/Library/Google/GoogleSoftwareUpdate",@"~/Library/Google/Google Chrome Brand.plist"]},
                                         @"com.qihoo.mac360safe":
                                             @{@(McSoftwareFileDaemon): @[@"/Library/LaunchDaemons/com.qihoo.360safe.daemon.plist"]}
                                         };
    
    NSDictionary *specialInfo = [pluginRelativeInfo objectForKey:soft.bundleID];
    for (id type in specialInfo)
    {
        NSArray *specialItems = [specialInfo objectForKey:type];
        if (!specialItems || specialItems.count == 0)
            continue;
        
        //找到对应的容器
        NSMutableArray *typeArray = [pathInfo objectForKey:type];
        if (!typeArray)
        {
            typeArray = [[NSMutableArray alloc] init];
            [pathInfo setObject:typeArray forKey:type];
        }
        
        //加入有效的路径
        for (NSString *onePath in specialItems)
        {
            NSString *realPath = [onePath stringByExpandingTildeInPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:realPath])
                [typeArray addObject:realPath];
        }
    }
}

//检索插件(精确)
- (void)searchPlugin
{
    NSDictionary *pluginRelativeInfo = @{@"com.qvod.QvodPlayer":
                                             @[@"com.qvod.qvodplayerplugin",@"com.qvod.qvodbrowserplugin"],
                                         @"com.google.Chrome":
                                             @[@"com.google.Keystone",@"com.google.Keystone.Agent"],
                                         @"com.magican.castle":
                                             @[@"com.magican.castle.monitor"]
                                         };
    NSArray *pluginBundleIDs = [pluginRelativeInfo objectForKey:soft.bundleID];
    for (NSString *relativeBundleID in pluginBundleIDs)
    {
        NSString *pluginPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:relativeBundleID];
        if (!pluginPath)
        {
            continue;
        }
        McSoftwareFileScanner *pluginUninstaller = [McSoftwareFileScanner scannerWithPath:pluginPath];
        [pluginUninstaller start];
        for (id key in pluginUninstaller.pathInfo)
        {
            NSMutableArray *mainTypeArray = [pathInfo objectForKey:key];
            NSMutableArray *pluginTypeArray = [pluginUninstaller.pathInfo objectForKey:key];
            if (!mainTypeArray)
            {
                [pathInfo setObject:pluginTypeArray forKey:key];
            }else
            {
                [mainTypeArray addObjectsFromArray:pluginTypeArray];
            }
        }
        
    }
}

#pragma mark -

//判断是否已经存在该目录(包括逻辑上层次包含)
static BOOL filepathExistsArray(NSString *filePath,NSMutableArray *items)
{
    //直接判断是否有路径相同
    if ([items containsObject:filePath])
    {
        return YES;
    }
    
    //然后判断路径是否有层次关系(倒序遍历，因为可能会中途删除元素)
    for (int idx = (int)[items count]-1; idx >= 0 ; idx--)
    {
        NSString *currentPath = [items objectAtIndex:idx];
        
        //如果filePath是已经存在路径的子路径
        if ([currentPath isParentPath:filePath])
        {
            return YES;
        }
        
        //如果filePath是某文件的父路径，刚删除该文件，保留filePath
        if ([filePath isParentPath:currentPath])
        {
            [items removeObjectAtIndex:idx];
        }
    }
    return NO;
}

//转义正则表达中的特殊字符
NS_INLINE NSString *regexEscape(NSString *string)
{
    if (string.length == 0)
    {
        return string;
    }
    
    NSMutableString *result = [string mutableCopy];
    NSArray *escapes = @[@"\\",@"/",@"|",@"{",@"}",@"(",@")",@"[",@"]",@"*",@".",@"?",@"+",@"^",@"$"];
    for (NSString *aChar in escapes)
    {
        NSString *escapeChar = [@"\\" stringByAppendingString:aChar];
        [result replaceOccurrencesOfString:aChar withString:escapeChar options:0 range:NSMakeRange(0, [result length])];
    }
    
    return result;
}

@end
