//
//  McUninstallSoft.m
//  QMUnintallDemo
//
//  
//  Copyright (c) 2013年 haotan. All rights reserved.
//

#import "McUninstallSoft.h"
#import "NSArray+Extension.h"
#import "NSString+Extension.h"
#import "McCoreFunction.h"
#import "QMSafeMutableArray.h"
#import "QMSoftwareConfigConst.h"

@interface McUninstallSoft ()
{
    McSoftwareFileType removingType;
}
@property (nonatomic, strong) McLocalSoft *localSoft;
@end

NSString *McUninstallSoftStateNotification = @"McUninstallSoftStateNotification";
NSString *McUninstallSoftFileSizeKey = @"McUninstallSoftFileSizeKey";
NSString *McUninstallSoftProgress = @"McUninstallSoftProgress";
NSString *McUninstallSoftPathKey = @"McUninstallSoftPathKey";

@implementation McUninstallSoft
@synthesize localSoft;
@synthesize items;

+ (id)uninstallSoftWithSoft:(McLocalSoft *)localsoft
{
    McUninstallSoft *uninstallerSoft = [[self alloc] init];
    uninstallerSoft.localSoft = localsoft;
    
    McSoftwareFileScanner *scanner = [McSoftwareFileScanner scannerWithSoft:localsoft];
    [scanner start];
    uninstallerSoft.items = scanner.items;
    return uninstallerSoft;
}

+ (id)uninstallSoftWithPath:(NSString *)filePath
{
    McLocalSoft *localsoft = [McLocalSoft softWithPath:filePath];
    if (!localsoft)
    {
        return nil;
    }
    
    return [self uninstallSoftWithSoft:localsoft];
}

- (NSArray *)flatItems {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (McUninstallItemTypeGroup *group in items)
    {
        [array addObjectsFromArray:group.items];
    }
    return array;

}

- (uint64_t)size
{
    uint64_t totalSize = 0;
    for (McUninstallItemTypeGroup *group in items)
    {
        for (McSoftwareFileItem *fileItem in group.items) {
            if (fileItem.type != McSoftwareFileOther)
                totalSize += fileItem.fileSize;
        }
    }
    return totalSize;
}

- (NSDate *)modifyDate
{
    return localSoft.modifyDate;
}

- (NSDate *)createDate
{
    return localSoft.createDate;
}

- (NSString *)showName
{
    return localSoft.showName;
}

- (NSString *)bundleID
{
    return localSoft.bundleID;
}

- (NSString *)version
{
    return localSoft.version;
}

- (NSImage *)icon
{
    return localSoft.icon;
}

- (McLocalType)type
{
    return localSoft.type;
}

- (void)appendItem:(id)item
{
    if ([item isKindOfClass:[NSArray class]])
    {
        for (id subItem in item)
        {
            [self appendItem:subItem];
        }
    }
    else if ([item isKindOfClass:[McUninstallSoft class]])
    {
        McUninstallSoft *uninstallSoft = item;
        [self appendItem:uninstallSoft.localSoft];
        [self appendItem:uninstallSoft.items];
    }
    else if ([item isKindOfClass:[NSString class]])
    {
        NSString *filePath = item;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            McSoftwareFileItem *fileItem = [McSoftwareFileItem itemWithPath:filePath];
            fileItem.type = McSoftwareFileUnname;
            [self appendItem:fileItem];
        }
    }
    else if ([item isKindOfClass:[McLocalSoft class]])
    {
        McLocalSoft *newLocalSoft = item;
        
        McSoftwareFileItem *fileItem = [McSoftwareFileItem itemWithPath:newLocalSoft.bundlePath];
        fileItem.type = McSoftwareFileBundle;
        [self appendItem:fileItem];
        
        //版本更高的bundle为localSoft
        if ([localSoft.bundleID isEqualToString:newLocalSoft.bundleID] && [localSoft compareVersion:item] == NSOrderedAscending)
        {
            localSoft = item;
        }
    }
    else if ([item isKindOfClass:[McSoftwareFileItem class]])
    {
        McSoftwareFileItem *newItem = item;
//        NSMutableArray *currentItems = items?[items mutableCopy]:[NSMutableArray array];
//        for (int i = (int)[currentItems count]-1; i >= 0 ; i--)
//        {
//            McUninstallSoftGroup *groupItem = [items objectAtIndex:i];
//            if (groupItem.type == newItem.type)
//            {
//                for (int j = (int)[groupItem.items count] -1; j >= 0; j--) {
//                    McSoftwareFileItem *curItem = [groupItem.items objectAtIndex:j];
//                    if ([curItem.filePath isEqualToString:newItem.filePath] || [curItem.filePath isParentPath:newItem.filePath])
//                    {
//                        return;
//                    }
//                    else if ([newItem.filePath isParentPath:curItem.filePath])
//                    {
//                        [groupItem.items removeObjectAtIndex:j];
//                        continue;
//                    }
//                }
//            }
//        }
//        [currentItems addObject:newItem];
//        self.items = [[NSArray alloc] initWithArray:currentItems];
        for (McUninstallItemTypeGroup *groupItem in items) {
            if (groupItem.fileType == newItem.type) {
                for (int i = (int)[groupItem.items count]-1; i >= 0 ; i--) {
                    McSoftwareFileItem *curItem = [groupItem.items objectAtIndex:i];
                    if ([curItem.filePath isEqualToString:newItem.filePath] || [curItem.filePath isParentPath:newItem.filePath])
                    {
                        return;
                    }
                    else if ([newItem.filePath isParentPath:curItem.filePath])
                    {
                        [groupItem.items removeObjectAtIndex:i];
                        continue;
                    }
                }
                [groupItem.items addObject:newItem];
                return;
            }
        }
    }
}

