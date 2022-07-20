//
//  QMCacheEnumerator.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMCacheEnumerator.h"
#import "QMActionItem.h"
#import "QMFilterParse.h"
#import "QMXMLParseManager.h"
#import "InstallAppHelper.h"
#import "LMAppSandboxHelper.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "QMFilterItem.h"

@interface QMCacheEnumerator()

@property (nonatomic, strong) NSDictionary *installBundleDic;
@property (nonatomic, strong) NSMutableArray *libCacheArr;
@property (nonatomic, strong) NSMutableArray *containerCacheArr;
@property (nonatomic, strong) NSMutableArray *tempCacheArr;

@end

@implementation QMCacheEnumerator

-(instancetype)init{
    self = [super init];
    if (self) {
//        [self initialData];
        self.installBundleDic = [InstallAppHelper getInstallBundleIds];
    }
    return self;
}

+(QMCacheEnumerator *)shareInstance{
    static QMCacheEnumerator *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMCacheEnumerator alloc] init];
    });
    
    return instance;
}

//初始化 或者 重新初始化
-(void)initialData{
    //lib数据
    NSDictionary *fileterDic = [[QMXMLParseManager sharedManager] filterItemDict];
    QMFilterItem *libcacheItem = [fileterDic objectForKey:@"73"];
    NSString *libcacheString = libcacheItem.value;
    QMActionItem *actionItem = [self getCacheActionItemWithPath:@"~/Library/Caches" andScanFilters:libcacheString type:kXMLKeyAbs];//扫描缓存
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[[QMXMLParseManager sharedManager] filterItemDict]];//获取XML中需要过滤的应用
    self.libCacheArr = [[NSMutableArray alloc] initWithArray:[filterParse enumeratorAtFilePath:actionItem]];
    NSMutableArray *removeArr = [NSMutableArray new];
    for (NSString *path in self.libCacheArr) {
        if ([path isEqualToString:@"Images"]) {
            continue;
        }
        if ([path isEqualToString:@"Videos"]) {
            continue;
        }
        if ([path isEqualToString:@"File"]) {
            continue;
        }
        NSString *componet = [path lastPathComponent];
        if (![componet containsString:@"."]) {
            [removeArr addObject:path];
        }
        if ([componet containsString:@"Extension"]) {
            [removeArr addObject:path];
        }
    }
    if ([removeArr count] != 0) {
        [self.libCacheArr removeObjectsInArray:removeArr];
    }
    
    //container数据
    QMFilterItem *libContainItem = [fileterDic objectForKey:@"74"];
    NSString *libcontainString = libContainItem.value;
    actionItem = [self getCacheActionItemWithPath:@"~/Library/Containers/(.+)/Data/Library/Caches" andScanFilters:libcontainString type:kXMLKeyAbs];
    filterParse = [[QMFilterParse alloc] initFilterDict:fileterDic];
    self.containerCacheArr = [[NSMutableArray alloc] initWithArray:[filterParse enumeratorAtFilePath:actionItem]];
    removeArr = [NSMutableArray new];
    for (NSString *path in self.containerCacheArr) {
        if ([path isEqualToString:@"Images"]) {
            continue;
        }
        if ([path isEqualToString:@"Videos"]) {
            continue;
        }
        if ([path isEqualToString:@"File"]) {
            continue;
        }
        NSString *componet = [path lastPathComponent];
        if (![componet containsString:@"."]) {
            [removeArr addObject:path];
        }
        if ([componet containsString:@"Extension"]) {
            [removeArr addObject:path];
        }
    }
    if ([removeArr count] != 0) {
        [self.containerCacheArr removeObjectsInArray:removeArr];
    }
    
    if (![McCoreFunction isAppStoreVersion]) {
        //temp数据
        QMFilterItem *libsystemItem = [fileterDic objectForKey:@"75"];
        NSString *libsystemString = libsystemItem.value;
        actionItem = [self getCacheActionItemWithPath:@"SystemTempDir" andScanFilters:libsystemString type:kXMLKeySpecial];
        filterParse = [[QMFilterParse alloc] initFilterDict:fileterDic];
        self.tempCacheArr = [[NSMutableArray alloc] initWithArray:[filterParse enumeratorAtFilePath:actionItem]];
        removeArr = [NSMutableArray new];
        for (NSString *path in self.tempCacheArr) {
            NSString *componet = [path lastPathComponent];
            if (![componet containsString:@"."]) {
                [removeArr addObject:path];
            }
            if ([componet containsString:@"Extension"]) {
                [removeArr addObject:path];
            }
        }
        if ([removeArr count] != 0) {
            [self.tempCacheArr removeObjectsInArray:removeArr];
        }
    }
}

