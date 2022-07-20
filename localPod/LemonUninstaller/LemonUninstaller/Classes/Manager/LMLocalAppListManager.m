//
//  LMLocalSoftManager.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMLocalAppListManager.h"
#import "McApplicationScanner.h"
#import "McPluginScanner.h"
#import "McInputMethodScanner.h"
#import "QMSafeMutableArray.h"
#import "NSTimer+Extension.h"
#import <dlfcn.h>
#import <AppKit/AppKit.h>
#import <sys/stat.h>
#import "LMLocalApp.h"
#import "LMLocalApp.h"
#import <QMCoreFunction/LoginItemManager.h>
#import "PkgUninstallManager.h"


#define needReScanTimeThreshhold 1 * 24 * 60 * 60  //单位 s, 一天

@interface LMLocalAppListManager ()
{
    NSMutableArray<LMLocalApp *> *_appsList; // <<LMLocalApp *>根据bundleId合并后的结果
    NSRecursiveLock *_scanLock;  //防止多次重复扫描.(同时只存在一个扫描)
    NSArray *scanPaths;
    NSInteger _scanCount;
    NSTimeInterval fullScanTime;
    BOOL _isStopScaning;
}
@end

@implementation LMLocalAppListManager

+ (id)defaultManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _isStopScaning = FALSE;
        _scanLock = [[NSRecursiveLock alloc] init];
        scanPaths =  @[@"/Applications",
                    [@"~/Applications" stringByExpandingTildeInPath],
                    [@"~/Downloads" stringByExpandingTildeInPath],
                    [@"~/Desktop" stringByExpandingTildeInPath],
                    [@"~/Documents" stringByExpandingTildeInPath]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAppDelectProgress:)
                                                     name:LMNotificationDelectProgress
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onScanProgress:)
                                                     name:LMNotificationScanProgress
                                                   object:nil];
        
    }
    return self;
}

- (NSArray<LMLocalApp *> * )appsList{
    return _appsList;
}


- (void)setAppsList:(NSMutableArray * _Nonnull)appsList {
    _appsList = appsList;
}


- (void)scanAllAppsItemAsync:(LMSortType)sortType  byAscendingOrder:(BOOL)ascendingOrder {
    NSLog(@"%s ...", __FUNCTION__);
    _isStopScaning = FALSE;
    // 详细扫描.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self fullScan:sortType byAscendingOrder:ascendingOrder];
    });
}

- (void)fullScan:(LMSortType)sortType  byAscendingOrder:(BOOL)ascendingOrder{
    [_scanLock lock];
    self->fullScanTime = [[NSDate date] timeIntervalSince1970];
    // get apps(根据 path)
    NSArray<LMLocalApp *> * pathAppArray= [self enumLocalAppsWithPath] ;
    // merge same bundle id app
    self.appsList = [[self mergeAppsByBundleId:pathAppArray] mutableCopy];
    // sort appList
    [self appsListSortByType:sortType byAscendingOrder:ascendingOrder];
    self->_scanCount = 0;
    [self scanItems:self.appsList withType:LMScanTypeScanAll];
    [_scanLock unlock];
}

- (BOOL)isNeedFullScanBecauseOvertime{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if(now - self->fullScanTime > needReScanTimeThreshhold){
        return YES;
    }else{
        return NO;
    }
}


- (NSArray *)needScanItems {
    NSMutableArray *unscanList = [NSMutableArray array];
    NSArray<LMLocalApp *> *list = [self appsList];
    for (int i = 0; i < [list count]; i++) {
        if (!list[i].isScanComplete) {
            [unscanList addObject:list[i]];
        }
    }
    return unscanList;
}


// 增量扫描，只扫描新增的，还没有扫描过的item
- (void) scanIncreaseItems:(NSArray*)unscanList{
    NSLog(@"%s, list:%@", __FUNCTION__, unscanList);
    _scanCount = 0;
    NSInteger scanType = LMScanTypeScanIncrease;
    [self scanItems:unscanList withType:scanType];
}

