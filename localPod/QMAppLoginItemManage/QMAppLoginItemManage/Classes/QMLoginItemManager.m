//
//  LoginItemManager.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//


#import "QMLoginItemManager.h"
#import "QMBaseLoginItem.h"
#import <dlfcn.h>
#import "QMAppLoginItem.h"
#import <ServiceManagement/SMLoginItem.h>
#import <ServiceManagement/ServiceManagement.h>
#import "QMLocalAppHelper.h"
#import <AppKit/NSWorkspace.h>

@interface QMLoginItemManager ()

/**
 launchd service 文件存放的目录
 */
@property NSArray *launchServiceFilePathArray;

/*
 Save login items
 */
@property NSMutableArray *loginItemArray;


typedef char (*SMLoginItemSetEnabledWithURL_ptr) ( void* ptr, char enabled);

@end

///Login Item Manager
@implementation QMLoginItemManager

+ (instancetype)shareInstance {
    static QMLoginItemManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMLoginItemManager alloc] init];
        [instance initData];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

-(void)initData{
    self.launchServiceFilePathArray = @[@"/Library/LaunchDaemons",@"/Library/LaunchAgents",[@"~/Library/LaunchAgents" stringByExpandingTildeInPath]];
}


#pragma mark -- App LoginItem
/**
获取LoginItem数据
获取应用中LoginItem数据
方法：遍历应用列表，筛选出包含LoginItem目录的应用
*/
-(NSMutableArray *)getAppLoginItems{
    /// macOS 13之后LoginItem不能被非应用本身来注册，仅支持应用自身使用SMAppService注册。
    if (@available(macOS 13.0, *)) {
        return [NSMutableArray array];
    }
    
    NSMutableArray *loginItemArray = [[NSMutableArray alloc]init];
    NSArray<QMLocalApp *> *appArray = [[QMLocalAppHelper shareInstance] getLocalAppData];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (QMLocalApp *localApp in appArray) {
        if ([self needFilterLoginItem:localApp.bundleId]) {
            continue;
        }
        if ([self.delegate respondsToSelector:@selector(needFilterLoginItemBundleId:)]) {
            if ([self.delegate needFilterLoginItemBundleId:localApp.bundleId]) {
                continue;
            }
        }
        NSString *loginItemDirPath = [localApp.bundlePath stringByAppendingString:@"/Contents/Library/LoginItems"];
        BOOL isExist = [fileManager fileExistsAtPath:loginItemDirPath];
        if(isExist){
            NSError *error = nil;
            NSArray *contentsArray = [fileManager contentsOfDirectoryAtPath:loginItemDirPath error:&error];
            for (NSString *path in contentsArray) {
                if ([path containsString:@".app"]) {
                   NSString *loginItemAppPath = [[loginItemDirPath stringByAppendingString:@"/"] stringByAppendingString:path];
//                    NSLog(@"%s, loginItemPath: %@", __FUNCTION__, loginItemAppPath);
                    QMAppLoginItem *loginItem = [[QMAppLoginItem alloc] initWithAppPath:localApp.bundlePath loginItemPath:loginItemAppPath loginItemType:LoginItemTypeAppItem];
                    if (!loginItem.loginItemBundleId) {
                        continue;
                    }
                    loginItem.isEnable = [self appLoginItemIsEnabledWithBundleId:loginItem.loginItemBundleId];
                    [loginItemArray addObject:loginItem];
                }
            }
        }
        
    }
    NSLog(@"%s, app loginItem Array count : %lu", __FUNCTION__, (unsigned long)loginItemArray.count);
    return loginItemArray;
}

-(void)enableAppLoginItemWithBundleId: (NSString *)bundleId{
    NSString *plistFilePath = [self createPlistFileWithBundleId:bundleId];
    if (plistFilePath) {
        [self loadPlistFile:plistFilePath];
        [self removeFile:plistFilePath];
    }
}

-(void)disableAppLoginItemWithBundleId: (NSString *)bundleId{
    NSString *plistFilePath = [self createPlistFileWithBundleId:bundleId];
    if (plistFilePath) {
        [self unloadPlistFile:plistFilePath];
        [self removeFile:plistFilePath];
    }
}

