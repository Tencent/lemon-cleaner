//
//  LMLocalApp.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMLocalApp.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/NSFileManager+Extension.h>
#import <QMCoreFunction/NSArray+Extension.h>
#import "LMPredefinedScaned.h"
#import "LMLocalAppListManager.h"
#import "PkgUninstallManager.h"
#import "LMUninstallXMLParseManager.h"
#import "LMASRecentProjectsXMLParse.h"


@implementation LMDateWrapper
- (instancetype)initWithDate:(NSDate *)date {
    self = [super init];
    if (self) {
        self.date = date;
    }
    return self;
}

@end


@interface LMLocalApp () {
    NSString *_bundleID;
    NSString *_appName;
    NSString *_showName;
    NSString *_executableName;
    NSString *_version;
    NSString *_buildVersion;
//    NSString  *copyright;
//    NSString  *bundlePath;
//    NSString  *minSystem;
    NSNumber *_bundleSize;
    LMDateWrapper *_lastUsedDate;
//    NSDate    *createDate;
    NSDictionary *_infoDict;

    NSNumber *_totalSize;

    NSMutableArray<LMFileGroup *> *_fileItemGroup;

    NSDate *_lastPostDate;
    LMPredefinedScaned *_predefinedScanner;

    PkgUninstallProvider *_pkgProvider;
    NSMutableArray<LMLocalApp *> *_otherSameBundleApps;

    NSArray<LMLoginItem *> *_loginItems;

}

@property(nonatomic, readonly, strong) NSDictionary *infoDict;

@end

@implementation LMLocalApp


- (instancetype)initWithPath:(NSString *)bundlePath {
    self = [super init];
    if (self) {
        _bundlePath = bundlePath;
        _isScanComplete = NO;

#ifdef  DebugAppUninstallScanBySerial
        NSString *bundleID = self.bundleID;
        NSString *appName = self.appName;
        NSString *version = self.version;
        NSDate *lastUsedDate = self.lastUsedDate;
        NSLog(@"init local app, app bundleID is %@, appName is %@,version is%@, lastUsedDate is%@", bundleID, appName, version, lastUsedDate);
#endif

#ifndef DebugNotUseBrewStrategy
        _predefinedScanner = [[LMPredefinedScaned alloc] init];
#endif

        //LMLocalApp的生成一种调用方式是在 App 卸载模块中,另一种调用方式是在 卸载残留检测中. 注意:PkgUninstallManager扫描所有 pkg 列表是在 pkg 卸载模块中, 单app 并不会扫描.
        _pkgProvider = [[PkgUninstallManager shared] getProviderWithAppBundleId:self.bundleID];

    }
    return self;
}


- (void)setAllSystemLoginItems:(NSArray<LMLoginItem *> *)loginItem {
    self->_loginItems = loginItem;
}

- (NSArray<LMFileGroup *> *)fileItemGroup {
    NSArray *ret = [_fileItemGroup copy];
    return ret;
}

- (NSArray<LMLocalApp *> *)otherSameBundleApps {
    NSArray *ret = [_otherSameBundleApps copy];
    return ret;
}

- (NSString *) getNameWithBundleId{
    
    NSString *returnStr = @"";
    if(_appName){
        returnStr = [returnStr stringByAppendingString:_appName];
    }
    
    returnStr = [returnStr stringByAppendingString:@"#"];
    if(_bundleID){
        returnStr = [returnStr stringByAppendingString:_bundleID];
    }
    return returnStr;
}


// 过滤出有效的 fileItemGroup->第一次完成扫描. 删除某些 Items 后都需要更新列表,  这里是实时获取的,性能不好
- (NSArray<LMFileGroup *> *)validFileItemGroup {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [_fileItemGroup count]; i++) {
        if ([_fileItemGroup[i].filePaths count] > 0) {
            [ret addObject:_fileItemGroup[i]];
        }
    }
    return [ret copy];
}

- (NSDictionary *)infoDict {
    if (!_infoDict) {
        /*
         获取info信息，先通过读取plist文件，这样的效率更高，如果读取失败(比如文件名不是Info.plist),
         则直接调用infoDictionary方法获取到Info信息。
         */

        NSDictionary *dict = nil;
        NSString *infoPath = [_bundlePath stringByAppendingString:@"/Contents/Info.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
            dict = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
        }
        if (!dict) {
            NSBundle *bundle = [NSBundle bundleWithPath:_bundlePath];
            dict = [bundle infoDictionary];
        }

        if (!dict) {
            return nil;
        }
        _infoDict = dict;
    }
    return _infoDict;
}

- (NSString *)bundleID {
    if (!_bundleID) {
        //获取bundleID
        _bundleID = self.infoDict[(NSString *) kCFBundleIdentifierKey];
        if ([_bundleID length] == 0) {
            return nil;
        }
    }
    return _bundleID;
}

- (NSString *)appName {
    if (!_appName) {
        NSString *appNameString = self.infoDict[(NSString *) kCFBundleNameKey];
        if (![appNameString isKindOfClass:[NSString class]] || [appNameString length] == 0) {
            appNameString = [[_bundlePath lastPathComponent] stringByDeletingPathExtension];
            if ([appNameString length] == 0) {
                return nil;
            }
        }
        _appName = appNameString;
    }
    return _appName;
}

- (NSString *)showName {
    if (!_showName) {
        NSBundle *bundle = [NSBundle bundleWithPath:_bundlePath];
        NSString *displayName = [bundle localizedInfoDictionary][@"CFBundleDisplayName"];
        if (![displayName isKindOfClass:[NSString class]] || displayName.length == 0) {
            displayName = [[_bundlePath lastPathComponent] stringByDeletingPathExtension];
            if (displayName.length == 0) {
                displayName = self.appName;
            }
        }
        _showName = displayName;
    }
    return _showName;
}

- (NSString *)executableName {
    if (!_executableName) {
        NSBundle *bundle = [NSBundle bundleWithPath:_bundlePath];
        NSString *executableNameString = self.infoDict[(NSString *) kCFBundleExecutableKey];
        if (![executableNameString isKindOfClass:[NSString class]] || [executableNameString length] == 0) {
            executableNameString = [[bundle executablePath] lastPathComponent];
            if ([executableNameString length] == 0) {
                executableNameString = self.appName;
            }
        }
        _executableName = executableNameString;
    }
    return _executableName;
}

