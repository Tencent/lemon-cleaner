//
//  AppTrashDel.m
//  LemonMonitor
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "AppTrashDel.h"
#import "LmTrashWatchUninstallWindowController.h"
#import "LemonDaemonConst.h"
#import "LMLocalApp.h"
#import "LMLocalAppListManager.h"
#import "LMTrashAppIdentity.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <AppKit/AppKit.h>

#ifndef IS_ENABLE_TRASH_WATCH
#define IS_ENABLE_TRASH_WATCH @"enable_trash_watch"
#endif

@interface AppTrashDel() <McUninstallWindowControllerDelegate>{
    dispatch_queue_t checkQueue;
    NSMutableArray<LmTrashWatchUninstallWindowController*> *uninstallWndControllers;
}     

@end

@implementation AppTrashDel

// 只是启动 监听 plist,plist 启动时会通知 Daemon, Daemon以普通权限启动,然后利用全局通知通知 Monitor(或 Lemon)启动卸载残留弹窗. (收到通知的间隔可能比较长)
+ (BOOL)enableTrashWatch:(BOOL)isEnable{
    NSLog(@"%s, enable:%d", __FUNCTION__, isEnable);
    NSString *cmd = nil;
    NSString *plistDstPath = [[@"~" stringByAppendingPathComponent:TRASH_MONITOR_LAUNCHD_PATH] stringByExpandingTildeInPath];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (isEnable) {
        
        NSString *srcPath = [DEFAULT_APP_PATH stringByAppendingPathComponent:@"Contents/Resources"];
        srcPath = [srcPath stringByAppendingPathComponent:[TRASH_MONITOR_LAUNCHD_PATH lastPathComponent]];

        [fileMgr removeItemAtPath:plistDstPath error:nil];
        
        NSMutableDictionary *trashMonitorConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:srcPath];
        
        NSString *userTrashPath = [@"~/.Trash" stringByExpandingTildeInPath];
        [trashMonitorConfig setObject:@[userTrashPath] forKey:@"WatchPaths"];
        
        // 检查~/Library/LaunchAgents文件夹是否存在
        NSString *userLaunchAgentsPath = [@"~/Library/LaunchAgents" stringByExpandingTildeInPath];
        if (![fileMgr fileExistsAtPath:userLaunchAgentsPath]) {
            // 创建文件夹
            NSError *error = nil;
            [fileMgr createDirectoryAtPath:userLaunchAgentsPath withIntermediateDirectories:NO attributes:nil error:&error];
            
            if (error) {
                NSLog(@"create userLaunchAgentsPath: %@", error.localizedDescription);
            }
        }
        
        if (![trashMonitorConfig writeToFile:plistDstPath atomically:NO]) {
            NSLog(@"trash plist write to ~/Library/LaunchAgents/com.tencent.Lemon.trash.plist failed: dstPath:%@, src path is %@", plistDstPath, srcPath);
            NSLog(@"print  trashMonitorConfig ....");
            for(NSString *key in [trashMonitorConfig allKeys]) {
                NSLog(@"%@",[trashMonitorConfig objectForKey:key]);
            }
            return NO;
        }
        
        if(![fileMgr fileExistsAtPath:plistDstPath]){
            NSLog(@"after write,but plist not exist ");
            return NO;
        }

        cmd = [NSString stringWithFormat:@"launchctl load -w %@", plistDstPath];
        int ret = system([cmd UTF8String]);
        NSLog(@"[TraskWatch] load failed : %d", ret);
        if (0 != ret) {
            cmd = [NSString stringWithFormat:@"launchctl bootstrap gui/501 %@", plistDstPath];
            ret = system([cmd UTF8String]);
            NSLog(@"[TraskWatch] bootstrap result : %d", ret);
        }
    } else {
        cmd = [NSString stringWithFormat:@"launchctl remove %@", TRASH_MONITOR_LAUNCHD_LABLE];
        system([cmd UTF8String]);
        [fileMgr removeItemAtPath:plistDstPath error:nil];
    }
    
    return YES;
}

#pragma mark - check trash watcher enable