/*
 返回文件类型表示当前正在删除该类文件,
 McUninstallRemovingNone表示目前没有删除任何文件,
 McUninstallRemoveFinished表示已经卸载完成
 */
- (McSoftwareFileType)removingType
{
    return removingType;
}

////删除关联文件
//- (void)removeItems:(NSArray *)array :(void(^)(double progress))progressHandler :(void(^)(BOOL removeAll))finishHandler
//{
//    dispatch_queue_t inQueue = dispatch_get_current_queue();
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        uint64_t removeSize = 0;
//
//        //将需要删除的文件按类型分组
//        NSMutableDictionary *removeInfo = [[NSMutableDictionary alloc] init];
//        for (McSoftwareFileItem *item in array)
//        {
//            id typeKey = @(item.type);
//            NSMutableArray *typeArray = [removeInfo objectForKey:typeKey];
//            if (!typeArray)
//            {
//                typeArray = [[NSMutableArray alloc] init];
//                [removeInfo setObject:typeArray forKey:typeKey];
//            }
//            [typeArray addObject:item];
//            removeSize += item.fileSize;
//        }
//
//        //逐项删除并通知代理
//        double progress = 0;
//        for (McSoftwareFileType type = McSoftwareFileBundle;type <= McSoftwareFileOther;type++)
//        {
//            NSDate *beginDate = [NSDate date];
//            id typeKey = @(type);
//            NSMutableArray *typeArray = [removeInfo objectForKey:typeKey];
//            if (typeArray)
//            {
//                //设置当前正在删除的类型,更新进度
//                removingType = type;
//                progress += typeArray.count*1.0/array.count;
//
//                //完成删除动作
//                for (McSoftwareFileItem *fileItem in typeArray)
//                {
//                    if (type==McSoftwareFileBundle)
//                        [self killItemProcess:fileItem];
//                    if (type==McSoftwareFileDaemon)
//                        [self launchUnloadItem:fileItem];
//
//                    [[McCoreFunction shareCoreFuction] cleanItemAtPath:fileItem.filePath array:nil removeType:McCleanRemoveRoot];
//
//                    //在主线通知代理进度，并发送通知
//                    dispatch_sync(inQueue, ^{
//                        if (progressHandler) progressHandler(progress);
//                        [self postNotification:@{McUninstallSoftProgress: @(progress),
//                                                 McUninstallSoftPathKey: fileItem.filePath
//                                                 }];
//                    });
//                }
//
//                //更新变量
//                items = [items arrayByRemoveObjectsFromArray:typeArray];
//                [removeInfo removeObjectForKey:typeKey];
//
//                while ([beginDate timeIntervalSinceNow] > -0.5)
//                {
//                    usleep(1000*100);
//                }
//            }
//        }
//
//        //删除登录项和Dock图标
//        [self removeLoginitems:array];
//        [self removeIconFromDock:array];
//
//        //判定删除是否完全被卸载了(根据主程序还否还存在)
//        BOOL removeAll = YES;
//        for (McSoftwareFileItem *item in items)
//        {
//            if (item.type == McSoftwareFileBundle)
//            {
//                removeAll = NO;
//                break;
//            }
//        }
//        removingType = removeAll?McUninstallRemoveFinished:McUninstallRemovingNone;
//
//        //在主线通知回调结束,并发送状态通知
//        dispatch_async(inQueue, ^{
//            if (finishHandler) finishHandler(removeAll);
//            [self postNotification:@{McUninstallSoftFileSizeKey: @(removeSize),McUninstallSoftProgress:@(1.0)}];
//        });
//    });
//}