- (NSString *)version {
    if (!_version) {
        NSString *shortVersion = nil;
        NSString *shortVersionStr = self.infoDict[@"CFBundleShortVersionString"];
        if ([shortVersionStr isKindOfClass:[NSString class]] && shortVersionStr.length > 0)
            shortVersion = [shortVersionStr versionString];

        NSString *bundleVersion = nil;
        NSString *bundleVersionStr = self.infoDict[(NSString *) kCFBundleVersionKey];
        if ([bundleVersionStr isKindOfClass:[NSString class]] && bundleVersionStr.length > 0)
            bundleVersion = [bundleVersionStr versionString];

        //当两个版本号都不存在时，给定一个默认值
        if (!shortVersion && !bundleVersion)
            _version = @"0.0";

        //当shortVersion不存在，采用bundleVersion
        if (!shortVersion)
            _version = bundleVersion;

            //当bunleVerion不存在,采用shortVersion
        else if (!bundleVersion)
            _version = shortVersion;

            //当两者相同时，仅保留shortVersion
        else if ([shortVersion isEqualToString:bundleVersion])
            _version = shortVersion;

            //当shortVersion以bundleVersion开始或结尾，仅保留shortVersion
        else if ([shortVersion hasPrefix:bundleVersion] || [shortVersion hasSuffix:bundleVersion])
            _version = shortVersion;

            //当bundleVersion以shortVersion开始或结尾，仅保留bundleVersion
        else if ([bundleVersion hasPrefix:shortVersion] || [bundleVersion hasSuffix:shortVersion])
            _version = bundleVersion;

            //其它情况
        else {
            NSArray *shortItems = [shortVersion componentsSeparatedByString:@"."];
            NSArray *bundleItems = [bundleVersion componentsSeparatedByString:@"."];

            //处理写法不一样：3.00与3.0.XXX,取位数长的版本号
            BOOL numberSame = YES;
            for (NSUInteger i = 0; i < shortItems.count && i < bundleItems.count; i++) {
                if ([shortItems[i] intValue] != [bundleItems[i] intValue]) {
                    numberSame = NO;
                    break;
                }
            }

            //如果是相同的表达方式，取位数长的版本号
            if (numberSame)
                _version = shortItems.count > bundleItems.count ? shortVersion : bundleVersion;

                //否则认定是版本号+编译号
            else {
                _version = shortVersion;
//                _buildVersion = bundleVersion;
            }
        }
    }
    return _version;
}

- (NSNumber *)bundleSize {
    if (!_bundleSize) {
        //优先通过Spotlight来获取size和date
        MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef) _bundlePath);
        if (item) {
            NSNumber *size = (__bridge_transfer NSNumber *) MDItemCopyAttribute(item, kMDItemFSSize);
            if (size && [size isKindOfClass:[NSNumber class]]) {
                _bundleSize = size;
            }
            CFRelease(item);
        } else {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_bundlePath error:NULL];

            NSNumber *size = attributes[NSFileSize];
            if (size && [size isKindOfClass:[NSNumber class]]) {
                _bundleSize = size;
            }
        }

        //通过逐层遍历去计算包大小
        if (!_bundleSize || [_bundleSize unsignedLongLongValue] == 0) {
            uint64 fileSize = [[NSFileManager defaultManager] diskSizeAtPath:_bundlePath];
            _bundleSize = @(fileSize);
        }
    }
    return _bundleSize;

}

- (NSDate *)lastUsedDate {
    if (!_lastUsedDate) {
        _lastUsedDate = [[LMDateWrapper alloc] init];
        MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef) _bundlePath);
        if (item) {
            NSDate *lastUsedData = (__bridge_transfer NSDate *) MDItemCopyAttribute(item, kMDItemLastUsedDate);
            if (lastUsedData && [lastUsedData isKindOfClass:[NSDate class]]) {
                _lastUsedDate.date = lastUsedData;
            }
            CFRelease(item);
        };
    }
    return _lastUsedDate.date;
}

- (NSInteger)totalSize {
//    if (!_totalSize) {
    NSArray *groupArray = [_fileItemGroup copy];

    NSInteger ret = 0;
    for (LMFileGroup *group in groupArray) {
        ret = ret + group.totalSize;
    }
    _totalSize = [[NSNumber alloc] initWithLong:ret];
//    }

    return [_totalSize longValue];
}

- (NSImage *)icon {
    //获取图标
    NSImage *_icon;
    @try {
        NSImage *iconImage = nil;
        iconImage = [[NSWorkspace sharedWorkspace] iconForFile:_bundlePath];

        if (iconImage != nil) {
            [iconImage setSize:NSMakeSize(32, 32)];
            _icon = iconImage;
        }
    }
    @catch (NSException *exception) {
        _icon = nil;
    }

    //设置默认的图标
    if (!_icon) {
        // 单例,只执行一次
        static NSImage *defaultIcon = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
            [defaultIcon setSize:NSMakeSize(32, 32)];
        });
        _icon = defaultIcon;
    }
    return _icon;
}

- (NSInteger)fileItemCount {
    NSInteger count = 0;
    NSArray<LMFileGroup *> *groupArray = self.fileItemGroup;
    for (LMFileGroup *group in groupArray) {
        count += [group.filePaths count];
    }
    return count;
}

- (BOOL)isBundleItemDelected {
    LMFileGroup *bundleGroup = [self groupByType:LMFileTypeBundle];
    return [bundleGroup.filePaths count] == 0;
}

- (NSInteger)selectedCount {
    NSInteger count = 0;
    for (LMFileGroup *group in self.fileItemGroup) {
        count += group.selectedCount;
    }
    return count;
}


- (NSInteger)selectedSize {
    NSInteger size = 0;
    for (LMFileGroup *group in self.fileItemGroup) {
        size += group.selectedSize;
    }
    return size;
}

- (void)delSelectedItem {
    NSInteger progressMax = [self selectedCount] + [self.fileItemGroup count];
    NSLog(@"%s, coutToDel:%ld", __FUNCTION__, progressMax);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __block NSInteger progressCount = 0;
        self->_lastPostDate = [NSDate date];

        NSMutableArray<LMFileItem *> *deleteBundleItems = [NSMutableArray array];
        NSInteger totalBundleCount = 0;

        for (LMFileGroup *group in self.fileItemGroup) {
            [self postDeletedProgressNotification:progressCount++ progressMax:progressMax isFinished:NO];
            
            if (group.fileType == LMFileTypeBundle) {
                totalBundleCount = group.filePaths.count;
            }
            
            // LMFileGroup deleteItems的时候,
            [group delSelectedItem:^(LMFileItem *_Nonnull delectedItem) {

                if (delectedItem.type == LMFileTypeBundle) {
                    [deleteBundleItems addObject:delectedItem];
                }

                // 发送清理进度
                [self postDeletedProgressNotification:progressCount++ progressMax:progressMax isFinished:NO];
            }];
        }
        [self clearLeaveOverThingsAfterBundleRemove:deleteBundleItems withBundleCount: totalBundleCount];

        // 发送清理完成事件
        // 事件接受者做的操作:
        // 1. isFinished 时,才会移除已被清理的项目
        // 2. 显示进度  包括主界面/ CellView
        
        [self postDeletedProgressNotification:progressMax progressMax:progressMax isFinished:YES];
    });
}


// 当app完全卸载完成时, 删除一些额外信息, 包括 dock 栏, pkgInfo 等
- (void)clearLeaveOverThingsAfterBundleRemove:(NSArray<LMFileItem *> *)removedBundleItems  withBundleCount:(NSInteger) totalBundleCount {

    if (removedBundleItems.count < 1 || totalBundleCount < 1) {
        return;
    }

    // 移除 Dock 栏上固定图标
    for (LMFileItem *removedBundleItem in removedBundleItems) {
        [self removeIconFromDock:removedBundleItem];
    }

    BOOL allBundleRemoved = removedBundleItems.count == totalBundleCount;
    if (allBundleRemoved) {
        [_pkgProvider removePkgInfo];
    }
}

- (void)cleanDeletedItems {
    for (LMFileGroup *group in _fileItemGroup) {
        [group cleanDeletedItem];
    }
}


- (void)postDeletedProgressNotification:(NSInteger)progressCount progressMax:(NSInteger)max isFinished:(BOOL)isFinished {
    float progress = (float) progressCount / max;

    // 需要在子线程中调用，会卡子线程，保证两次postNotification的间隔大于progresView的animationTime， 以避免进度条回退。
    // 这里对应的animationTime在McTableCellView中设置。
    while (_lastPostDate && [_lastPostDate timeIntervalSinceNow] > -0.02) {
        usleep(1000 * 20);
    }
//    NSLog(@"%s, maxProgress:%ld, curProgress:%ld, progress:%f ", __FUNCTION__, max, progressCount, progress);
    dispatch_async(dispatch_get_main_queue(), ^{

        NSDictionary *userInfo = @{
                LMNotificationKeyDelProgress: @(progress),
                LMNotificationKeyIsDelFinished: @(isFinished)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationDelectProgress object:self userInfo:userInfo];
    });
    _lastPostDate = [NSDate date];

}