- (void)removeFile:(NSString *)path {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%s,error: %@", __FUNCTION__, error);
    }
}

- (NSString *)createPlistFileWithBundleId:(NSString *)bundleId {
    NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleId];
    NSLog(@"%s,bundleId: %@, login item path: %@", __FUNCTION__, bundleId, appPath);
    if (!appPath) {
        return nil;
    }
//    NSString *templatePath = [[NSBundle bundleForClass:self.class] pathForResource:@"loginItem_template" ofType:@"plist"];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"loginItem_template" ofType:@"plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:templatePath];
    if (!dict) {
        NSLog(@"dict is nil");
        return nil;
    }
    NSMutableArray *arguments = [dict objectForKey:@"ProgramArguments"];
    if (!arguments || arguments.count == 0) {
        return nil;
    }
    [arguments replaceObjectAtIndex:0 withObject:appPath];
    [dict setObject:arguments forKey:@"ProgramArguments"];
    [dict setObject:bundleId forKey:@"Label"];
    [dict setObject:appPath.stringByDeletingLastPathComponent forKey:@"WorkingDirectory"];
    
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [[directory stringByAppendingPathComponent:bundleId] stringByAppendingPathExtension:@"plist"];
    BOOL result = [dict writeToFile:path atomically:YES];
    NSLog(@"result = %d",result);
    if (result) {
        return path;
    }
    return nil;
}

- (void)loadPlistFile:(NSString *)filePath {
    NSString *cmd = [NSString stringWithFormat:@"launchctl load -w %@",filePath];
    BOOL ret = system([cmd UTF8String]);
    NSLog(@"%s, ret = %d", __FUNCTION__ ,ret);
}

- (void)unloadPlistFile:(NSString *)filePath {
    NSString *cmd = [NSString stringWithFormat:@"launchctl unload -w %@",filePath];
    BOOL ret = system([cmd UTF8String]);
    NSLog(@"%s, ret = %d", __FUNCTION__ ,ret);
}


#pragma mark -- system login item
/**
 获取系统偏好设置中登录项数据
 方法：采用系统提供的API: LSSharedFileListCreate
 */
-(NSMutableArray *)getSystemLoginItems{
    self.loginItemArray = [[NSMutableArray alloc]init];
    UInt32 seedValue;
    CFURLRef thePath;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in (__bridge NSArray *)loginItemsArray) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
            NSString *filePath = [(__bridge NSURL *)thePath path];
            QMBaseLoginItem *loginItem = [[QMBaseLoginItem alloc] initWithAppPath:filePath];
            loginItem.loginItemType = LoginItemTypeSystemItem;
            loginItem.isEnable = YES;
            [self.loginItemArray addObject:loginItem];
//            NSLog(@"%s, filePath : %@", __FUNCTION__, filePath);
            CFRelease(thePath);
           }
       }
       CFRelease(loginItemsArray);
       CFRelease(loginItems);
    NSLog(@"%s, system loginItem Array count : %lu", __FUNCTION__, (unsigned long)self.loginItemArray.count);
    return self.loginItemArray;
}

//判断LoginItem是否启用
- (BOOL)appLoginItemIsEnabledWithBundleId:(NSString*)bundleId {
    if (!bundleId) {
        return NO;
    }
    CFDictionaryRef dict = SMJobCopyDictionary(kSMDomainUserLaunchd, (__bridge CFStringRef)bundleId);
//    NSLog(@"%s, dict = %@",__FUNCTION__, dict);
    if (dict == NULL) {
        return NO;
    }
    CFRelease(dict);
    return YES;
}

-(void)addSystemLoginItemWithAppPath: (NSString *)appPath{
    NSLog(@"%s, app path: %@", __FUNCTION__, appPath);
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    //url为app所在的目录
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
    CFRelease(item);
    CFRelease(loginItems);
}