- (void)scanItems:(NSArray<LMLocalApp *> *)itemList withType:(NSInteger)scanType  {
    
    
    // 初始化扫描(不管是增量扫描还是全量扫描.). 只拿到 app 路径.  // TODO app需要合并
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{
                                   LMNotificationKeyListChangedReason:[NSNumber numberWithInteger:LMChangedReasonScanInit],
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationListChanged
                                                            object:self
                                                          userInfo:userInfo];
    });
    
    
    // 预先扫描项
    // 预先扫描 LoginItem,防止每次App 扫描时都重新获取一次 LoginItem.
    NSArray<LMLoginItem *> *loginItems = [LoginItemManager getAllValidLoginItems];
    [PkgUninstallManager searchAllPkgList];
    
    NSInteger count = [itemList count];
    NSLog(@"%s, itemCount:%ld", __FUNCTION__, count);
    
    LMUninstallXMLParseManager *xmlParseManager = [LMUninstallXMLParseManager sharedManager];
    [xmlParseManager startParseXML];
    
    // dispatch_queue 设置最大同时执行数量, 防止同时起上百个线程阻塞主线程
#ifdef DebugAppUninstallScanBySerial
    dispatch_queue_t searchQueue = dispatch_queue_create("uninstall_queue_max_1", DISPATCH_QUEUE_SERIAL);
#else
    dispatch_queue_t searchQueue = dispatch_queue_create("uninstall_queue_max_5", DISPATCH_QUEUE_CONCURRENT);
#endif
    // 等待子线程完成.  dispatch_apply 会限制子线程数量(cpu 核心 *2)
    // dispatch_async 不会限制
    
    dispatch_apply(count, searchQueue, ^(size_t index) {
        @autoreleasepool{
            if(self->_isStopScaning){
                return ;
            }
            
            LMLocalApp *app = itemList[index];
            [app setAllSystemLoginItems:loginItems];
            
            [app scanFileItems:AppUninstall];
            if(![itemList[index] isScanComplete]){
                return ;
            }
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setObject:itemList[index] forKey:LMKeyScanProgressCurObject];
            [info setObject:[NSNumber numberWithLong:count] forKey:LMKeyScanProgressTotal];
            [info setObject:[NSNumber numberWithInteger:scanType] forKey:LMKeyScanType];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationScanProgress
                                                                    object:self
                                                                  userInfo:info];
            });
            
#ifdef DebugAppUninstallScanBySerial
            [NSThread sleepForTimeInterval:2];
#endif
        }
    });
    
    NSLog(@"%s .........end", __FUNCTION__);
}

-(BOOL)appPaths: (NSArray *)appPaths isContains: (NSString *)path{
    for(NSString *temp in appPaths){
        if([temp isEqualToString:path]){
            return YES;
        }
    }
    return NO;
}


- (NSArray<LMLocalApp *> *)enumLocalAppsWithPath{
    // test uninstall single app

//    #ifdef DEBUG
//    NSMutableArray<LMLocalApp *> *list = [NSMutableArray array];
//    NSString *appPath = @"/Applications/NTFS for Mac.app";
//    [list addObject:[[LMLocalApp alloc] initWithPath:appPath]];
//    return list;
//    #endif
    
//    NSLog(@"%s", __FUNCTION__);
    NSMutableArray<NSString *> *appPaths = nil;
//    long startTime = [[NSDate date]timeIntervalSince1970];
    NSArray<NSString *> *appPathFromSystem = [self getAppsFromSystem];
    NSArray<NSString *> *appPathByEnumDir = [self getAppsByEnumDir];
    appPaths = [appPathFromSystem mutableCopy];
    for(NSString *path in appPathByEnumDir){
        if(![self appPaths:appPathFromSystem isContains:path]){
            [appPaths addObject:path];
        }
    }
//    if (!appPaths) {
//        NSLog(@"get Apps from system fail, get by enum dir");
//        appPaths = [self getAppsByEnumDir];
//    }
    
//    long endTime = [[NSDate date]timeIntervalSince1970];
//    long runTime = endTime - startTime;
//    NSLog(@"%s,runTime:%ld",__FUNCTION__,runTime);
    NSLog(@"%s, count:%lu, path%@", __FUNCTION__,(unsigned long)[appPaths count], [[appPaths valueForKey:@"description"] componentsJoinedByString:@", "]);
    
    // path -> LMLocalApp
    NSMutableArray<LMLocalApp *> *localAppArray = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString * path in appPaths) {
        if ([fm fileExistsAtPath:path])
            [localAppArray addObject:[[LMLocalApp alloc] initWithPath:path]];
    }
    return [localAppArray copy];
}