//删除Dock中的Icon图标 =>只删除常驻类型的
- (void)removeIconFromDock:(LMFileItem *)fileItem {
    //读取Dock的配置文件，通过CFPreferences的API可以避免直接读文件不同步的问题

    //persistent-apps 常驻在 Dock 栏的App\
    CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
    id apps = (__bridge_transfer NSArray *) CFPreferencesCopyAppValue(CFSTR("persistent-apps"), CFSTR("com.apple.dock"));

    if (!apps || ![apps isKindOfClass:[NSArray class]])
        return;

    NSMutableArray *removeApps = [[NSMutableArray alloc] init];
    for (id appInfo in apps) {
        if (![appInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *titleInfo = [appInfo objectForKey:@"tile-data"];
        if (!titleInfo || ![titleInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *fileInfo = [titleInfo objectForKey:@"file-data"];
        if (!fileInfo || ![fileInfo isKindOfClass:[NSDictionary class]])
            continue;

        NSString *fileURLString = [fileInfo objectForKey:@"_CFURLString"];
        NSURL *fileURL = [NSURL URLWithString:fileURLString];
        NSString *filePath = [fileURL path];
        if (!filePath)
            continue;

        NSString *dockName = [[filePath.lastPathComponent stringByDeletingPathExtension] lowercaseString];

        //与名字绝对匹配
        if ([filePath hasPrefix:fileItem.path]) {
            [removeApps addObject:appInfo];

            //判定垃圾桶中App与Dock中的相对应(在垃圾桶&&图标对应文件不存在&&文件名相似)
        } else if ([[fileItem.path stringByAbbreviatingWithTildeInPath] hasPrefix:@"~/.Trash"]
                && ![[NSFileManager defaultManager] fileExistsAtPath:filePath]
                && ([[self.appName lowercaseString] hasPrefix:dockName] ||
                [[self.executableName lowercaseString] hasPrefix:dockName] ||
                [dockName hasPrefix:[self.appName lowercaseString]] ||
                [dockName hasPrefix:[self.executableName lowercaseString]] ||
                [[fileItem.path.lastPathComponent lowercaseString] hasPrefix:dockName])) {

            [removeApps addObject:appInfo];

        }

    }

    if ([removeApps count] > 0) {
        apps = [apps arrayByRemoveObjectsFromArray:removeApps];

        //写入Dock的配置文件
        //通过CFPreferences的API可以避免直接读文件不同步的问题
        CFPreferencesSetAppValue(CFSTR("persistent-apps"), (__bridge CFArrayRef) apps, CFSTR("com.apple.dock"));
        CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));

        //杀死Dock进程(重启)
        system("killall Dock");
    }
}


- (NSString *)description {
    return [NSString stringWithFormat:@"bundleId:%@\n isScanComplete:%hhd\n, appName:%@\n, showName:%@\n, version:%@\n, bundlePath:%@\n, lastUsedDate:%@\n, totalSize:%ld, icon:%p, fileItems:%@, ", self.bundleID, self.isScanComplete, self.appName, self.showName, self.version, self.bundlePath, self.lastUsedDate, self.totalSize, self.icon, self.fileItemGroup];
}

- (void)removeDup:(NSMutableArray<LMFileGroup *> *)fileItemGroup {
    int groupCount = (int) [fileItemGroup count];
    for (int i = groupCount - 1; i >= 0; i--) {
        NSMutableArray *searchArray = [fileItemGroup[i].filePaths mutableCopy];
        NSMutableArray *resultArray = [NSMutableArray array];

        for (LMFileItem *itemPath in searchArray) {
            BOOL exists = NO;
            for (int j = groupCount - 1; j >= 0; j--) {

                if (j == i) continue;

                if (filepathExistsAtGroup(itemPath, fileItemGroup[j])) {
                    exists = YES;
                    break;
                }
            }
            if (!exists) {
                [resultArray addObject:itemPath];
            }
        }
        fileItemGroup[i].filePaths = [resultArray copy];
    }


    //如果去重时删除了主Bundle
    LMFileGroup *bundleGroup = [self groupByType:LMFileTypeBundle inGroups:fileItemGroup];
    if ([bundleGroup.filePaths count] == 0) {
        [bundleGroup addFileItem:[LMFileItem itemWithPath:_bundlePath withType:LMFileTypeBundle]];
    }
}

// scanFileItems 可能来自两个不同的模块, 软件卸载 或者 卸载残留,
// 为了做到App卸载全量扫描过程中,当界面退出时,及时停止扫描操作, 所以区分两种不同类型.
- (void)scanFileItems:(AppScanType)scanType {
    LMLocalAppListManager *manager = [LMLocalAppListManager defaultManager];

    NSMutableArray<LMFileGroup *> *fileItemGroups = [[NSMutableArray alloc] init];
    // 用 brew 的搜索逻辑进行搜索
    [_predefinedScanner setScanApp:[self.appName stringByAppendingPathExtension:@"app"]];
    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }

    // 使用 pkgutil 的搜索逻辑进行搜索
    [_pkgProvider searchAllItems];
    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }
    //模糊匹配搜索 + 使用brew规则扫描的结果.


    // fileItemGroups add的FileItemGroup不为空, 那么展示的时候怎么排除这些空的呢.
    [fileItemGroups addObject:[self searchBundles]];
    [fileItemGroups addObject:[self searchKext]];
    [fileItemGroups addObject:[self searchFileSystem]];
    [fileItemGroups addObject:[self searchPreferencePane]];
    [fileItemGroups addObject:[self searchLoginItem]];
//    [fileItemGroup addObject:[self searchRunningApp]];

    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }

    if (_bundleID && [_bundleID isEqualToString:@"com.google.android.studio"]) {
        int a = 0;
    }
    [fileItemGroups addObject:[self searchSupports]];
    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }
    [fileItemGroups addObject:[self searchCaches]];
    [fileItemGroups addObject:[self searchPreferences]];
    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }
    [fileItemGroups addObject:[self searchStates]];  // 未知, mac 10.14 没有这个目录.

    [fileItemGroups addObject:[self searchCrashReporters]];
    [fileItemGroups addObject:[self searchLogs]];
    [fileItemGroups addObject:[self searchSandboxs]];
    [fileItemGroups addObject:[self searchLaunchDaemons:fileItemGroups]];

    [fileItemGroups addObject:[self searchOthers]];
    //以下两个相当于对一些特殊的应用运营，Lemon有自己的运营策略，所以这里不用
//    [self searchSpecial];
//    [self searchPlugin];

//    NSLog(@"%s, before remove dup:%@", __FUNCTION__, fileItemGroup);

    //去除重复或包含的路径(采用倒序的原因是如果出面重复尽量保留前面扫描的路径)
    [self removeDup:fileItemGroups];

    _totalSize = nil; //扫描后将_totalSize复位为nil, 下次取totalSize时将会重新计算大小。
    _fileItemGroup = fileItemGroups;

    if (scanType == AppUninstall && manager.stopScaning) {
        return;
    }
    _isScanComplete = YES;
}