-(void)removeSystemLoginItemWithAppPath: (NSString *)appPath{
    [self reverseSharedFileList];
    NSLog(@"%s, app path: %@", __FUNCTION__, appPath);
    UInt32 seedValue;
    CFURLRef thePath;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in (__bridge NSArray *)loginItemsArray) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        OSStatus status = LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL);
        if (status == noErr) {
            //appPath目录为要取消开机启动app的路径
            if ([[(__bridge NSURL *)thePath path] hasPrefix:appPath]) {
                OSStatus status = LSSharedFileListItemRemove(loginItems, itemRef); // Deleting the item
                NSLog(@"%s, remove login item path: %@, result is: %d",__FUNCTION__, appPath,status);
                break;
            }
            CFRelease(thePath);
        } else {
            NSLog(@"%s, resolve item error: %d", __FUNCTION__, status);
        }
    }
    CFRelease(loginItemsArray);
    CFRelease(loginItems);
    [self reverseSharedFileList];
}

- (void)reverseSharedFileList {
    UInt32 seedValue;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
    NSArray *array = (__bridge NSArray *)loginItemsArray;
    NSLog(@"%s, shared list file count: %lu", __FUNCTION__, (unsigned long)array.count);
    CFRelease(loginItemsArray);
    CFRelease(loginItems);
}


#pragma mark -- Launch service
/**
 获取Launch plist数据
 */
- (NSArray *)getLaunchServiceItems {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *launchServiceItemArray = [[NSMutableArray alloc]init];
    for (NSString *directoryPath in self.launchServiceFilePathArray) {
        NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:directoryPath error:NULL];
        for (NSString *fileName in fileNames) {
            if ([self needFilterFile:fileName]) {
                continue;
            }
            if ([self.delegate respondsToSelector:@selector(needFilterLaunchServiceFile:)]) {
                if ([self.delegate needFilterLaunchServiceFile:fileName]) {
                    continue;
                }
            }
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
            NSString *label = dict[LAUNCH_SERVICE_LABEL];
            if (!label || [label isEqualToString:@""]) {
                continue;
            }
            QMAppLaunchItem *launchItem = [[QMAppLaunchItem alloc] initWithLaunchFilePath:filePath itemType:LoginItemTypeService];
            launchItem.label = label;
            launchItem.isEnable = [self serviceIsEnabledWithItem:launchItem];;
//            NSLog(@"%s, launch login itme filePath : %@",__FUNCTION__, filePath);
            //将launch plist文件与App进行匹配；
            //1. 先通过bundleId进行匹配，如果plist文件名包含bundleId,则匹配成功
            //2. 分析plist文件，与其中包含的App进行匹配
            QMLocalApp *localApp = [self getAppInfoWithFileName:fileName];
            if (localApp) {
                launchItem.appName = localApp.appName;
                launchItem.appPath = localApp.bundlePath;
            } else if(dict) {
                NSArray *array = dict[LAUNCH_SERVICE_PROGRAM_ARGUMENTS];
                if(array && array.count > 0){
                    NSString *programPath = array[0];
                    //判断是否包含app
                    if (([programPath containsString:@".app/"] || [programPath hasSuffix:@"app"])) {
                        NSRange range = [programPath rangeOfString:@".app"];
                        if (range.location != NSNotFound) {
                            NSUInteger index = range.location + 4;
                            NSString *appPath = [programPath substringToIndex:index];
                            launchItem.appPath = appPath;
                            launchItem.appName = [appPath lastPathComponent];
                        }
                    }
                }
            }
            [launchServiceItemArray addObject:launchItem];
        }
        
    }
    NSLog(@"%s, launchItemArray count : %lu",__FUNCTION__, (unsigned long)launchServiceItemArray.count);
    return launchServiceItemArray;
}

- (BOOL)needFilterFile:(NSString *)fileName {
    fileName = [fileName lowercaseString];
    if ([fileName containsString:@"com.tencent.lemon."]) {
        return YES;
    }
    if ([fileName containsString:@"com.tencent.lemonmonitor"]) {
        return YES;
    }
    if ([fileName containsString:@"com.teamviewer"]) {
        return YES;
    }
    if ([fileName containsString:@"com.xk72.charles"]) {
        return YES;
    }
    if ([fileName containsString:@"com.cisco.anyconnect"]) {
        return YES;
    }
    return NO;
}