- (void)delSelectedItems:(void(^)(double progress))progressHandler :(void(^)(BOOL removeAll))finishHandler
{
//    dispatch_queue_t inQueue = dispatch_get_current_queue();
    NSLog(@"uninstall %s, %d", __FUNCTION__, __LINE__);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        uint64_t removeSize = 0;
        
        //让进度条尽快显示
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postNotification:@{McUninstallSoftProgress:@(0.0)}];
        });
//        NSLog(@"uninstall %s, %d", __FUNCTION__, __LINE__);
        NSMutableArray *selectedItems = [[NSMutableArray alloc] init];
        for (McUninstallItemTypeGroup *group in self.items) {
            for (McSoftwareFileItem *fileItem in group.items) {
                if (fileItem.isSelected) {
                    removeSize += fileItem.fileSize;
                    [selectedItems addObject:fileItem];
                }
            }
        }
//        NSLog(@"uninstall %s, %d", __FUNCTION__, __LINE__);
        
        //逐项删除并通知代理
        double progress = 0;
        NSMutableArray *removedItems = [[NSMutableArray alloc] init];
        for (McUninstallItemTypeGroup *group in self.items){
            NSDate *beginDate = [NSDate date];
            [removedItems removeAllObjects];
            // 完成删除动作
            for (McSoftwareFileItem *fileItem in group.items) {
                if (!fileItem.isSelected) {
                    continue;
                }
                if (fileItem.type==McSoftwareFileBundle)
                    [self killItemProcess:fileItem];
                if (fileItem.type==McSoftwareFileDaemon)
                    [self launchUnloadItem:fileItem];
                
                //在主线通知代理进度，并发送通知
//                NSLog(@"uninstall %s, %d progress:%f", __FUNCTION__, __LINE__, progress);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (progressHandler) progressHandler(progress);
                    [self postNotification:@{McUninstallSoftProgress: @(progress),
                                             McUninstallSoftPathKey: fileItem.filePath
                                             }];
                });
                
                [[McCoreFunction shareCoreFuction] cleanItemAtPath:fileItem.filePath array:nil removeType:McCleanRemoveRoot];
                progress +=  1.0 / selectedItems.count;
 
                [removedItems addObject:fileItem];
            }
            
            //更新变量
            [group.items removeObjectsInArray:(NSArray *)removedItems];
            while ([beginDate timeIntervalSinceNow] > -0.5 && [self.items lastObject] != group)
            {
                usleep(1000*100);
            }
            
        }
        
        [removedItems removeAllObjects];
        for (McUninstallItemTypeGroup *group in self.items){
            if ([group.items count] == 0) {
                [removedItems addObject:group];
            }
        }
        self.items = [self.items arrayByRemoveObjectsFromArray:removedItems];
        
        //删除登录项和Dock图标
        //由于内部LSSharedFileListCreate方法，在10.11以后的系统已经不支持，苹果也没有给替换的解决方案，故去除该点
        //[self removeLoginitems:selectedItems];
        [self removeIconFromDock:selectedItems];
        
        //判定删除是否完全被卸载了(根据主程序还否还存在)
        BOOL removeAll = YES;
        for (McUninstallItemTypeGroup *group in self.items)
        {
            if (group.fileType == McSoftwareFileBundle)
            {
                removeAll = NO;
                break;
            }
        }
        
        //先显示到99%，再发送完成通知如果直接发送1，进度条可能看不到走满就消失，一般情况下不影响体验，但当只有一个删除项时
        // 进度条会从0直接消失。