- (void)sendDebugInnerScanNotification:(NSString *)phraseName {

#ifdef  DebugAppUninstallScanBySerial
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setObject:self forKey:LMKeyScanProgressCurObject];
    [info setObject:[NSString stringWithFormat:@"search:%@", phraseName] forKey:LMKeyScanProgressCurPhrase];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LMNotificationScanInnerProgress
                                                            object:self
                                                          userInfo:info];
    });
    
    [NSThread sleepForTimeInterval:3.0];
#endif
}


- (LMFileGroup *)groupByType:(LMFileType)type inGroups:(NSMutableArray *)groups {
    for (LMFileGroup *group in groups) {
        if (group.fileType == type) {
            return group;
        }
    }
    return nil;
}

- (LMFileGroup *)groupByType:(LMFileType)type {
    for (LMFileGroup *group in self.fileItemGroup) {
        if (group.fileType == type) {
            return group;
        }
    }
    return nil;
}

- (LMFileGroup *)searchBundles {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeBundle]];

    // 对于 application 这项, 可能存在多个同 bundleId 的 app,需要 merge 结果
    LMFileGroup *applicationItem = [self searchApplication];
    if (self.otherSameBundleApps) {
        for (LMLocalApp *otherApp in self.otherSameBundleApps) {
            LMFileGroup *otherApplicationItem = [otherApp searchApplication];
            [applicationItem merge:otherApplicationItem];
        }
    }

    NSArray *pkgSearchBundlePaths = [_pkgProvider searchBundles];
    LMFileGroup *pkgSearchGroup = [[LMFileGroup alloc] init];
    pkgSearchGroup.fileType = LMFileTypeBundle;
    pkgSearchGroup.filePaths = [self genFileItemArrayWithPaths:pkgSearchBundlePaths withType:LMFileTypeBundle];


    [applicationItem merge:pkgSearchGroup];

    return applicationItem;
}

- (LMFileGroup *)searchApplication {

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeBundle;
    NSArray *pathArray = @[self.bundlePath];
    group.filePaths = [self genFileItemArrayWithPaths:pathArray withType:LMFileTypeBundle];

    return group;
}

- (LMFileGroup *)searchKext {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeKextWithPath]];


    LMFileGroup *group = [[LMFileGroup alloc] init];

    // brew规则 搜索到的kext 是 bundleid 类型的, 卸载时应该用" sudo kextunload -b  com.paragon-software.filesystems.ntfs"
    // pkg 扫描规则扫到的 kext是路径, 卸载时应该用" sudo kextunload  /Library/Extensions/ufsd_NTFS.kext
    // 为了防止冲突,只采用一种扫描结果,优先使用 pkg 扫描结果.

    NSArray *pkgKexts = [_pkgProvider scanKext];
    NSArray *predefineKexts = [_predefinedScanner scanKext];

    NSMutableArray *filePaths = [NSMutableArray array];
    if (pkgKexts && pkgKexts.count > 0) {
        group.fileType = LMFileTypeKextWithPath;
        [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:pkgKexts withType:LMFileTypeKextWithPath]];
    } else if (predefineKexts && predefineKexts.count > 0) {
        group.fileType = LMFileTypeKextWithBundleId;
        [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:predefineKexts withType:LMFileTypeKextWithBundleId]];
    }

    group.filePaths = filePaths;
    return group;

}

- (LMFileGroup *)searchFileSystem {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeFileSystem]];


    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeFileSystem;
    NSArray *searchPaths = [_pkgProvider searchFileSystem];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:searchPaths withType:LMFileTypeFileSystem]];
    group.filePaths = filePaths;

    return group;
}


- (LMFileGroup *)searchPreferencePane {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeFileSystem]];


    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypePreferencePane;
    NSArray *searchPaths = [_pkgProvider searchPreferencePane];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:searchPaths withType:LMFileTypePreferencePane]];
    group.filePaths = filePaths;

    return group;
}

- (LMFileGroup *)searchLoginItem {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeLoginItem]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeLoginItem;
    NSMutableArray *filePaths = [NSMutableArray array];

    LMLoginItem *loginItem = [LoginItemManager loginItemAt:self.bundlePath in:self->_loginItems];
    if (loginItem) {
        NSArray *searchLoginItem = @[loginItem.displayName];
        [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:searchLoginItem withType:LMFileTypeLoginItem]];
    }

    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchRunningApp {
    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeSignal;
    NSArray *predefineKillSignal = [_predefinedScanner scanSignal];
    // TODO 正在运行的 app,没有适配 signal 或者 quit,也要杀死.
    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:predefineKillSignal withType:LMFileTypeSignal]];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchSupports {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeSupport]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeSupport;
    NSArray *searchPaths = @[@"/Library/Application Support",
            [@"~/Library/Application Support" stringByExpandingTildeInPath]
    ];

//    if([self.bundleID isEqualToString:@"com.microsoft.edgemac.Canary"]){
//        NSLog(@"");
//    }
    NSMutableSet *allSets = [NSMutableSet set];
    NSMutableArray *searchArray = [self searchFiles:searchPaths options:kMcSearchByName | kMcSearchByBundleID | kMcSearchByCompany suffixRegex:nil fileGroup: group];
    [allSets addObjectsFromArray:searchArray];
    [allSets addObjectsFromArray:[_predefinedScanner scanSupports]];
    [allSets addObjectsFromArray:[_pkgProvider scanSupports]];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:[allSets allObjects] withType:LMFileTypeSupport]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;

//    NSLog(@"_predefinedScanner searchSupports ... filePaths is %@", [[[_predefinedScanner scanSupports] valueForKey:@"description"] componentsJoinedByString:@""]);
    return group;
}

- (LMFileGroup *)searchCaches {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeCache]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeCache;

    NSString *tempPathT = NSTemporaryDirectory();
    NSString *tempPathC = [[tempPathT stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"C"];
    NSArray *searchPaths = @[@"/Library/Caches",
            [@"~/Library/Caches" stringByExpandingTildeInPath],
            tempPathT, tempPathC];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName | kMcSearchByBundleID | kMcSearchByCompany suffixRegex:nil fileGroup: group];
    [result addObjectsFromArray:[_predefinedScanner scanCaches]];
    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypeCache]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchPreferences {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypePreference]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypePreference;

    NSArray *searchPaths = @[@"/Library/Preferences",
            [@"~/Library/Preferences" stringByExpandingTildeInPath]
    ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID | kMcSearchByName suffixRegex:nil fileGroup: group];

    [result addObjectsFromArray:[_predefinedScanner scanPreferences]];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypePreference]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchStates {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeState]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeState;

    NSArray *searchPaths = @[
            [@"~/Library/Saved Application State" stringByExpandingTildeInPath]
    ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:nil fileGroup: group];
    [result addObjectsFromArray:[_predefinedScanner scanStates]];
    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypeState]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchCrashReporters {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeReporter]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeReporter;

    NSArray *searchPaths = @[@"/Library/Application Support/CrashReporter",
            @"/Library/Logs/DiagnosticReports",
            [@"~/Library/Application Support/CrashReporter" stringByExpandingTildeInPath],
            [@"~/Library/Logs/DiagnosticReports" stringByExpandingTildeInPath]
    ];

    /*
     ([0-9a-fA-F-]{5,})匹配FF6CC5AF-BAB1-5F5B
     ([0-9]{4}(-[0-9]{1,2}){2})匹配日期
     */
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName | kMcSearchByBundleID | kMcSearchByCompany suffixRegex:@"_(([0-9a-fA-F-]{5,})|([0-9]{4}(-[0-9]{1,2}){2})).*" fileGroup: group];
    [result addObjectsFromArray:[_predefinedScanner scanCrashReporters]];
    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypeReporter]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchLogs {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeLog]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeLog;

    NSArray *searchPaths = @[@"/Library/Logs",
            [@"~/Library/Logs" stringByExpandingTildeInPath]
    ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByName | kMcSearchByBundleID | kMcSearchByCompany suffixRegex:nil fileGroup: group];
    [result addObjectsFromArray:[_predefinedScanner scanLogs]];
    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypeLog]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchSandboxs {
    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeSandbox]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeSandbox;

    NSArray *searchPaths = @[
            [@"~/Library/Containers" stringByExpandingTildeInPath]
    ];
    NSMutableArray *result = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:nil fileGroup: group];

    [result addObjectsFromArray:[self containerFromPlist]];
    [result addObjectsFromArray:[_predefinedScanner scanSandboxs]];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:result withType:LMFileTypeSandbox]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