+ (BOOL)isTrashWatcherEnable {
    NSString *cmd = [NSString stringWithFormat:@"launchctl list | grep '%@'", TRASH_MONITOR_LAUNCHD_LABLE];
    NSString *retString = [QMShellExcuteHelper excuteCmd:cmd];
    if (retString == nil || [retString isEqualToString:@""]) {
        return NO;
    }
    return YES;
}

+ (void)keepTrashWatcherAlive {
    if (![self isTrashWatcherEnable]) {
        NSLog(@"[TraskWatch] trask watcher disable");
        [self enableTrashWatch:YES];
    }
}

//+ (BOOL)enableTrashWatchFromMonitor:(BOOL)isEnable{
//    NSLog(@"%s, enable:%d", __FUNCTION__, isEnable);
//    NSString *cmd = nil;
//    NSString *plistDstPath = [[@"~" stringByAppendingPathComponent:TRASH_MONITOR_LAUNCHD_PATH_FROM_MONITOR] stringByExpandingTildeInPath];
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    if (isEnable) {
//
//        NSString *srcPath = [DEFAULT_APP_PATH stringByAppendingPathComponent:@"Contents/Resources"];
//        srcPath = [srcPath stringByAppendingPathComponent:[TRASH_MONITOR_LAUNCHD_PATH_FROM_MONITOR lastPathComponent]];
//
//        [fileMgr removeItemAtPath:plistDstPath error:nil];
//
//        NSMutableDictionary *trashMonitorConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:srcPath];
//
//        NSString *userTrashPath = [@"~/.Trash" stringByExpandingTildeInPath];
//        [trashMonitorConfig setObject:@[userTrashPath] forKey:@"WatchPaths"];
//        if (![trashMonitorConfig writeToFile:plistDstPath atomically:NO]) {
//            NSLog(@"trash plist write to ~/Library/LaunchAgents/com.tencent.Lemon.monitor.trash.plist MONITOR Monitor failed: dstPath:%@, src path is %@", plistDstPath, srcPath);
//            NSLog(@"print  trashMonitorConfig ....");
//            for(NSString *key in [trashMonitorConfig allKeys]) {
//                NSLog(@"%@",[trashMonitorConfig objectForKey:key]);
//            }
//            return NO;
//        }
//
//        if(![fileMgr fileExistsAtPath:plistDstPath]){
//            NSLog(@"after write,but plist not exist ");
//            return NO;
//        }
//
//        cmd = [NSString stringWithFormat:@"launchctl load  %@", plistDstPath];
//        system([cmd UTF8String]);
//    } else {
//        cmd = [NSString stringWithFormat:@"launchctl remove %@", TRASH_MONITOR_LAUNCHD_LABLE_FROM_MONITOR];
//        system([cmd UTF8String]);
//        [fileMgr removeItemAtPath:plistDstPath error:nil];
//    }
//    return YES;
//}

- (instancetype)init
{
    self = [super init];
    if (self) {
        checkQueue = dispatch_queue_create("checkQueue", NULL);
    }
    return self;
}

- (NSString *)resolvedTrashDirectory {
    NSString *trashPath = [@"~/.Trash" stringByExpandingTildeInPath];
    return [[trashPath stringByStandardizingPath] stringByResolvingSymlinksInPath];
}

- (BOOL)isDirectTrashItemName:(NSString *)item {
    if (![item isKindOfClass:[NSString class]] || item.length == 0) {
        return NO;
    }
    if ([item hasPrefix:@"/"] || [item containsString:@"/"]) {
        return NO;
    }
    if ([item isEqualToString:@"."] || [item isEqualToString:@".."]) {
        return NO;
    }
    return YES;
}

- (NSString *)resolvedSafeTrashAppPathForItem:(NSString *)item {
    if (![self isDirectTrashItemName:item]) {
        return nil;
    }
    NSString *trashDir = [self resolvedTrashDirectory];
    NSString *joined = [[@"~/.Trash" stringByExpandingTildeInPath] stringByAppendingPathComponent:item];
    NSString *resolved = [[joined stringByStandardizingPath] stringByResolvingSymlinksInPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:resolved]) {
        return nil;
    }
    NSString *parent = [resolved stringByDeletingLastPathComponent];
    if (![parent isEqualToString:trashDir]) {
        NSLog(@"delTrashOfApps skip item not remaining a trash direct child: %@ -> %@", item, resolved);
        return nil;
    }
    return resolved;
}

