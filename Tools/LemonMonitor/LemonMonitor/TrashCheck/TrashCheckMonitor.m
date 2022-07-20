//
//  TrashCheckMonitor.m
//  LemonMonitor
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "TrashCheckMonitor.h"
#import <AppKit/AppKit.h>
#import <sys/stat.h>
#import "LemonDaemonConst.h"
#import <QMUICommon/SharedPrefrenceManager.h>

@implementation TrashCheckMonitor

- (NSString *)getWatchPath {
    return [@"~/.Trash" stringByExpandingTildeInPath];
}

- (NSString *)getTrashLogFile {
    NSString *path = [[@"~" stringByAppendingPathComponent:APP_SUPPORT_PATH2] stringByAppendingPathComponent:@"trashLog"];
    return [path stringByExpandingTildeInPath];
}

- (NSArray *)getOldTrashApps {
    NSArray *appTrashItem = [NSArray arrayWithContentsOfFile:[self getTrashLogFile]];
//    NSLog(@"[TrashDel] oldTrashApps: %@", appTrashItem);
    return appTrashItem;
}

- (void)saveTrashApps:(NSArray *)items {
    if (!items) {
        items = [[NSArray alloc] init];
    }
    
    if (items) {
        NSString *trashLog = [self getTrashLogFile];
//        NSLog(@"[TrashDel] wrtieTrashLog %@", trashLog);
        [items writeToFile:trashLog atomically:YES];
    }
}

- (NSArray *)getTrashApps {
    NSString *trashPath = [self getWatchPath];
    NSArray *trashItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trashPath error:nil];
//    NSLog(@"[TrashDel] trashItems:%@", trashItems);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.app' "];
    NSArray *appTrashItems = [trashItems filteredArrayUsingPredicate:predicate];
    return appTrashItems;
}

-(BOOL)isTrashItemsChanged{
    NSInteger oldTrashSize = [SharedPrefrenceManager getInteger:OLD_TRASH_SIZE];
    NSLog(@"%s,old trash size : %ld",__FUNCTION__, (long)oldTrashSize);
    NSString *trashPath = [self getWatchPath];
    NSArray *trashItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trashPath error:nil];
    NSInteger newTrashSize = trashItems.count;
    NSLog(@"%s,new trash size : %ld",__FUNCTION__, (long)newTrashSize);
    [SharedPrefrenceManager putInteger:newTrashSize withKey:OLD_TRASH_SIZE];
    if(newTrashSize > oldTrashSize)
        return YES;
    return NO;
}



//检测是否系统重新命名的文件
//如果移到垃圾桶时有相同的文件，会将旧的重命名，在后面加上时间，例如 xxxx.app会变成 xxxx 下午1.30.23.app
//这样检测出来的实际上就是旧的重命名后的app

// 这里的判断不准:原因: 1.不同系统下样式不同. 2.时间字符串的长度不同.(长度为7或者8)
//       DerivedData 下午8.53.20
//       NetworkExtension 15.04.30 PM.app
//
- (BOOL) isSystemRenameFileName:(NSString *)fileName {
    NSString *name = [self removeAppExtensionOf:fileName];
    NSInteger len = [name length];
    // pattern like "1.12.30"
    if (len <= 7) {
        return NO;
    }
    NSString *endStr = [name substringFromIndex:len - 7];
//    NSLog(@"[TrashDel] %s endstr:%@", __FUNCTION__, endStr);
    NSString *regx = @"\\d\\.\\d\\d\\.\\d\\d";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regx];
    BOOL isMatch = [pred evaluateWithObject:endStr];
//    NSLog(@"[TrashDel] %s fileName: %@, match:%d", __FUNCTION__, fileName, isMatch);
    return isMatch;
}

- (NSString *)truncTimeStrFromName:(NSString *)fileName {
    if (![self isSystemRenameFileName:fileName])
        return fileName;
    NSString *name = [self removeAppExtensionOf:fileName];
    
    NSArray *strArray = [name componentsSeparatedByString:@" "];
    NSString *nameWithOutTime = @"";
    if ([strArray count] == 1) {
        nameWithOutTime = name;
    } else {
        for (int i = 0; i < [strArray count] - 1; i++) {
            nameWithOutTime = [nameWithOutTime stringByAppendingString:strArray[i]];
        }
    }
    
    NSString* ret = [self appendAppExtensionTo:nameWithOutTime];
    
    NSLog(@"[TrashDel] %s, return str:%@", __FUNCTION__, ret);
    return ret;
}



- (NSString *)removeAppExtensionOf:(NSString *)fileName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.app' "];
    BOOL isEndWithApp = [predicate evaluateWithObject:fileName];
    if (isEndWithApp) {
        return [fileName substringToIndex:[fileName length] - 4];
    }
    return fileName;
}