- (NSArray<LMLocalApp *> *)mergeAppsByBundleId:(NSArray<LMLocalApp *> *)unMergeList{
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    NSMutableArray<LMLocalApp*> *ret = [NSMutableArray array];
    for (LMLocalApp *app in unMergeList) {
        // 有些app, 例如，用stream安装的Sniper 3D Assassin Shoot to Kill.app，里面只有一个脚本，指向Stream，
        // 而且没有bundleId，所以这里可能会造成崩溃。
        if (!app.bundleID) {
            [ret addObject:app];
            continue;
        }
        LMLocalApp *tempApp = [temp objectForKey:app.bundleID];
        if (!tempApp) {
            LMLocalApp *newapp = [app copy]; //TODO 为什么要 copy一份? (copy 的意义是什么?) 真正卸载时显示不正常的原因(转圈的位置不对)
            [temp setObject:newapp forKey:app.bundleID];
        } else {
            if(!tempApp.isScanComplete && !app.isScanComplete){
                [tempApp simpleMerge:app];
            }else if(tempApp.isScanComplete && app.isScanComplete){
                [tempApp bothScanCompleteMerge:app];
            }else{
                [tempApp resetScanStateMerge:app];
            }
        }
    }
    [ret addObjectsFromArray:temp.allValues];
    return [ret copy];
}


- (NSArray<LMLocalApp *> *) appsListSortByType:(LMSortType)sortType byAscendingOrder:(BOOL) isAscending {
    NSMutableArray<LMLocalApp *> *unsortedArray = [[self appsList] mutableCopy];
    //排序(只针对APP)
    [unsortedArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        LMLocalApp *item1 = (LMLocalApp *)obj1;
        LMLocalApp *item2 = (LMLocalApp *)obj2;
        
        NSComparisonResult result = [item1.showName localizedCompare:item2.showName];
        
        if (sortType == LMSortTypeSize)
        {
            if (item1.totalSize > item2.totalSize)
                result = NSOrderedDescending;
            if (item1.totalSize < item2.totalSize)
                result = NSOrderedAscending;
        }
        else if (sortType == LMSortTypeLastUsedDate)
        {
            if (item1.lastUsedDate && item2.lastUsedDate)
                result = [item1.lastUsedDate compare:item2.lastUsedDate];
            else if(item1.lastUsedDate)
                result = NSOrderedDescending;
            else if(item2.lastUsedDate)
                result = NSOrderedAscending;
        }
        
        return isAscending ? result:(0 - result);
    }];
    self.appsList = unsortedArray;
    return [unsortedArray copy];
}