- (BOOL)needFilterLoginItem:(NSString *)bundleId {
    if ([bundleId isEqualToString:@"com.tencent.Lemon"]) {
        return YES;
    }
    if ([bundleId isEqualToString:@"com.tencent.LemonMonitor"]) {
        return YES;
    }
    return NO;
}

- (QMLocalApp *)getAppInfoWithFileName:(NSString *)fileName {
    NSArray <QMLocalApp *>* localAppData = [[QMLocalAppHelper shareInstance] getLocalAppData];
    for (QMLocalApp *localApp in localAppData) {
        if (!localApp.bundleId || [localApp.bundleId isEqualToString:@""]) {
//            NSLog(@"%s, app bundle is nil, the app path is: %@", __FUNCTION__, localApp.bundlePath);
            continue;
        }
        fileName = [fileName lowercaseString];
        NSString *tempString = [localApp.bundleId lowercaseString];
        if ([fileName containsString:tempString]) {
            return localApp;
        }
    }
    return nil;
}


//判断后台服务是否启用
-(BOOL)serviceIsEnabledWithItem: (QMAppLaunchItem *)item{
    NSString *cmd = @"";
    __block NSString *cmdResult = @"";
     BOOL isEnable = NO;
    switch (item.domainType) {
        case LaunchServiceDomainTypeSystem:
//            cmd = [NSString stringWithFormat:@"sudo launchctl list | grep %@", item.label];
            isEnable = [self.delegate isEnableForLaunchServiceLabel:item.label];
            break;
        case LaunchServiceDomainTypeUser:
            cmd = [NSString stringWithFormat:@"launchctl list | grep %@", item.label];
            cmdResult = [self.delegate exeCommonCmd:cmd];
            break;
        default:
            break;
    }
    if(cmdResult && ![cmdResult isEqualToString:@""]){
        isEnable = YES;
    }
    return isEnable;
}

-(void)disableLaunchItem:(QMAppLaunchItem *)item{
    NSLog(@"%s, launch file path: %@", __FUNCTION__, item.filePath);
    switch (item.domainType) {
        case LaunchServiceDomainTypeSystem:
//            cmd = [NSString stringWithFormat: @"sudo launchctl disable system/%@;sudo launchctl unload %@",item.label, item.filePath];
            [self.delegate disableSystemLaunchItemWithFilePath:item.filePath label:item.label];
            break;
        case LaunchServiceDomainTypeUser: {
            NSString *cmd = [NSString stringWithFormat: @"launchctl disable gui/$UID/%@;launchctl unload %@", item.label, item.filePath];
             int result = system([cmd UTF8String]);
             NSLog(@"%s, disable user launchctl item: %@, result: %d ", __FUNCTION__, item.label, result);

        }
            break;
        default:
            break;
    }

}

-(void)enableLaunchItem:(QMAppLaunchItem *)item{
    NSLog(@"%s, launch file path: %@", __FUNCTION__, item.filePath);
    NSString *cmd = @"";
//    cmd = @"sudo launchctl enable system/com.adobe.fpsaud&&sudo launchctl load /Library/LaunchDaemons/com.adobe.fpsaud.plist";
    switch (item.domainType) {
        case LaunchServiceDomainTypeSystem:
//            cmd = [NSString stringWithFormat: @"sudo launchctl enable system/%@&&sudo launchctl load %@",item.label, item.filePath];
            [self.delegate enabelSystemLaunchItemWithFilePath:item.filePath label:item.label];
            break;
        case LaunchServiceDomainTypeUser:
            cmd = [NSString stringWithFormat: @"launchctl enable gui/$UID/%@&&launchctl load %@", item.label, item.filePath];
            int result = system([cmd UTF8String]);
            NSLog(@"%s, enable user launchctl item: %@, result: %d ", __FUNCTION__, item.label, result);
            break;
        default:
            break;
    }
}


@end