//通过actionitem 来获取缓存数据
-(NSArray *)getCacheWithActionItem:(QMActionItem *)actionItem{
    NSMutableArray *pathArray = [NSMutableArray new];
//    if (actionItem.sandboxType == SandboxTypeNotDetermine) {
//        actionItem.sandboxType = [[LMAppSandboxHelper shareInstance] getAppSandboxTypeInScanWithBundleId:actionItem.bundleID appPath:actionItem.appPath];
//    }
//
//    //首先拿沙盒或者非沙盒的Caches
//    if (actionItem.sandboxType == SandboxTypeNot) {
//        actionItem.appSearchName = [NSBundle bundleWithIdentifier:actionItem.bundleID].infoDictionary[(NSString *)kCFBundleNameKey];
//        NSArray *retArr = [self getLibraryCacheByBundleId:actionItem.bundleID andAppName:actionItem.appSearchName];
//        [pathArray addObjectsFromArray:retArr];
//    }else if (actionItem.sandboxType == SandboxTypeYes){
//        NSString *retPath = [self getContainerCacheByBundleId:actionItem.bundleID];
//        if (retPath != nil) {
//            [pathArray addObject:retPath];
//        }
//    }else{
//        BOOL isExistBundle = [self.installBundleDic objectForKey:actionItem.bundleID] != nil;
//        BOOL isExistAppStore = [self.installBundleDic objectForKey:actionItem.bundleID] != nil;
//        if (!isExistAppStore) {
//            isExistAppStore = [self.installBundleDic objectForKey:actionItem.appstoreBundleID] != nil;
//        }
//        if (isExistBundle) {
//            actionItem.appSearchName = [NSBundle bundleWithIdentifier:actionItem.bundleID].infoDictionary[(NSString *)kCFBundleNameKey];
//            NSArray *retArr = [self getLibraryCacheByBundleId:actionItem.bundleID andAppName:actionItem.appSearchName];
//            [pathArray addObjectsFromArray:retArr];
//        }
//        if (isExistAppStore) {
//            NSString *retPath = [self getContainerCacheByBundleId:actionItem.appstoreBundleID];
//            if (retPath != nil) {
//                [pathArray addObject:retPath];
//            }
//            retPath = [self getContainerCacheByBundleId:actionItem.bundleID];
//            if (retPath != nil) {
//                [pathArray addObject:retPath];
//            }
//        }
//    }
    actionItem.appSearchName = [NSBundle bundleWithIdentifier:actionItem.bundleID].infoDictionary[(NSString *)kCFBundleNameKey];
    NSArray *retArr = [self getLibraryCacheByBundleId:actionItem.bundleID andAppName:actionItem.appSearchName];
    [pathArray addObjectsFromArray:retArr];
    retArr = [self getLibraryCacheByBundleId:actionItem.appstoreBundleID andAppName:actionItem.appSearchName];
    [pathArray addObjectsFromArray:retArr];
    NSString *retPath = [self getContainerCacheByBundleId:actionItem.appstoreBundleID];
    if (retPath != nil) {
        [pathArray addObject:retPath];
    }
    retPath = [self getContainerCacheByBundleId:actionItem.bundleID];
    if (retPath != nil) {
        [pathArray addObject:retPath];
    }
    //拿到TEMP目录的cache
    retPath = [self getTempCacheByBundleId:actionItem.bundleID];
    if (retPath != nil) {
        [pathArray addObject:retPath];
    }
    
    return pathArray;
}

//获取所有剩余的cache
-(NSArray *)getLeftAppCache{
    NSMutableArray *pathArray = [NSMutableArray new];
    if (self.libCacheArr != nil) {
        [pathArray addObjectsFromArray:self.libCacheArr];
    }
    if (self.containerCacheArr != nil) {
        [pathArray addObjectsFromArray:self.containerCacheArr];
    }
//    if (self.tempCacheArr != nil) {
//        [pathArray addObjectsFromArray:self.tempCacheArr];
//    }
    NSLog(@"left patharray = %@", pathArray);
    return pathArray;
}

-(QMActionItem *)getCacheActionItemWithPath:(NSString *)path andScanFilters:(NSString *)filters type:(NSString *)type{
    QMActionItem *actionItem = [[QMActionItem alloc] init];
    actionItem.type = QMActionFileType;
    
    QMActionPathItem *pathItem = [[QMActionPathItem alloc] init];
    pathItem.value = path;
    pathItem.scanFilters = filters;
    pathItem.type = type;
    
    [actionItem addActionPathItem:pathItem];
    
    return actionItem;
}