// 返回值：YES：能立刻得到扫描结果， NO:不能立刻得到扫描结果
- (BOOL)fastScan:(LMSortType)sortType  byAscendingOrder:(BOOL)ascendingOrder {
    _isStopScaning = FALSE;
    
    [_scanLock lock];
    NSLog(@"%s, scaning...", __FUNCTION__);
    
    NSArray *rawAppList = [self enumLocalAppsWithPath];
    NSArray *delApps;
    NSArray *addApps;
    [self compareAppList:[self appsList] to:rawAppList resultDel:&delApps resultAdd:&addApps];
    NSLog(@"%s, delApps:%@, addApps:%@", __FUNCTION__,delApps, addApps);
    
    NSMutableArray<LMLocalApp *> *apps = [_appsList mutableCopy];
    [apps removeObjectsInArray:delApps]; //delApp 中的 item 来源于 appList,所以直接移除即可.
    [apps addObjectsFromArray:addApps];  // 把新增的 app 来源于rawAppList, 是不同的对象,可以直接新增.
    self.appsList = [[self mergeAppsByBundleId:apps] mutableCopy]; // 新增的软件可能是同 bundle 的不同path 的软件.需要合并到旧项目中
//    NSLog(@"%s, after remove delApps count:%lu, :%@", __FUNCTION__, (unsigned long)[_appsList count], _appsList);
    
    NSArray *needScanItems = [self needScanItems];
    if([needScanItems count] != 0){
        sortType = LMSortTypeName;  // 增量扫描时重置为按 name 进行排序.
    }
    [self appsListSortByType:sortType byAscendingOrder:ascendingOrder]; //排序
    
    BOOL returnFlag;
    if ([needScanItems count] == 0) {
        returnFlag =  YES;
    } else {
        [self scanIncreaseItems:needScanItems];
        returnFlag =  NO;
    }
    [_scanLock unlock];

    return returnFlag;
}

- (void)compareAppList:(NSArray<LMLocalApp *> *)appList to:(NSArray<LMLocalApp *> *) rawPathAppList resultDel:(NSArray **)resultDel resultAdd:(NSArray **)resultAdd {
    NSMutableArray<LMLocalApp *> *delApps = [NSMutableArray array];
    NSMutableArray<LMLocalApp *> *rawPathApps = [rawPathAppList mutableCopy];
    BOOL isContain = NO;
    
    for (LMLocalApp *left in appList) {
        isContain = NO;
        NSMutableArray *sameBundleArray = [[NSMutableArray alloc]init]; // rawPathAppList中可能有多项与appList的某一项相同. 所以必须用数组保存.
        
        for (LMLocalApp *right in rawPathApps) {
            if ([self compareAppPathWithScanEndApp:left toRawPathApp:right]) {
                isContain = YES;
                [sameBundleArray addObject:right];
            }
        }
        
        if (!isContain){
            // 没有在Applist2找到相同的元素，证明被移除了
            [delApps addObject:left];
        } else {
            // 有相同的原素，从rawPathAppList中移除，减少下一次的比较时间。
            // 并且，最后剩下的就是新增的元素。
            [rawPathApps removeObjectsInArray:sameBundleArray];
        }
    }
    
    *resultDel = [delApps copy];
    *resultAdd = [rawPathApps copy];
}