//        NSLog(@"uninstall %s, %d progress:%f", __FUNCTION__, __LINE__, @(0.99));
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postNotification:@{McUninstallSoftFileSizeKey: @(removeSize),McUninstallSoftProgress:@(0.99)}];
        });
        usleep(1000*100);
        
        self->removingType = removeAll ?McUninstallRemoveFinished:McUninstallRemovingNone;
        //在主线通知回调结束,并发送状态通知
//        NSLog(@"uninstall %s, %d progress:%f", __FUNCTION__, __LINE__, @(1.0));
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finishHandler) finishHandler(removeAll);
            [self postNotification:@{McUninstallSoftFileSizeKey: @(removeSize),McUninstallSoftProgress:@(1.0)}];
        });
    });
}


- (void)postNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:McUninstallSoftStateNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark PrivateMethod

//结束进程
- (void)killItemProcess:(McSoftwareFileItem *)fileItem
{
    NSBundle *bundle = [NSBundle bundleWithPath:fileItem.filePath];
    if (!bundle)
        return;
    
    NSString *bundleIdentifier = [bundle bundleIdentifier];
    if (!bundleIdentifier)
        return;
    
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    for (NSRunningApplication *runningApp in apps)
    {
        [[McCoreFunction shareCoreFuction] killProcessByID:runningApp.processIdentifier];
    }
}

//卸载launch
- (void)launchUnloadItem:(McSoftwareFileItem *)fileItem
{
    if ([[[fileItem.filePath pathExtension] lowercaseString] isEqualToString:@"plist"])
    {
        NSString *commandString = [NSString stringWithFormat:@"launchctl unload %@",fileItem.filePath];
        //普通权限
        system([commandString UTF8String]);
        //ROOT权限
        [[McCoreFunction shareCoreFuction] unInstallPlist:fileItem.filePath];
    }
}

//删除登录项
- (void)removeLoginitems:(NSArray *)fileItems
{
    UInt32 seedValue;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!loginItems)
        return;
    
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in (__bridge NSArray *)loginItemsArray)
    {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        CFURLRef thePath = LSSharedFileListItemCopyResolvedURL(itemRef, 0, nil);
        if (thePath)
        {
            
            NSString *loginItemPath = [(__bridge NSURL *)thePath path];
            
            for (McSoftwareFileItem *item in fileItems)
                if ([loginItemPath hasPrefix:item.filePath]) {
//#ifndef DEBUG
                    LSSharedFileListItemRemove(loginItems, itemRef);
//#endif
                }
            CFRelease(thePath);
            thePath = nil;
        }
    }
    
    if (loginItemsArray) {
        CFRelease(loginItemsArray);
    }
    CFRelease(loginItems);
}

//删除Dock中的Icon图标
- (void)removeIconFromDock:(NSArray *)fileItems
{
    //读取Dock的配置文件，通过CFPreferences的API可以避免直接读文件不同步的问题
    CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
    NSArray *apps = (__bridge_transfer NSArray *)CFPreferencesCopyAppValue( CFSTR("persistent-apps"), CFSTR("com.apple.dock") );
    
    if (!apps || ![apps isKindOfClass:[NSArray class]])
        return;
    
    NSMutableArray *removeApps = [[NSMutableArray alloc] init];
    for (NSDictionary *appInfo in apps)
    {
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
        
        for (McSoftwareFileItem *item in fileItems)
        {
            //与名字绝对匹配
            if ([filePath hasPrefix:item.filePath])
                [removeApps addObject:appInfo];
            
            //判定垃圾桶中App与Dock中的相对应(在垃圾桶&&图标对应文件不存在&&文件名相似)
            else if ([[item.filePath stringByAbbreviatingWithTildeInPath] hasPrefix:@"~/.Trash"]
                && ![[NSFileManager defaultManager] fileExistsAtPath:filePath]
                && ([[localSoft.appName lowercaseString] hasPrefix:dockName] ||
                    [[localSoft.executableName lowercaseString] hasPrefix:dockName] ||
                    [dockName hasPrefix:[localSoft.appName lowercaseString]] ||
                    [dockName hasPrefix:[localSoft.executableName lowercaseString]] ||
                    [[item.filePath.lastPathComponent lowercaseString] hasPrefix:dockName]))
                [removeApps addObject:appInfo];
        }
    }
    
    if ([removeApps count] > 0)
    {
        apps = [apps arrayByRemoveObjectsFromArray:removeApps];
        
        //写入Dock的配置文件
        //通过CFPreferences的API可以避免直接读文件不同步的问题
        CFPreferencesSetAppValue(CFSTR("persistent-apps"), (__bridge CFArrayRef)apps, CFSTR("com.apple.dock"));
        CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
        
        //杀死Dock进程(重启)
        system("killall Dock");
    }
}