//获取的Library cache 目录 下该软件缓存 -- 返回并删除之
-(NSArray *)getLibraryCacheByBundleId:(NSString *)bundleId andAppName:(NSString *)appName{
    if ((self.libCacheArr == nil) || ([self.libCacheArr count] == 0)) {
        return nil;
    }
    NSMutableArray *resultArr = [NSMutableArray new];
    @try{
        if (appName != nil) {
            //5 appname
            appName = [appName lowercaseString];
            if ((appName != nil) &&![self checkIsChinese:appName]) {
                appName = [appName stringByReplacingOccurrencesOfString:@"[^a-z]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [appName length])];
            }
        }
        for (NSString *path in self.libCacheArr) {
            NSString *lastPathComponent = [path lastPathComponent];//可能是bundleid 也有可能是软件名 1
            NSString *lastPathExtention = nil; //2
            //如果是bundleid形式 拿到尾缀
            if ([lastPathComponent containsString:@"."]) {
                NSArray *ponentArr = [lastPathComponent componentsSeparatedByString:@"."];
                for (NSString *ponent in ponentArr) {//选取包含appname的那个字段
                    if (appName == nil) {
                        break;
                    }
                    if ([[ponent lowercaseString] containsString:appName]) {
                        lastPathExtention = [ponent lowercaseString];
                    }
                }
                if (lastPathExtention == nil) {
                    lastPathExtention = [[lastPathComponent pathExtension] lowercaseString];
                }
                
                lastPathExtention = [lastPathExtention stringByReplacingOccurrencesOfString:@"[^a-z]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [lastPathExtention length])];//很多app添加了数字尾缀  需要去掉
                if (([lastPathExtention length] > 0)  &&[lastPathExtention isEqualToString:appName]) {
                    [resultArr addObject:path];
                    continue;
                }
            }else{
                lastPathExtention = [lastPathComponent pathExtension];
                lastPathExtention = [lastPathExtention lowercaseString];
                //appname与2对比  ----- 文件尾缀与appname进行对比
                if (([lastPathExtention length] > 0)  &&[lastPathExtention isEqualToString:appName]) {
                    [resultArr addObject:path];
                    continue;
                }
            }
            NSString *lastBundleExtention = [[bundleId pathExtension] lowercaseString]; //3
            if(![lastBundleExtention containsString:@"163music"]){   //163music 去掉数字后与系统的music一样，所以需要过滤
                lastBundleExtention = [lastBundleExtention stringByReplacingOccurrencesOfString:@"[^a-z]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [lastBundleExtention length])];
            }
            //4 bundleid
            
            //相互对比
            //1与3对比 ---- 用来判断bundleid是否对比成功
            if ([lastPathComponent isEqualToString:bundleId]) {
                [resultArr addObject:path];
                continue;
            }
            //2与4对比  ----- 文件尾缀与bundleid尾缀对比
            if (([lastPathExtention length] > 0)  &&[lastPathExtention isEqualToString:lastBundleExtention]) {
                [resultArr addObject:path];
                continue;
            }
            
        }
        
        if ([resultArr count] != 0) {
            [self.libCacheArr removeObjectsInArray:resultArr];
        }
    }
    @catch(NSException *exception){
        NSLog(@"getLibraryCacheByBundleId exception is = %@", exception);
    }
    
    
    return [resultArr count] == 0 ? nil : resultArr;
}

- (BOOL)isStringContainEnWith:(NSString *)str {
    NSRegularExpression *numberRegular = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSInteger count = [numberRegular numberOfMatchesInString:str options:NSMatchingReportProgress range:NSMakeRange(0, str.length)];
    //count是str中包含[A-Za-z]数字的个数，只要count>0，说明str中包含英文
    if (count > 0) {
        return YES;
    }
    return NO;
}

- (BOOL)checkIsChinese:(NSString *)string{
    if (string == nil) {
        return NO;
    }
    for (int i=0; i<string.length; i++) {
        unichar ch = [string characterAtIndex:i];
        if (0x4E00 <= ch  && ch <= 0x9FA5) {
            return YES;
        }
    }
    return NO;
}

//后面两项 应该是与bundle id 一一进行对应
//获取的Library container 目录 下该软件缓存 -- 返回并删除之
-(NSString *)getContainerCacheByBundleId:(NSString *)bundleId{
    if ((self.containerCacheArr == nil) || ([self.containerCacheArr count] == 0)) {
        return nil;
    }
    NSString *retPath = nil;
    for (NSString *path in self.containerCacheArr) {
        NSString *lastPathComponent = [path lastPathComponent];//可能是bundleid 也有可能是软件名 1
        if ([lastPathComponent isEqualToString:bundleId]) {
            retPath = path;
            break;
        }
    }
    
    if (retPath) {
        [self.containerCacheArr removeObject:retPath];
    }
    
    
    return retPath;
}

//获取所有的temp 目录 该软件缓存 -- 返回并删除之
-(NSString *)getTempCacheByBundleId:(NSString *)bundleId{
    if ((self.tempCacheArr == nil) || ([self.tempCacheArr count] == 0)) {
        return nil;
    }
    NSString *retPath = nil;
    for (NSString *path in self.tempCacheArr) {
        NSString *lastPathComponent = [path lastPathComponent];//可能是bundleid 也有可能是软件名 1
        if ([lastPathComponent isEqualToString:bundleId]) {
            retPath = path;
            break;
        }
    }
    
    if (retPath) {
        [self.tempCacheArr removeObject:retPath];
    }
    
    
    return retPath;
}

@end