-(BOOL)compareAppPathWithScanEndApp:(LMLocalApp *)scanCompleteApp toRawPathApp:(LMLocalApp *)rawApp{
    if ([scanCompleteApp.bundlePath isEqualToString:rawApp.bundlePath]){
        return YES;
    }
    
    if(scanCompleteApp.otherSameBundleApps){
        for(LMLocalApp *otherScanCompleteApp in scanCompleteApp.otherSameBundleApps){
            if([otherScanCompleteApp.bundlePath isEqualToString:rawApp.bundlePath]){
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)uninstall:(LMLocalApp *)app {
    NSLog(@"%s, %@", __FUNCTION__, app);
    [app delSelectedItem];
}

#pragma mark -
#pragma mark private

- (void)onScanProgress:(NSNotification *)notify {
    // 通知都是发送在主线程执行, 不会有多线程问题.
    NSDictionary *info = notify.userInfo;
    NSInteger total = [[info objectForKey:LMKeyScanProgressTotal] longValue];
    _scanCount++;
    BOOL isScanEnd = (_scanCount == total);
    if (isScanEnd){
        NSNumber *scanType = [info objectForKey:LMKeyScanType];
        NSLog(@"%s, scan end, type:%@", __FUNCTION__, scanType);
        
        NSDictionary *userInfo = @{
                                   LMNotificationKeyListChangedReason:[NSNumber numberWithInteger:LMChangedReasonScanEnd],
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationListChanged
                                                            object:self
                                                          userInfo:userInfo];
       
    }
}

- (void)onAppDelectProgress:(NSNotification *)notify {
    LMLocalApp *delectedItem = [notify object];
    NSDictionary *userInfo = [notify userInfo];
//    float progress = [[userInfo objectForKey:LMNotificationKeyDelProgress] floatValue];
    BOOL isFinish = [[userInfo objectForKey:LMNotificationKeyIsDelFinished] boolValue];
    if (isFinish) {
        NSInteger reason = LMChangedReasonPartialDel;
        // 如果xxx.app被移除了，则从列表删除
        if ([delectedItem isBundleItemDelected]) {
            reason = LMChangedReasonDel;
            [_appsList removeObject:delectedItem];
        }
        // app 未删除的情况下, 仍然需要展示. 大小需要重新计算.
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{
                                       LMNotificationKeyListChangedReason:[NSNumber numberWithInteger:reason],
                                       LMNotificationKeyDelItem:delectedItem
                                       };
            [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationListChanged
                                                                object:self
                                                              userInfo:userInfo];
        });

    
    }
}



- (NSArray<NSString*> *)getAppsFromSystem {
    NSDate *date = [NSDate date];
    
    static OSStatus (*QMCopyAllApplicationURLs)(CFArrayRef * array) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QMCopyAllApplicationURLs = dlsym(RTLD_DEFAULT, "_LSCopyAllApplicationURLs");
    });
    
    
    if (!QMCopyAllApplicationURLs) {
        return nil;
    }
    
    NSMutableArray<NSString*> *scanPaths = [[NSMutableArray alloc] init];
    CFArrayRef appURLs = NULL;
    QMCopyAllApplicationURLs(&appURLs);
    
    for (CFIndex idx=0; idx<CFArrayGetCount(appURLs); idx++)
    {
        CFURLRef appURL = CFArrayGetValueAtIndex(appURLs, idx);
        NSString *appPath = (__bridge_transfer NSString *)CFURLCopyPath(appURL);
        appPath = [appPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([self fileVaild:appPath] && [self bundleVaild:appPath])
        {
            //去除掉末尾的"/"符号
            while (appPath.length>0 && [appPath hasSuffix:@"/"])
            {
                appPath = [appPath substringWithRange:NSMakeRange(0, appPath.length-1)];
            }
            [scanPaths addObject:appPath];
        }
    }
    CFRelease(appURLs);
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSLog(@"%s, interval:%f ms", __FUNCTION__,  interval * 1000);
    return [scanPaths copy];
}

- (NSArray *)getAppsByEnumDir {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (NSString *path in scanPaths) {
        [self scanAppFromPath:path toResult:results depth:0];
    }
    
    return [results copy];
}

// 递归扫描. 判断 路径是不是app(是目录,并且是 package 类型)
- (BOOL)scanAppFromPath:(NSString *)path toResult:(NSMutableArray *)results depth:(NSInteger) depth{
    if (depth > 3) {
        return NO;
    }
    

    struct stat fileStat;
    if (lstat([path fileSystemRepresentation], &fileStat) != 0) {
        return NO;
    }

    //处理软链, 若果链接的目的地址是scanPaths中的子路径，则不进行扫描(避免重复扫描)
    if (fileStat.st_mode & S_IFLNK)
    {
        NSString *destination = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:path error:NULL];
        if (!destination)
            return NO;
        
        for (NSString *onePath in scanPaths)
        {
            if ([destination hasPrefix:onePath])
            {
                return NO;
            }
            
        }
        
        path = destination;
    }
    //如果不是目录,不处理
    else if (!(fileStat.st_mode & S_IFDIR))
        return NO;
    
    //判定是否是package类型
    BOOL isPackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
    if (isPackage)
    {
        NSString *extension = [[path pathExtension] lowercaseString];
        if ([extension isEqualToString:@"app"] && [self fileVaild:path] && [self bundleVaild:path])
        {
            [results addObject:path];
            return YES;
        }
    } else {
        //添加子路径
        NSArray *childSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        for (NSString *childItem in childSubPaths)
        {
            NSString *childRelativePath = [path stringByAppendingPathComponent:childItem];
            [self scanAppFromPath:childRelativePath toResult:results depth:depth+1];
        }
    }
    return NO;
}