- (LMFileGroup *)searchLaunchDaemons:(NSMutableArray *)groups {

    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeDaemon]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeDaemon;

    NSArray *searchPaths = @[@"/Library/LaunchAgents",
            @"/Library/LaunchDaemons",
            @"/Library/StartupItems",
            [@"~/Library/LaunchAgents" stringByExpandingTildeInPath],
            [@"~/Library/LaunchDaemons" stringByExpandingTildeInPath]];

    NSMutableSet *allSet = [NSMutableSet set];
//    if([self.appName containsString:@"MacBoos"]){
//           NSLog(@"");
//    }
    //找到绝对匹配
    NSArray *searchResult = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:@"\\.plist" fileGroup: group];
    [allSet addObjectsFromArray:searchResult];

    //找到模糊匹配,然后根据里面的内容做二次判断
    NSMutableArray *vaguenessArr = [NSMutableArray array];
    NSArray *searchVaguenessResult = [self searchFiles:searchPaths options:kMcSearchByBundleID suffixRegex:@".{1,}\\.plist" fileGroup: group];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *resultPath in searchVaguenessResult) {
        //找到守护进程的Plist文件，然后再根据该文件找到可执行文件
        NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:resultPath];
        id programInfo = plistDict[@"Program"];
        if (!programInfo) {
            programInfo = plistDict[@"ProgramArguments"];
            if (!programInfo) {
                continue;
            }
        }

        //找到所有出现的路径
        NSMutableArray *exeArray = [[NSMutableArray alloc] init];
        if ([programInfo isKindOfClass:[NSArray class]]) {
            for (NSString *program in programInfo) {
                if ([program isKindOfClass:[NSString class]] &&
                        [fileManager fileExistsAtPath:program]) {
                    [exeArray addObject:program];
                }
            }
        } else if ([programInfo isKindOfClass:[NSString class]]) {
            if ([fileManager fileExistsAtPath:programInfo]) {
                [exeArray addObject:programInfo];
            }
        }

        //判定路径是否与所有扫描到的路径关联
        for (NSString *exePath in exeArray) {
            BOOL find = NO;
            for (LMFileGroup *group in groups) {
                for (LMFileItem *fileItem in group.filePaths) {
                    if ([fileItem.path isEqualToString:exePath] ||
                            [fileItem.path isParentPath:exePath]) {
                        [vaguenessArr addObject:resultPath];
                        find = YES;
                        break;
                    }
                }
                if (find) break;
            }
            if (find) break;
        }
    }
    [allSet addObjectsFromArray:vaguenessArr];


    [allSet addObjectsFromArray:[_predefinedScanner scanLaunchDaemons]];
    [allSet addObjectsFromArray:[_pkgProvider scanLaunchDaemons]];

    NSMutableArray *filePaths = [NSMutableArray array];
    [filePaths addObjectsFromArray:[self genFileItemArrayWithPaths:[allSet allObjects] withType:LMFileTypeDaemon]];
    filePaths = [self removeDupInArray:filePaths];
    group.filePaths = filePaths;
    return group;
}

//扫描其它文件
- (LMFileGroup *)searchOthers {

    [self sendDebugInnerScanNotification:[LMFileItem getLMFileTypeName:LMFileTypeOther]];

    LMFileGroup *group = [[LMFileGroup alloc] init];
    group.fileType = LMFileTypeOther;
    NSArray *searchPaths = @[@"/Library",
            [@"~/Library" stringByExpandingTildeInPath], @"/Users/Shared", [@"~/Library/WebKit" stringByExpandingTildeInPath]
    ];
    NSArray *array1 = [self searchFiles:searchPaths options:kMcSearchByCompany | kMcSearchByName | kMcSearchByBundleID suffixRegex:nil fileGroup: group];

//    searchPaths = @[[@"~/Pictures/" stringByExpandingTildeInPath],
//                    [@"~/Movies" stringByExpandingTildeInPath],
//                    [@"~/Music" stringByExpandingTildeInPath],
//                    [@"~/Downloads" stringByExpandingTildeInPath],
//                    [@"~/Documents" stringByExpandingTildeInPath],
//                    [@"~/Desktop" stringByExpandingTildeInPath]];
//    NSArray *array2 = [self searchFiles:searchPaths options:kMcSearchByName|kMcSearchByBundleID suffixRegex:nil];

//    NSMutableArray *r esultArray = [[NSMutableArray alloc] initWithCapacity:array1.count+array2.count];


    // 来自predefine,来源于预定策略.
    NSArray *predefineds = [_predefinedScanner scanOthers];
    NSArray *pkgSearchs = [_pkgProvider scanOthers];
    
    NSInteger maxCount = array1.count + predefineds.count;
    NSMutableSet *resultSet = [[NSMutableSet alloc] initWithCapacity:maxCount];
    [resultSet addObjectsFromArray:array1];
    [resultSet addObjectsFromArray:predefineds];
    [resultSet addObjectsFromArray:pkgSearchs];

    // 特殊处理(目前是VMware有虚拟机文件需要删除)
    [resultSet addObjectsFromArray:[self searchCustomPath]];

    // 因为数据来自于 array1, array2, array3. 数据需要合并
    [self removeSubPathIfExist:resultSet];


//    [resultArray addObjectsFromArray:array2];
    NSMutableArray<LMFileItem *> *filePaths = [NSMutableArray array];
    NSArray<LMFileItem *> *resultItem = [self genFileItemArrayWithPaths:resultSet.allObjects withType:LMFileTypeOther];
    [filePaths addObjectsFromArray:resultItem];



    // other类型默认是不勾选的，但从预定义扫描得到的item将其默认勾选。
    for (LMFileItem *item in filePaths) {
        for (NSString *predifineStr in predefineds) {
            if ([item.path isEqualToString:predifineStr]) {
                item.isSelected = YES;
                break;
            }
        }
    }
    group.filePaths = filePaths;
    return group;
}