- (BOOL)isTrashWatchPreferenceDisabled {
    // 与发送侧 Tools/LemonMonitor/LemonMonitor/main.m trashCheck 同一语义：
    // SharedPrefrenceManager getBool 在 key 缺失时为 NO，视为关闭，避免伪造通知绕过开关。
    return ![SharedPrefrenceManager getBool:IS_ENABLE_TRASH_WATCH];
}

- (BOOL)shouldSkipProtectedBundleID:(NSString *)bundleID {
    if (bundleID.length == 0) {
        return YES;
    }
    if ([bundleID hasPrefix:@"com.apple."]
        || [bundleID hasPrefix:MAIN_APP_BUNDLEID]
        || [bundleID hasPrefix:MONITOR_APP_BUNDLEID]
        || [bundleID hasPrefix:@"com.tencent.TeamSecurityManager"]) {
        return YES;
    }
    return NO;
}

- (BOOL)pathIsInstalledOutsideTrash:(NSString *)path trashDir:(NSString *)trashDir {
    if (path.length == 0 || trashDir.length == 0) {
        return NO;
    }
    NSString *resolved = [[path stringByStandardizingPath] stringByResolvingSymlinksInPath];
    NSPredicate *dmgPathPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", @"/Volumes/[^/]*/[^/]*[.]app"];
    if ([resolved hasPrefix:trashDir]) {
        return NO;
    }
    if ([dmgPathPredicate evaluateWithObject:resolved]) {
        return NO;
    }
    return YES;
}

- (BOOL)isBundleStillInstalledByLaunchServices:(NSString *)bundleID trashDir:(NSString *)trashDir {
    if (bundleID.length == 0) {
        return NO;
    }
    NSString *otherPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    return [self pathIsInstalledOutsideTrash:otherPath trashDir:trashDir];
}

- (BOOL)isNameStillInstalledByWorkspace:(LMTrashAppIdentity *)claimed trashDir:(NSString *)trashDir {
    NSArray *names = @[
        claimed.appName ?: @"",
        claimed.executableName ?: @"",
        claimed.showName ?: @""
    ];
    NSMutableSet *seen = [NSMutableSet set];
    for (NSString *name in names) {
        if (name.length == 0 || [seen containsObject:name]) {
            continue;
        }
        [seen addObject:name];
        // fullPathForApplication: 已 deprecated，用于补卸载枚举不含 Apple/Lemon 时的名字维。
        // 删除后仍有 LMTrashInstalledMatch 的 name 维（仅覆盖五目录枚举到的应用）兜底。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:name];
#pragma clang diagnostic pop
        if ([self pathIsInstalledOutsideTrash:path trashDir:trashDir]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<LMTrashAppIdentity *> *)installedIdentitiesForTrashSkip {
    LMLocalAppListManager *manager = [LMLocalAppListManager defaultManager];
    NSArray<LMLocalApp *> *apps = manager.appsList;
    if (apps.count == 0) {
        apps = [manager enumLocalAppsWithPath];
    }
    NSMutableArray<LMTrashAppIdentity *> *identities = [NSMutableArray array];
    NSString *trashDir = [self resolvedTrashDirectory];
    for (LMLocalApp *app in apps) {
        if (![app isKindOfClass:[LMLocalApp class]]) {
            continue;
        }
        if (app.bundlePath.length > 0 && [app.bundlePath hasPrefix:trashDir]) {
            continue;
        }
        [identities addObject:[LMTrashAppIdentity identityWithBundleID:app.bundleID
                                                               appName:app.appName
                                                       executableName:app.executableName
                                                             showName:app.showName]];
    }
    return identities;
}

- (BOOL)shouldSkipTrashItemAtPath:(NSString *)appPath
                           bundle:(NSBundle *)appBundle
              installedIdentities:(NSArray<LMTrashAppIdentity *> *)installedIdentities {
    NSString *bundleID = appBundle.bundleIdentifier;
    if ([self shouldSkipProtectedBundleID:bundleID]) {
        NSLog(@"delTrashOfApps skip protected bundle %@", bundleID);
        return YES;
    }
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID].count > 0) {
        NSLog(@"delTrashOfApps skip still running %@", bundleID);
        return YES;
    }
    NSString *trashDir = [self resolvedTrashDirectory];
    if ([self isBundleStillInstalledByLaunchServices:bundleID trashDir:trashDir]) {
        NSLog(@"delTrashOfApps skip still installed by LaunchServices %@", bundleID);
        return YES;
    }
    LMLocalApp *claimedApp = [[LMLocalApp alloc] initWithPath:appPath];
    LMTrashAppIdentity *claimed = [LMTrashAppIdentity identityWithBundleID:claimedApp.bundleID ?: bundleID
                                                                   appName:claimedApp.appName
                                                           executableName:claimedApp.executableName
                                                                 showName:claimedApp.showName];
    if ([self isNameStillInstalledByWorkspace:claimed trashDir:trashDir]) {
        NSLog(@"delTrashOfApps skip still installed by application name %@", claimed.appName);
        return YES;
    }
    if ([LMTrashInstalledMatch claimedIdentity:claimed matchesInstalled:installedIdentities]) {
        NSLog(@"delTrashOfApps skip identity matches installed app %@", bundleID);
        return YES;
    }
    return NO;
}

