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
#import <QMCoreFunction/QMShellExcuteHelper.h>

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

- (void)delTrashOfApps:(NSArray *)apps {
    if ( [apps count] == 0)
        return;
    
    dispatch_async(checkQueue, ^{
        NSString *trashPath = [@"~/.Trash" stringByExpandingTildeInPath];
        NSMutableArray<LMLocalApp *> *appTrashs = [[NSMutableArray alloc] init];
        for (NSString *appItem in apps) {
            NSString *appPath = [trashPath stringByAppendingPathComponent:appItem];
            
            NSTimeInterval now = [[[NSDate alloc]init] timeIntervalSince1970];
            NSLog(@"delTrashOfApps start to scan %@ trash leftover, start time is %f ", appPath, now);
            NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
            if (!appBundle || !appBundle.bundleIdentifier){
                NSLog(@"delTrashOfApps %@ no need show scan result because appBundle or identifier not valid", appPath );
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