- (NSArray *)searchCustomPath
{
    if (_bundleID && [_bundleID isEqualToString:@"com.vmware.fusion"]) {
        // ~/Virtual Machines.localized/目录下的.vmwarevm虚拟机文件需要展示是否删除
        // 收集此目录下的虚拟机path
        NSString *directory = [@"~/" stringByExpandingTildeInPath];
        NSString *searchPath = [NSString stringWithFormat:@"%@%@", directory, @"/Virtual Machines.localized/"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:searchPath error:&error];
        // 筛选虚拟机文件
        if (!filePaths || filePaths.count == 0) {
            return nil;
        }
        NSMutableArray *vmPaths = [NSMutableArray array];
        for (NSString *filePath in filePaths) {
            BOOL isDir = NO;
            NSString *path = [searchPath stringByAppendingPathComponent:filePath];
            [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
            if (isDir && [[path pathExtension] isEqualToString:@"vmwarevm"]) {
                [vmPaths addObject:path];
            }
        }
        return [vmPaths copy];
    }
    if (_bundleID && [_bundleID isEqualToString:@"com.google.android.studio"]) {
        // 策略:
        // 1:查找recentProjects.xml的所有文件出来（AS各个版本此文件位置可能不同）
        // 2:解析每个recentProjects.xml文件的recentPaths，去除汇总得到所有用户工程目录
        // 3:搜索展示用户工程目录
        return [self findAndroidStudioRecentProjectsXMLFilePaths];

    }
    return nil;
}

// 查找AS所有的recentProjects.xml文件
- (NSArray<NSString *> *)findAndroidStudioRecentProjectsXMLFilePaths
{
    NSArray *searchDirectorys = @[
            [@"~/Library/Application Support/Google" stringByExpandingTildeInPath],
            [@"~/Library/Preferences" stringByExpandingTildeInPath]
    ];

    // 构造搜索路径
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *resultPaths = [NSMutableArray array];
    for (NSString *directory in searchDirectorys) {
        NSArray<NSString *> *dirFiles = [fileManager contentsOfDirectoryAtPath:directory error:nil];
        if (dirFiles && dirFiles.count > 0) {
            NSString *matchPath = @"AndroidStudio*";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", matchPath];
            NSArray *results = [dirFiles filteredArrayUsingPredicate:predicate];
            for (NSString *matchFile in results) {
                NSString *recentProjectsXMLFilePath = [NSString stringWithFormat:@"%@/%@/options/recentProjects.xml", directory, matchFile];
                BOOL isDirectory = NO;
                if ([fileManager fileExistsAtPath:recentProjectsXMLFilePath isDirectory:&isDirectory]) {
                    if (!isDirectory) {
                        [resultPaths addObject:recentProjectsXMLFilePath];
                    }
                }
            }
        }
    }

    // 查找所有存在的目标文件
    if (resultPaths.count > 0) {
        NSMutableSet *recentPathSet = [NSMutableSet set];
        for (NSString *recentXMLPath in resultPaths) {
            NSArray *recentPaths = [self findAndroidStudioRecentProjectsPathsFromXMLFile:recentXMLPath];
            [recentPathSet addObjectsFromArray:recentPaths];
        }
        return [recentPathSet allObjects];
    }
    return nil;

}

- (NSArray<NSString *> *)findAndroidStudioRecentProjectsPathsFromXMLFile:(NSString *)xmlFilePath
{
    LMASRecentProjectsXMLParse *parse = [LMASRecentProjectsXMLParse new];
    return [parse parseXMLWithPath:xmlFilePath];
}


// 一个路径集合中存在多个路径, 如果路径之间存在 包含关系.则移子路径.防止大小统计重复.
// 比如 brew 配置规则:  ~/Library/Android,  ~/Library/Android/sdk
- (void)removeSubPathIfExist:(NSMutableSet *)resultSet {

    NSMutableArray *needRemoveArray = [[NSMutableArray alloc] init];
    for (NSString *outerItem in resultSet) {

        BOOL needRemove = false;
        for (NSString *innerItem in resultSet) {
            if ([innerItem isEqualToString:outerItem]) {
                continue;
            }

            // 路径是越长的,越具体,越在文件树的底部.
            if ([outerItem containsString:innerItem]) {
                needRemove = true;
                break;
            }
        }

        if (needRemove) {
            [needRemoveArray addObject:outerItem];
        }
    }

    if (needRemoveArray.count > 0) {
        NSLog(@"%s, needRemoveArray is %@", __FUNCTION__, needRemoveArray);
        for (NSString *needRemoveItem in needRemoveArray) {
            [resultSet removeObject:needRemoveItem];
        }
    }
}

////特殊搜索(还不知道名字的项目)
//- (LMFileGroup *)searchSpecial
//{
//    NSDictionary *pluginRelativeInfo = @{@"com.google.Chrome":
//                                             @{@(McSoftwareFileUnname):@[@"~/Library/Google/GoogleSoftwareUpdate",@"~/Library/Google/Google Chrome Brand.plist"]},
//                                         @"com.qihoo.mac360safe":
//                                             @{@(McSoftwareFileDaemon): @[@"/Library/LaunchDaemons/com.qihoo.360safe.daemon.plist"]}
//                                         };
//
//    NSDictionary *specialInfo = [pluginRelativeInfo objectForKey:soft.bundleID];
//    for (id type in specialInfo)
//    {
//        NSArray *specialItems = [specialInfo objectForKey:type];
//        if (!specialItems || specialItems.count == 0)
//            continue;
//
//        //找到对应的容器
//        NSMutableArray *typeArray = [pathInfo objectForKey:type];
//        if (!typeArray)
//        {
//            typeArray = [[NSMutableArray alloc] init];
//            [pathInfo setObject:typeArray forKey:type];
//        }
//
//        //加入有效的路径
//        for (NSString *onePath in specialItems)
//        {
//            NSString *realPath = [onePath stringByExpandingTildeInPath];
//            if ([[NSFileManager defaultManager] fileExistsAtPath:realPath])
//                [typeArray addObject:realPath];
//        }
//    }
//}

////检索插件(精确)
//- (LMFileGroup *)searchPlugin
//{
//    NSDictionary *pluginRelativeInfo = @{@"com.qvod.QvodPlayer":
//                                             @[@"com.qvod.qvodplayerplugin",@"com.qvod.qvodbrowserplugin"],
//                                         @"com.google.Chrome":
//                                             @[@"com.google.Keystone",@"com.google.Keystone.Agent"],
//                                         @"com.magican.castle":
//                                             @[@"com.magican.castle.monitor"]
//                                         };
//    NSArray *pluginBundleIDs = [pluginRelativeInfo objectForKey:self.bundleID];
//    for (NSString *relativeBundleID in pluginBundleIDs)
//    {
//        NSString *pluginPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:relativeBundleID];
//        if (!pluginPath)
//        {
//            continue;
//        }
//        McSoftwareFileScanner *pluginUninstaller = [McSoftwareFileScanner scannerWithPath:pluginPath];
//        [pluginUninstaller start];
//        for (id key in pluginUninstaller.pathInfo)
//        {
//            NSMutableArray *mainTypeArray = [pathInfo objectForKey:key];
//            NSMutableArray *pluginTypeArray = [pluginUninstaller.pathInfo objectForKey:key];
//            if (!mainTypeArray)
//            {
//                [pathInfo setObject:pluginTypeArray forKey:key];
//            }else
//            {
//                [mainTypeArray addObjectsFromArray:pluginTypeArray];
//            }
//        }
//
//    }
//}
- (NSMutableArray<LMFileItem *> *)removeDupInArray:(NSArray<LMFileItem *> *)array {
    NSMutableArray<LMFileItem *> *removeDupArray = [NSMutableArray array];
    for (int i = 0; i < [array count]; i++) {
        LMFileItem *item = array[i];
        BOOL skip = NO;
        for (NSUInteger j = 0; j < [removeDupArray count]; j++) {
            if ([item.path isEqualToString:removeDupArray[j].path] || [[removeDupArray[j] path] isParentPath:item.path]) {
                skip = YES;
                break;
            }

            if ([item.path isParentPath:[removeDupArray[j] path]]) {
                removeDupArray[j] = item;
                skip = YES;
                break;
            }
        }
        if (!skip) {
            [removeDupArray addObject:item];
        }
    }
    return removeDupArray;
}


- (NSArray<LMFileItem *> *)genFileItemArrayWithPaths:(NSArray *)array withType:(LMFileType)fileType {
    NSMutableArray<LMFileItem *> *itemArray = [[NSMutableArray alloc] init];
    for (NSString *path in array) {
        LMFileItem *item = [LMFileItem itemWithPath:path withType:fileType];
        item.isSelected = !(fileType == LMFileTypeOther);
        [itemArray addObject:item];
    }
    return [itemArray copy];
}

//简单 merge: (还未扫描残留), 需要全量扫描.
- (void)simpleMerge:(LMLocalApp *)mergedApp {
    // 如果两个都没打开过，用版本号高的那个
    // 如果有被打开过，用最近打开过的那个
    BOOL replaceUsingApp = NO;
    if (!self.lastUsedDate && !mergedApp.lastUsedDate) {
        if ([self compareVersion:self.version to:mergedApp.version] == NSOrderedAscending) {
            replaceUsingApp = YES;
        }
    } else if (self.lastUsedDate && mergedApp.lastUsedDate) {
        if ([self.lastUsedDate compare:mergedApp.lastUsedDate] == NSOrderedAscending) {
            replaceUsingApp = YES;
        }
    } else if (!self.lastUsedDate && mergedApp.lastUsedDate) {
        replaceUsingApp = YES;
    }

    LMLocalApp *otherApp;
    if (replaceUsingApp) {
        otherApp = [self copy]; //把自己作为子项
        _appName = mergedApp.appName;
        _showName = mergedApp.showName;
        _executableName = mergedApp.executableName;
        _version = mergedApp.version;
        _bundlePath = mergedApp.bundlePath;
        _lastUsedDate = [[LMDateWrapper alloc] initWithDate:mergedApp.lastUsedDate];
    } else {
        otherApp = mergedApp;
    }

    if (!self->_otherSameBundleApps) {
        _otherSameBundleApps = [[NSMutableArray alloc] init];
    }
    [_otherSameBundleApps addObject:otherApp];

}

//增量 merge: merge 的两个 app,有一个没有扫描完毕. 需要重新扫描这个 app
- (void)resetScanStateMerge:(LMLocalApp *)app {
    NSLog(@"%s : app1 path:%@, app2 path :%@ ", __FUNCTION__, self.bundlePath, app.bundlePath);
    self.isScanComplete = NO;
    app.isScanComplete = NO;
    [self simpleMerge:app];
    _fileItemGroup = nil;
}

// merge 的两个 app 都扫描结束了(原则上不存在这种情况)
- (void)bothScanCompleteMerge:(LMLocalApp *)app {
    NSLog(@"%s : app1 path:%@, app2 path :%@ ", __FUNCTION__, self.bundlePath, app.bundlePath);

    [self simpleMerge:app];
    for (LMFileGroup *group in app.fileItemGroup) {
        LMFileGroup *dstGroup = [self groupByType:group.fileType];
        [dstGroup merge:group];
    }
}


- (NSComparisonResult)compareVersion:(NSString *)version1 to:(NSString *)version2 {
    NSString *version1_highest = [version1 componentsSeparatedByString:@"."][0];//取最高位比较
    NSString *version2_highest = [version2 componentsSeparatedByString:@"."][0];
    NSInteger v1 = [version1_highest integerValue];
    NSInteger v2 = [version2_highest integerValue];
    if (v2 > v1) {
        return NSOrderedAscending;
    } else if (v2 < v1) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}


#pragma mark --


//判断是否已经存在该目录(包括逻辑上层次包含)
static BOOL filepathExistsAtGroup(LMFileItem *fileItem, LMFileGroup *group) {
    NSArray<LMFileItem *> *items = group.filePaths;
    //直接判断是否有路径相同
    if ([group containsPath:fileItem.path]) {
        return YES;
    }

    //然后判断路径是否有层次关系(倒序遍历，因为可能会中途删除元素)
    for (int idx = (int) [items count] - 1; idx >= 0; idx--) {
        LMFileItem *currentItem = [items objectAtIndex:idx];

        //如果filePath是已经存在路径的子路径
        if ([currentItem.path isParentPath:fileItem.path]) {
            return YES;
        }

        //如果filePath是某文件的父路径，刚删除该文件，保留filePath
        if ([fileItem.path isParentPath:currentItem.path]) {
            [group removeItemAtIndex:idx];
        }
    }
    return NO;
}

// 通过分析plist过虑用户的沙盒文件。
// 匹配规则：plist的SandboxProfileDataValidationInfo/SandboxProfileDataValidationParametersKey/application_dyld_paths或
// SandboxProfileDataValidationInfo/SandboxProfileDataValidationParametersKey/application_bundle 是以bundlePath开头的
- (NSMutableArray *)containerFromPlist {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *containerPath = [@"~/Library/Containers" stringByExpandingTildeInPath];
    NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:containerPath error:NULL];
    for (NSString *subPath in subPaths) {
        @autoreleasepool {
            NSString *plistPath = [subPath stringByAppendingPathComponent:@"Container.plist"];
            plistPath = [containerPath stringByAppendingPathComponent:plistPath];
            NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            NSDictionary *info = plistDict[@"SandboxProfileDataValidationInfo"];
            NSDictionary *params = info[@"SandboxProfileDataValidationParametersKey"];


            NSString *dyldPath = params[@"application_dyld_paths"];
            NSString *bundlePath = params[@"application_bundle"];
            NSRange range = [dyldPath rangeOfString:self.bundlePath];
            NSRange rangeBundle = [bundlePath rangeOfString:self.bundlePath];

            // 如果是自己，忽略。因为上文已经通过匹配目录名匹配到。
            if ([bundlePath isEqualToString:self.bundlePath]) {
                continue;
            }

            if ((range.location == 0 && range.length > 0) || (rangeBundle.location == 0 && range.length > 0)) {
                [result addObject:[plistPath stringByDeletingLastPathComponent]];
                //            NSLog(@"more %@, path:%@", soft.appName, [plistPath stringByDeletingLastPathComponent]);
            }
        }
    }
    return result;
}