- (void)delTrashOfApps:(NSArray *)apps {
    if ( [apps count] == 0)
        return;
    if ([self isTrashWatchPreferenceDisabled]) {
        NSLog(@"delTrashOfApps skip because trash watch preference disabled");
        return;
    }
    
    dispatch_async(checkQueue, ^{
        NSArray<LMTrashAppIdentity *> *installedIdentities = [self installedIdentitiesForTrashSkip];
        NSMutableArray<LMLocalApp *> *appTrashs = [[NSMutableArray alloc] init];
        for (NSString *appItem in apps) {
            NSString *appPath = [self resolvedSafeTrashAppPathForItem:appItem];
            if (!appPath) {
                NSLog(@"delTrashOfApps skip unsafe trash item %@", appItem);
                continue;
            }
            
            NSTimeInterval now = [[[NSDate alloc]init] timeIntervalSince1970];
            NSLog(@"delTrashOfApps start to scan %@ trash leftover, start time is %f ", appPath, now);
            NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
            if (!appBundle || !appBundle.bundleIdentifier){
                NSLog(@"delTrashOfApps %@ no need show scan result because appBundle or identifier not valid", appPath );
                continue;
            }
            if ([self shouldSkipTrashItemAtPath:appPath bundle:appBundle installedIdentities:installedIdentities]) {
                continue;
            }
            
            LMLocalApp *localSoft = [[LMLocalApp alloc] initWithPath:appPath];
            if (!localSoft){
                NSLog(@"delTrashOfApps %@ no need show scan result because can't init LMLocalApp ", appPath);
                continue;
            }
            [localSoft scanFileItems:AppTrashLeftover];
            if ([localSoft fileItemCount] < 1){
                NSLog(@"delTrashOfApps %@ no need show scan result because no trash leftover ", appPath);
                continue;
            }
            [appTrashs addObject:localSoft];
        }
        
        if (appTrashs.count > 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showUninstaller:appTrashs];
                NSTimeInterval showTime = [[[NSDate alloc]init] timeIntervalSince1970];
                NSArray *appBundles = [appTrashs valueForKey:@"bundleID"];
                NSLog(@"delTrashOfApps end scan trash leftover, end time is %f , show apps is %@", showTime , [appBundles componentsJoinedByString:@","]);

            });
        }
    });
}

- (void)showUninstaller:(NSArray<LMLocalApp *> *)softs
{
    if (!uninstallWndControllers)
    {
        uninstallWndControllers  = [NSMutableArray array];
    }
    
    for(LMLocalApp *itemApp in softs){
        LmTrashWatchUninstallWindowController *uninstallWndController = [[LmTrashWatchUninstallWindowController alloc] init];
        [uninstallWndControllers addObject:uninstallWndController];
        
        uninstallWndController.delegate = self;
        uninstallWndController.soft = itemApp;
        [uninstallWndController show];
    }
}

#pragma mark - McUninstallWindowControllerDelegate

- (void)uninstallFinished:(id)sender
{
    if([sender isKindOfClass:LmTrashWatchUninstallWindowController.class]){
        LmTrashWatchUninstallWindowController *uninstallFinshWindow = sender;
        [uninstallWndControllers removeObject:uninstallFinshWindow];
    }
}

@end