@end

#pragma mark -
#pragma mark McUninstallSoftGroup

@interface McUninstallSoftGroup ()
{
    NSDate *_createDate;
    NSDate *_modifyDate;
    NSImage *_iconImage;
    NSString *_showName;
    QMSafeMutableArray *subItems;
}
@end

@implementation McUninstallSoftGroup
@synthesize groupInfo;

- (id)init
{
    self = [super init];
    if (self)
    {
        subItems = [[QMSafeMutableArray alloc] init];
    }
    return self;
}

- (void)appendItem:(id)item
{
    if ([item isKindOfClass:[McLocalSoft class]])
    {
        McLocalSoft *software = item;
        NSString *mainBundle = groupInfo[kQMSoftwareGroupIdentifer];
        
        //找到最合理的localsoft
        if ([software.bundleID isEqualToString:mainBundle])
        {
            if (!self.localSoft ||
                [self.localSoft compareVersion:software] == NSOrderedAscending)
            {
                self.localSoft = software;
            }
        }
        
        //找到最远的创建时间
        if (!_createDate || [_createDate compare:software.createDate] == NSOrderedDescending)
        {
            _createDate = software.createDate;
        }
        
        //找到最近的使用时间
        if (!_modifyDate || [_modifyDate compare:software.createDate] == NSOrderedAscending)
        {
            _modifyDate = software.modifyDate;
        }
    }
    
    if (!_iconImage &&[item isKindOfClass:[NSString class]])
    {
        NSString *filePath = item;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            //优先取第一个路径用来显示icon和名字
            if (!_iconImage)
            {
                _iconImage = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
                [_iconImage setSize:NSMakeSize(32, 32)];
            }
            
            if (!_showName)
            {
                _showName = [filePath lastPathComponent];
            }
        }
    }
    
    if ([item isKindOfClass:[McUninstallSoft class]])
    {
        McUninstallSoft *uninstallItem = item;
        
        //防止重复加入
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"bundleID == %@",uninstallItem.bundleID];
        if ([[subItems filteredArrayUsingPredicate:filter] count] == 0)
        {
            [subItems addObject:uninstallItem];
        }
    }
    
    [super appendItem:item];
}

- (NSDate *)modifyDate
{
    if (_modifyDate)
    {
        return _modifyDate;
    };
    return [super modifyDate];
}

- (NSDate *)createDate
{
    if (_createDate)
    {
        return _createDate;
    }
    
    return [super createDate];
}

- (NSString *)showName
{
    if (self.localSoft)
    {
        return self.localSoft.showName;
    }
    
    if ([subItems count] == 1)
    {
        return [(McUninstallSoft *)[subItems lastObject] showName];
    }
    
    if (_showName)
    {
        return _showName;
    }
    return @"";
}

- (NSImage *)icon
{
    if (self.localSoft)
    {
        return self.localSoft.icon;
    }
    
    if ([subItems count] == 1)
    {
        return [(McUninstallSoft *)[subItems lastObject] icon];
    }
    
    if (_iconImage)
    {
        return _iconImage;
    }
    return nil;
}

- (NSString *)version
{
    if (self.localSoft)
    {
        return self.localSoft.version;
    }
    
    if ([subItems count] == 1)
    {
        return [(McUninstallSoft *)[subItems lastObject] version];
    }
    
    return @"--";
}

- (NSString *)bundleID
{
    return groupInfo[kQMSoftwareGroupIdentifer];
}

- (McLocalType)type
{
    return kMcLocalFlagApplication;
}

@end