enum {
    kMcSearchByName = 1,
    kMcSearchByBundleID = 1 << 1,
    kMcSearchByCompany = 1 << 2,
};


-(NSString *)getMatchedNameFromXMLWithFileGroup: (LMFileGroup *)group{
    LMUninstallXMLParseManager *mananger = [LMUninstallXMLParseManager sharedManager];
    for (LMUninstallItem *item in mananger.uninstallItems) {
        if([item.bundleId isEqualToString:self.bundleID]){
            switch (group.fileType) {
                case LMFileTypeSupport:
                    return item.applicationSupportName;
                    break;
                case LMFileTypeSandbox:
                    return item.containerName;
                case LMFileTypeCache:
                    return item.cacheName;
                case LMFileTypePreference:
                    return item.preferenceName;
                case LMFileTypeLog:
                    return item.logName;
                case LMFileTypeOther:
                    return item.otherName;
                case LMFileTypeReporter:
                    return item.crashReporterName;
                case LMFileTypeDaemon:
                    return item.launchServiceName;
                default:
                    return @"";
                    break;
            }
        }
       
    }
    return @"";
}

/*
 paths:检索的目录
 options:检索方式的掩码
 suffixRegex:结尾处的正则
 所有匹配对大小写,空白均不敏感
 fileGroup: 通过判断文件类型获取XML中匹配的名称
 */