- (BOOL)fileVaild:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return NO;
    }
    
    //只处理用户目录和Applications目录
    if (![filePath hasPrefix:NSHomeDirectory()] && ![filePath hasPrefix:@"/Applications/"]) {
        if ([filePath containsString:@"SogouInput.app"]) {
            // Note: (v4.8.9)支持SogouInput卸载
            return YES;
        }
        return NO;
    }
    
    //垃圾箱中软件不处理
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/.Trash/"]])
        return NO;
    
    //Library中的软件不处理
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/Library/"]])
        return NO;
    
    //不处理/Applications/CrossOver下的Window兼容软件
    if ([filePath hasPrefix:[NSHomeDirectory() stringByAppendingString:@"/Applications/CrossOver/"]])
        return NO;
    
    //不处理build目录下的软件
    if ([filePath rangeOfString:@"/build/" options:NSCaseInsensitiveSearch].length > 0)
        return NO;
    
    //不处理Parallels虚拟机中的软件
    if ([filePath rangeOfString:@"\\/Applications \\(Parallels\\)\\/" options:NSRegularExpressionSearch].length > 0)
        return NO;
    //用户反馈node_modules文件夹下的App是项目依赖，清理会影响正常使用
    if ([filePath containsString:@"node_modules"]) {
        return NO;
    }
    //包下面的子程序不处理(逐层检测父路径是否为Package)
    BOOL isSubApp = NO;
    NSString *parentPath = [filePath stringByDeletingLastPathComponent];
    while ([parentPath.pathComponents count] > 2)
    {
        if ([parentPath.pathExtension length] > 0 && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:parentPath])
        {
            isSubApp = YES;
            break;
        }
        parentPath = [parentPath stringByDeletingLastPathComponent];
    }
    if (isSubApp)
        return NO;
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"app"])
    {
        return YES;
    }
    
    return NO;
}


- (BOOL)bundleVaild:(NSString *)bundlePath
{
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if([bundle.bundleIdentifier isEqualToString:@"com.apple.TransporterApp"])
        return YES;
    //不处理苹果软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.apple"]) {
        // Note: (v4.8.9)支持苹果自家应用(Keynote和Numbers)卸载
        if ([bundle.bundleIdentifier hasPrefix:@"com.apple.iWork.Keynote"]
            || [bundle.bundleIdentifier hasPrefix:@"com.apple.iWork.Numbers"]) {
            return YES;
        }
        return NO;
    }
    
    //不处理自身软件(但除了 LmeonLite)
    if ([bundle.bundleIdentifier hasPrefix:@"com.tencent.LemonLite"])
        return YES;
    if ([bundle.bundleIdentifier hasPrefix:@"com.tencent.LemonGroup"])
        return YES;
    if ([bundle.bundleIdentifier hasPrefix:@"com.tencent.Lemon"])
        return NO;
        
    //不处理CrossOver的windows软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.codeweavers.CrossOverHelper"])
        return NO;
    
    //不处理VMWare的Windows软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.vmware.proxyApp"])
        return NO;
    
    //不处理parallels的windows软件
    if ([bundle.bundleIdentifier hasPrefix:@"com.parallels.ApplicationGroupBridge"] ||
        [bundle.bundleIdentifier hasPrefix:@"com.parallels.winapp"])
        return NO;
    
    return YES;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(BOOL)stopScaning{
    return _isStopScaning;
}

-(void)setStopScaning:(BOOL)stop{
    _isStopScaning = stop;
    [self clearDataAfterStop];
}

-(void)clearDataAfterStop{
    [PkgUninstallManager clearAfterFinish];
}
@end