- (NSString *)appendAppExtensionTo:(NSString *)appName {
    return [appName stringByAppendingString:@".app"];
}


// 找出最新的删除 App.
- (NSArray *)getNewTashApps {
    NSLog(@"%s", __FUNCTION__);
    NSArray *oldTrashApps = [self getOldTrashApps];  //写在 ~/Library/Application Support/com.tencent.Lemon/trashLog
    
    NSArray *curTrashApps = [self getTrashApps];
    [self saveTrashApps:curTrashApps];
    //oldTrashApps为nil, 代表应用刚启动第一次检测，所以直接返回nil
    // oldTrashApps为大小为0的array，代表上一次检测垃圾桶里没有app
    if (!oldTrashApps) {
        NSLog(@"%s oldTrash is nil, stop scan", __FUNCTION__);
        return nil;
    }else{
        NSLog(@"%s oldTrash Apps is \n %@", __FUNCTION__,  [oldTrashApps componentsJoinedByString:@",  "]);
        if(curTrashApps){
            NSLog(@"%s nowTrash Apps is \n %@", __FUNCTION__,  [curTrashApps componentsJoinedByString:@",  "]);
        }
    }
    NSMutableArray *newApps = [[NSMutableArray alloc] init];
    
    NSMutableArray<NSString*> *oldTrashContainsApps = [NSMutableArray array];
    for (NSString *newItem in curTrashApps) {
        
        // 过滤老应用
        if ([oldTrashApps containsObject:newItem]) {
            [oldTrashContainsApps addObject:newItem];
            continue;
        }
        
        NSString *appPath = [[self getWatchPath] stringByAppendingPathComponent:newItem];
        NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
        
        if (!appBundle || !appBundle.bundleIdentifier) {
            NSLog(@"%s stop uninstall this app:%@ is valid, appBundle is %@", __FUNCTION__, newItem, appBundle);
            continue;
        }
        
        if ([appBundle.bundleIdentifier hasPrefix:@"com.apple."]
            || [appBundle.bundleIdentifier hasPrefix:MAIN_APP_BUNDLEID]
            || [appBundle.bundleIdentifier hasPrefix:MONITOR_APP_BUNDLEID])
        {
            NSLog(@"%s stop uninstall this type app:%@, id:%@ ", __FUNCTION__, newItem, appBundle.bundleIdentifier);
            continue;
        }
        
        // 当该bundleID的软件仍然在运行，不处理
        NSArray *runApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:appBundle.bundleIdentifier];
        if (runApps.count > 0){
            NSLog(@"%s stop uninstall this app:%@, id:%@ because still running", __FUNCTION__, newItem, appBundle.bundleIdentifier);
            continue;
        }
        

        // 当还安装有同bundleID的软件(且未被删除)，不处理 =>注意有些 DMG 挂载后,会生成 /Volumes/xxxx/abc.app 这种情形下abc.app删除时不应该算还存在其
        //osascript -e "POSIX path of (path to application id \"com.iqiyi.player \")" 可以用shell的命令获取此 bundleId 的软件的安装位置.
        NSString *otherPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:appBundle.bundleIdentifier];
        NSPredicate *dmgPathPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", @"/Volumes/[^/]*/[^/]*[.]app"];
        if (otherPath
            &&![otherPath hasPrefix:[self getWatchPath]]
              && ![dmgPathPredicate evaluateWithObject:otherPath]){
            NSLog(@"%s stop uninstall this app:%@, id:%@ because have other app at: %@", __FUNCTION__, newItem, appBundle.bundleIdentifier, otherPath);
            continue;
        }
        
        NSString *trashPath = [self getWatchPath];
        NSURL *itemUrl = [[NSURL alloc]initFileURLWithPath:[trashPath stringByAppendingPathComponent:newItem]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:[itemUrl path]]){
            NSLog(@"%s file not exist %@ ", __FUNCTION__, newItem);
            continue;
        }
        [newApps addObject:newItem];
//        struct stat fileStat;
//        if (lstat([itemUrl fileSystemRepresentation], &fileStat) == noErr){
//            struct timespec atime = fileStat.st_atimespec;
//
//            NSTimeInterval now = [[[NSDate alloc] init] timeIntervalSince1970];
//            if( fabs(now - atime.tv_sec) < 10){
//                [newApps addObject:newItem];
//            }else{
//                NSLog(@"%s file %@ ctime changed over 10s ,now is %f, atime is %ld", __FUNCTION__, [itemUrl path] , now, (long)atime.tv_sec);
//            }
//        }else{
//             NSLog(@"%s lstat() called error", __FUNCTION__);
//        }
    }
    
    if(oldTrashContainsApps.count > 0){
        NSLog(@"oldTrashContainsApps:%@", [oldTrashContainsApps componentsJoinedByString:@", "]);
    }
    return newApps;
    
}


@end