- (NSMutableArray *)searchFiles:(NSArray *)paths options:(int)options suffixRegex:(NSString *)suffixRegex fileGroup: (LMFileGroup *)group{
#ifdef DebugAppUninstallScanBySerial
    NSLog(@"%s paths:%@, option:%d, regex:%@", __FUNCTION__, paths, options, suffixRegex);
#endif
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *showName = [[self.showName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSString *bundleName = [[self.appName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
//    if([self.showName containsString:@"MacBooster"]){
//        NSLog(@"");
//    }
//    NSLog(@"bundleName : %@",bundleName);
    NSString *executableName = [[self.executableName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSString *matchBundle = [[self.bundleID stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];

    NSString *matchedNameFromXML = [self getMatchedNameFromXMLWithFileGroup:group];
    matchedNameFromXML = [[matchedNameFromXML stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    //匹配软件名称的正则表达式
    NSString *nameRegex = nil;
//    if (!executableName || [bundleName isEqualToString:executableName]) {
//        //(\\..*){0,}表示匹配XXX或XXX.*两种形式
//        nameRegex = [NSString stringWithFormat:@"\\b(%@)%@(\\..*){0,}\\b", regexEscape(bundleName), suffixRegex ? suffixRegex : @""];
//    } else

    NSString *footerRegex = @"";
    if ([suffixRegex isKindOfClass:NSString.class] && suffixRegex.length > 0) {
        footerRegex = suffixRegex;
    } else {
        footerRegex = @"(\\..*){0,}\\b";
    }
    {
        if ([matchedNameFromXML isKindOfClass:NSString.class] && matchedNameFromXML.length > 0) {
            nameRegex = [NSString stringWithFormat:@"\\b((%@)|(%@)|(%@)|(%@))%@",regexEscape(matchedNameFromXML), regexEscape(bundleName), regexEscape(executableName),regexEscape(showName), footerRegex];
        } else {
            nameRegex = [NSString stringWithFormat:@"\\b((%@)|(%@)|(%@))%@", regexEscape(bundleName), regexEscape(executableName),regexEscape(showName), footerRegex];
        }
        
    }
    NSPredicate *namePred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];

    //匹配bundleID的正则表达式
    NSString *bundleIDRegex = @"";
    if((options & kMcSearchByBundleID) && ([matchedNameFromXML isKindOfClass:NSString.class] && matchedNameFromXML.length > 0)){
        bundleIDRegex = [NSString stringWithFormat:@"\\b(\\w+\\.)?((%@)|(%@))%@", regexEscape(matchBundle),regexEscape(matchedNameFromXML), footerRegex];
    }else{
        bundleIDRegex = [NSString stringWithFormat:@"\\b(\\w+\\.)?(%@)%@", regexEscape(matchBundle), footerRegex];
    }
    NSPredicate *bundleIDPred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", bundleIDRegex];

    //对BundleID有三段的获取到公司名称
    NSString *companyName = nil;
    NSArray *bundleComponents = [self.bundleID componentsSeparatedByString:@"."];
    if (bundleComponents.count == 3) {
        companyName = bundleComponents[1];
        companyName = [[companyName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    }
    if ([self.bundleID isEqualToString:@"com.jetbrains.apps.activator"]) {
        companyName = @"jetbrains";
    }
    
    if(group.fileType == LMFileTypeSupport){
        //MacBooster在support下有两个文件夹：MacBoosterMini 和MacBoosterAB，先做特殊处理，直接添加MacBoosterAB文件夹
        if([self.appName containsString:@"MacBooster"]){
            NSString *path = [[@"~/Library/Application Support" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"MacBoosterAB"];
            BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if(isExist){
                [resultArray addObject:path];
            }
        }
    }

    for (NSString *namePath in paths) {
        NSArray *subNames = [fileManager contentsOfDirectoryAtPath:namePath error:NULL];
        for (NSString *subName in subNames) {
            
//            if([showName containsString:@"microsoftedge"] && [subName isEqualToString:@"Microsoft Edge Canary"]){
//                NSLog(@"");
//            }

            NSString *subPath = [namePath stringByAppendingPathComponent:subName];
            NSString *matchSubName = [[subName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];

            //匹配与名字相符的文件(尝试匹配两种文件名)
            if ((options & kMcSearchByName) && [namePred evaluateWithObject:matchSubName]) {
                [resultArray addObject:subPath];
                continue;
            }

            //匹配与BunldeID相符的文件(尝试匹配是否去除后缀)
            if ((options & kMcSearchByBundleID) && [bundleIDPred evaluateWithObject:matchSubName]) {
                [resultArray addObject:subPath];
                continue;
            }
            //和BundleId匹配，如果文件名中包含BundleID就匹配成功
//            if(!self.bundleID){
//                NSLog(@"%s, self.bundleID is null %@", __FUNCTION__, self.bundleID);
//                NSLog(@"%s, self.appName : %@", __FUNCTION__, self.appName);
//            }
//            NSLog(@"%s, self.bundleID : %@", __FUNCTION__, self.bundleID);
            
            
            // --bug=129758439 【lemon 官网】【线上历史问题】FinalShell 通过lemon卸载会删除本机所有后台服务
            // containsString: bundle id 过于粗暴。FinalShell 的bundle id = st。导致所有的plist文件被匹配。
            // 影响精确匹配
//            if(self.bundleID && (options & kMcSearchByBundleID) && [subName containsString:self.bundleID]){
//                [resultArray addObject:subPath];
//                continue;
//            }

            //匹配公司名目录下面与产品名字或BunldeID相同的文件
            if ((options & kMcSearchByCompany) && companyName && [matchSubName isEqualToString:companyName]) {
                NSArray *thirdSubs = [fileManager contentsOfDirectoryAtPath:subPath error:NULL];
                for (NSString *thirdItem in thirdSubs) {
                    NSString *matchThirdName = [[thirdItem stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
                    if ([namePred evaluateWithObject:matchThirdName] ||
                            [bundleIDPred evaluateWithObject:matchThirdName]
                            ) {
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

//转义正则表达中的特殊字符
NS_INLINE NSString *regexEscape(NSString *string) {
    if (string.length == 0) {
        return string;
    }

    NSMutableString *result = [string mutableCopy];
    NSArray *escapes = @[@"\\", @"/", @"|", @"{", @"}", @"(", @")", @"[", @"]", @"*", @".", @"?", @"+", @"^", @"$"];
    for (NSString *aChar in escapes) {
        NSString *escapeChar = [@"\\" stringByAppendingString:aChar];
        [result replaceOccurrencesOfString:aChar withString:escapeChar options:0 range:NSMakeRange(0, [result length])];
    }

    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    LMLocalApp *model = [[LMLocalApp allocWithZone:zone] init];
    model->_bundleID = _bundleID;
    model->_appName = _appName;
    model->_showName = _showName;
    model->_executableName = _executableName;
    model->_version = _version;
    model->_bundlePath = _bundlePath;
    model->_bundleSize = _bundleSize;
    model->_lastUsedDate = _lastUsedDate;
    model->_isScanComplete = _isScanComplete;
    model->_fileItemGroup = [NSMutableArray array];
    model->_predefinedScanner = _predefinedScanner;
    model->_pkgProvider = _pkgProvider;
    for (int i = 0; i < [_fileItemGroup count]; i++) {
        [model->_fileItemGroup addObject:[_fileItemGroup[i] copy]];
    }
    return model;
}


@end


