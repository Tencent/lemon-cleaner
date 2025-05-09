//
//  Owl2Manager.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager.h"
#import "OwlConstant.h"
#import "LemonDaemonConst.h"
#import "Client.h"
#import "AVMonitor.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "consts.h"
#import "Owl2Manager+Database.h"
#import "Owl2Manager+Notification.h"
#import "Owl2Manager+Guide.h"
#import <QMCoreFunction/QMSafeMutableDictionary.h>
#import <QMCoreFunction/QMSafeMutableArray.h>

static NSString * kAppName(NSBundle *bundle) {
    NSString *appName = nil;
    appName = [bundle localizedInfoDictionary][@"CFBundleDisplayName"];
    if (!appName) {
        appName = [bundle localizedInfoDictionary][@"CFBundleName"];
    }
    if (!appName) {
        appName = [bundle infoDictionary][@"CFBundleName"];
    }
    if (!appName) {
        appName = [bundle infoDictionary][@"CFBundleExecutable"];
    }
    return appName;
}

@interface Owl2Manager () <NSUserNotificationCenterDelegate>

@property (nonatomic, strong) NSThread *owlIOThread;
@property (nonatomic, strong) NSMutableArray *notificationDetailArray;
@property (nonatomic, strong) AVMonitor *avMonitor;
@property (nonatomic) BOOL isAudioDeviceActive;

@end

@implementation Owl2Manager

typedef void (^OwlCompleteBlock)(void);

+ (Owl2Manager *)sharedManager
{
    static Owl2Manager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _wlArray = [[NSMutableArray alloc] init];
        _logArray = [[QMSafeMutableArray alloc] init];
        _notificationDetailArray = [[NSMutableArray alloc] init];
        _owlVedioItemDic = [[NSMutableDictionary alloc] init];
        _owlAudioItemDic = [[NSMutableDictionary alloc] init];
        _owlSystemAudioItemDic = [[NSMutableDictionary alloc] init];
        _isWatchAudio = NO;
        _isWatchVideo = NO;
        _isFetchDataFinish = NO;
        _isWantShowOwlWindow = NO;
        _notificationCount = 0;
        _allApps = [self getAllAppInfoWithIndexArray:nil];
        self.notificationInsertLogList = [[QMSafeMutableDictionary alloc] init];
        
        _avMonitor = [[AVMonitor alloc] init];
        __weak typeof(self) weakSelf = self;
        _avMonitor.eventCallback = ^(Event *event) {
            dispatch_async(dispatch_get_main_queue(), ^{
               @try {
                   [weakSelf processEvent:event];
               } @catch (NSException *exception) {
                   NSLog(@"%@", exception);
               } @finally {

               }
           });
        };
        [self registeNotificationDelegate];
    }
    return self;
}


- (NSMutableArray*)getAllAppInfoWithIndexArray:(NSArray*)indexArray
{
    NSMutableArray *allAppArray = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    void (^block)(NSString *appsPath) = ^(NSString *appsPath) {
        for (NSString *name in [fm contentsOfDirectoryAtPath:appsPath error:nil]) {
            //NSLog(@"appName: %@", name);
            if ([[name pathExtension] isEqualToString:@"app"]) {
                if ([name isEqualToString:MAIN_APP_NAME]) {
                    continue;
                }
                NSString *path = [appsPath stringByAppendingPathComponent:name];
                NSBundle *bubble = [NSBundle bundleWithPath:path];
                //NSLog(@"info: %@", [bubble infoDictionary]);
                NSString *icon = NSImageNameBonjour;
                if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleIconFile"]) {
                    icon = [[bubble infoDictionary] objectForKey:@"CFBundleIconFile"];
                    icon = [[bubble resourcePath] stringByAppendingPathComponent:icon];
                    if ([[icon pathExtension] isEqualToString:@""]) {
                        icon = [icon stringByAppendingPathExtension:@"icns"];
                    }
                }
                NSString *appName = kAppName(bubble);
                if (!appName) {
                    continue;
                }
                NSString *identifier = nil;
                if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleIdentifier"]) {
                    identifier = [[bubble infoDictionary] objectForKey:@"CFBundleIdentifier"];
                }
                if (!identifier) {
                    continue;
                }
                
                if (!path) {
                    continue;
                }
                NSString *executName = nil;
                if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleExecutable"]) {
                    executName = [[bubble infoDictionary] objectForKey:@"CFBundleExecutable"];
                }
                if (!executName) {
                    continue;
                }
                NSMutableDictionary *appDic = [[NSMutableDictionary alloc] init];
                [appDic setObject:icon forKey:OwlAppIcon];
                [appDic setObject:executName forKey:OwlExecutableName];
                [appDic setObject:path forKey:OwlBubblePath];
                [appDic setObject:identifier forKey:OwlIdentifier];
                [appDic setObject:appName forKey:OwlAppName];
                [appDic setObject:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
                if ([identifier hasPrefix:@"com.apple"]) {
                    [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlAppleApp];
                } else {
                    [appDic setObject:[NSNumber numberWithBool:NO] forKey:OwlAppleApp];
                }
                if (indexArray) {
                    [appDic setObject:[NSNumber numberWithInt:(int)indexArray.count] forKey:@"itemIndex"];
                }
                [allAppArray addObject:appDic];
            }
        }
    };
    
    NSString *systemAppsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)[0];
    block(systemAppsPath);
    NSString *userAppsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES)[0];
    block(userAppsPath);
    
    return allAppArray;
}

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB
{
    NSLog(@"setWatchVedio: %d, %d", _isWatchVideo, state);
    if (state) {
        // 设置过开启
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isPreviouslyEnabled = YES;
        });
    }
    if (state != _isWatchVideo) {
        _isWatchVideo = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (state) {
                    [self.avMonitor watchAllVideoDevice];
                } else {
                    [self.avMonitor unwatchAllVideoDevice];
                }
                [self setWatchVedioToDB:state];
            });
        }
    }
}

- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB
{
    NSLog(@"setWatchAudio: %d, %d", _isWatchAudio, state);
    if (state) {
        // 设置过开启
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isPreviouslyEnabled = YES;
        });
    }
    if (state != _isWatchAudio) {
        _isWatchAudio = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (state) {
                    [self.avMonitor watchAllAudioDevice];
                } else {
                    [self.avMonitor unwatchAllAudioDevice];
                }
                [self setWatchAudioToDB:state];
            });
        }
    }
}

- (void)addAppWhiteItem:(NSDictionary*)dic
{
    // 临时补丁，仅是可执行文件不允许添加到白名单
    if (![dic objectForKey:OwlIdentifier]) {
        return;
    }
    NSLog(@"QMPIPE_CMD_OWL_DATA addAppWhiteItem: %@", dic);
    NSMutableDictionary *mutableDic;
    if ([dic isKindOfClass:NSMutableDictionary.class]) {
        mutableDic = (NSMutableDictionary *)dic;
    } else {
        mutableDic = dic.mutableCopy;
    }
    
    NSDictionary *existingDic = nil;
    for (NSDictionary *subDic in self.wlArray) {
        if ([[subDic objectForKey:OwlIdentifier] isEqualToString:[dic objectForKey:OwlIdentifier]]) {
            // 将旧的白名单获取与新的白名单合并
            NSNumber *watchCam = subDic[OwlWatchCamera];
            NSNumber *watchMic = subDic[OwlWatchAudio];
            NSNumber *watchSpeaker = subDic[OwlWatchSpeaker];
            
            NSNumber *new_watchCam = mutableDic[OwlWatchCamera];
            NSNumber *new_watchMic = mutableDic[OwlWatchAudio];
            NSNumber *new_watchSpeaker = mutableDic[OwlWatchSpeaker];
            
            if (!new_watchCam && watchCam) {
                [mutableDic setObject:watchCam forKey:OwlWatchCamera];
            }
            if (!new_watchMic && watchMic) {
                [mutableDic setObject:watchMic forKey:OwlWatchAudio];
            }
            if (!new_watchSpeaker && watchSpeaker) {
                [mutableDic setObject:watchSpeaker forKey:OwlWatchSpeaker];
            }
   
            existingDic = subDic;
            break;
        }
    }
    if (existingDic) {
        // 移除旧的
        [self.wlArray removeObject:existingDic];
    }
    [self.wlArray addObject:mutableDic];
    [self addAppWhiteItemToDB:mutableDic];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
}

- (void)removeAppWhiteItemIndex:(NSInteger)index
{
    if (self.wlArray.count < index) {
        return;
    }
    NSDictionary *dic = [self.wlArray objectAtIndex:index];
    [self.wlArray removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
    [self removeAppWhiteItemToDB:dic];
}

- (void)replaceAppWhiteItemIndex:(NSInteger)index
{
    if (self.wlArray.count < index) {
        return;
    }
    NSDictionary *dic = [self.wlArray objectAtIndex:index];
//    [self removeAppWhiteItemToDB:dic];
    [self addAppWhiteItemToDB:dic];
}

- (void)loadOwlDataFromMonitor{
    
}

#pragma mark protect controll
- (void)startOwlProtect
{
    _wlArray = [[NSMutableArray alloc] init];
    _logArray = [[NSMutableArray alloc] init];
    _isFetchDataFinish = NO;
    NSLog(@"startOwlProtect begin: %d, %d", _isWatchVideo, _isWatchAudio);
    
    [self closeDB];
    [self loadDB];
    [_wlArray addObjectsFromArray:[self getWhiteList]];
    [self.avMonitor start];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isWatchVideo) {
            [self.avMonitor watchAllVideoDevice];
        }
        if (self.isWatchAudio) {
            [self.avMonitor watchAllAudioDevice];
        }
    });
    self.isFetchDataFinish = YES;
    NSLog(@"startOwlProtect end: %d, %d", _isWatchVideo, _isWatchAudio);
}

- (void)stopOwlProtect
{
    [self closeDB];
    [self.avMonitor unwatchAllAudioDevice];
    [self.avMonitor unwatchAllVideoDevice];
    self.isWatchAudio = NO;
    self.isWatchVideo = NO;
    [self.avMonitor stop];
}

#pragma mark io thread
-(void)start
{
    if ([self.owlIOThread isExecuting])
    {
        [NSException raise:@"ThoMoStubAlreadyRunningException"
                    format:@"The client stub had already been started before and cannot be started twice."];
    }
    
    // TODO: check if we cannot run a start-stop-start cycle
    NSAssert(self.owlIOThread == nil, @"Network thread not released properly");
    
    self.owlIOThread = [[NSThread alloc] initWithTarget:self selector:@selector(owlIOThreadEntry) object:nil];
    [self.owlIOThread start];
}
- (void)owlIOThreadEntry
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    while (![self.owlIOThread isCancelled] && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    {
        
    }
}

-(void)stop
{
    [self.owlIOThread cancel];
}

#pragma mark manager db data：
//a->启动设备保护逻辑
//Lemon和Monitor都在running，始终默认优先在Lemon中执行a，新方案Lemon和Monitor间不会通信，两者中只会在其中一个执行保护
//①Lemon启动，Monitor还未运行，Lemon中执行a
//②Monitor启动，Lemon在运行，Monitor不执行a
//③Monitor启动，Lemon没在运行，Monitor执行a
//④当前在②状态下，Lemon退出，Lemon发送通知给正在运行的Monitor执行a
//⑤当前在③状态下，Lemon启动，Lemon发送通知给Monitor停止执行设备保护逻辑，然后在Lemon中执行a
- (BOOL)isMonitorRunning
{
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID].count==0)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isLemonRunning
{
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count==0)
    {
        return NO;
    }
    return YES;
}

- (NSMutableDictionary *)getAppInfoWithPath:(NSString*)appPath appName:(NSString*)name
{
    //NSLog(@"getAppInfoWithPath appPath = %@, appNam = %@", appPath, name);
    NSString *path = [appPath stringByAppendingPathComponent:name];
    //[identifier hasPrefix:@"com.apple."]
    //可能已经被删除
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]){
        return nil;
    }
    NSBundle *bubble = [NSBundle bundleWithPath:path];
    if (!bubble) {
        return nil;
    }
    //NSLog(@"info: %@", [bubble infoDictionary]);
    NSString *icon = @"";
    if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleIconFile"]) {
        icon = [[bubble infoDictionary] objectForKey:@"CFBundleIconFile"];
        icon = [[bubble resourcePath] stringByAppendingPathComponent:icon];
        if ([[icon pathExtension] isEqualToString:@""]) {
            icon = [icon stringByAppendingPathExtension:@"icns"];
        }
    }
    NSString *appName = kAppName(bubble);
    if (!appName) {
        NSLog(@"getAppInfoWithPath appPath = %@, appNam = %@", path, appName);
        return nil;
    }
    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] initWithCapacity:9];
    [appDic setObject:appName forKey:OwlAppName];
    NSString *identifier = nil;
    if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleIdentifier"]) {
        identifier = [[bubble infoDictionary] objectForKey:@"CFBundleIdentifier"];
    }
    if (identifier) {
        [appDic setObject:identifier forKey:OwlIdentifier];
    } else {
        NSLog(@"getAppInfoWithPath identifier is nil");
        return nil;
    }
    NSString *executableName = nil;
    if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleExecutable"]) {
        executableName = [[bubble infoDictionary] objectForKey:@"CFBundleExecutable"];
    }
    if (executableName) {
        [appDic setObject:executableName forKey:OwlExecutableName];
    } else {
        NSLog(@"getAppInfoWithPath executableName is nil");
        return nil;
    }
    [appDic setObject:path forKey:OwlBubblePath];
    [appDic setObject:icon forKey:OwlAppIcon];
    NSNumber *appleApp;
    if ([identifier hasPrefix:@"com.apple"]) {
        appleApp = [NSNumber numberWithBool:YES];
    } else {
        appleApp = [NSNumber numberWithBool:NO];
    }
    [appDic setObject:appleApp forKey:OwlAppleApp];
    
    return appDic;
}


#pragma mark owl camera device watch
- (void)watchTimerRepeat
{
    OwlCompleteBlock complete = ^{
        
    };
    [self doOwlProcResultWithDeviceState:1 complete: complete];
}

- (void)processVedioEndItems
{
    NSLog(@"%s, owlVedioItemDic: %@", __FUNCTION__, self.owlVedioItemDic);
    NSArray *appNames = [self.owlVedioItemDic allKeys];
    NSMutableArray *endArray = [[NSMutableArray alloc] init];
    for (NSString *appName in appNames) {
        NSDictionary *item = [self.owlVedioItemDic objectForKey:appName];
        int deviceType = [item[OWL_DEVICE_TYPE] intValue];
        int count = [[item objectForKey:OWL_PROC_DELTA] intValue];
        
        if (deviceType == OwlProtectVedio) {
            if (count > 0) {
                NSMutableDictionary *endDic = [NSMutableDictionary dictionaryWithDictionary:item];
                [endDic setObject:@(-1) forKey:OWL_PROC_DELTA];
                [endArray addObject:endDic];
            }
        }
    }
    if (endArray.count > 0) {
        [self analyseDeviceInfoForNotificationWithArray:endArray];
        for (NSDictionary *dic in endArray) {
            NSString *appName = dic[OWL_PROC_NAME];
            [self.owlVedioItemDic removeObjectForKey:appName];
        }
    }
    if ([self.owlVedioItemDic allKeys].count > 0){
        NSLog(@"processVedioEndItems has some error: %@", self.owlVedioItemDic);
        [self.owlVedioItemDic removeAllObjects];
    }
}

- (void)processAudioEndItems
{
    NSLog(@"%s, owlItemDic: %@", __FUNCTION__, self.owlAudioItemDic);
    NSArray *appNames = [self.owlAudioItemDic allKeys];
    NSMutableArray *endArray = [[NSMutableArray alloc] init];
    for (NSString *appName in appNames) {
        NSDictionary *item = [self.owlAudioItemDic objectForKey:appName];
        int deviceType = [item[OWL_DEVICE_TYPE] intValue];
        int count = [[item objectForKey:OWL_PROC_DELTA] intValue];
        
        if (deviceType == OwlProtectAudio) {
            if (count > 0) {
                NSMutableDictionary *endDic = [NSMutableDictionary dictionaryWithDictionary:item];
                [endDic setObject:@(-1) forKey:OWL_PROC_DELTA];
                [endArray addObject:endDic];
            }
        }
    }
    if (endArray.count > 0) {
        [self analyseDeviceInfoForNotificationWithArray:endArray];
        for (NSDictionary *dic in endArray) {
            NSString *appName = dic[OWL_PROC_NAME];
            [self.owlAudioItemDic removeObjectForKey:appName];
        }
    }
    if ([self.owlAudioItemDic allKeys].count > 0){
        NSLog(@"processVedioEndItems has some error: %@", self.owlAudioItemDic);
        [self.owlAudioItemDic removeAllObjects];
    }
}

- (void)processEvent:(Event *)event
{
    if (event.deviceType != Device_SystemAudio && ![event.device.manufacturer containsString:@"Apple"]) {
        return;
    }
    AVDevice device = event.deviceType;
    NSControlStateValue state = event.state;
    Client *client = event.client;

    NSMutableArray *resArray = [NSMutableArray array];
    if (Device_Microphone == device) {
        if (client.pid.intValue > 0) {
            //信息完整，开启，与单个关闭
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:client.name.UTF8String];
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:client.path.UTF8String];
            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
            dicItem[OWL_DEVICE_NAME] = event.device.localizedName;
            dicItem[OWL_BUNDLE_ID] = client.processBundleID;
            dicItem[OWL_PROC_DELTA] = @(state == NSControlStateValueOn ? 1 : -1);
            
            [resArray addObject:dicItem];
            [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            if (![self.owlAudioItemDic objectForKey:client.name]) {
                [self.notificationDetailArray addObjectsFromArray:resArray];
            }
            
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
        } else if (client.processBundleID) { //如果无 pid 且有 bundleID 说明用户单独阻止，进行单独配对
            
            for (NSString *key in self.owlAudioItemDic) {
                NSMutableDictionary *dicItem = self.owlAudioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    if ([dicItem[OWL_BUNDLE_ID] isEqualToString:client.processBundleID]) {
                        dicItem[OWL_PROC_DELTA] = @(-1);
                        NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                        [resArray addObject:dicItem];
                    }
                }
            }
            [self analyseDeviceInfoForNotificationWithArray:resArray];
        } else {
            for (NSString *key in self.owlAudioItemDic) {
                NSMutableDictionary *dicItem = self.owlAudioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    dicItem[OWL_PROC_DELTA] = @(-1);
                    NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                    [resArray addObject:dicItem];
                }
            }

            [self analyseDeviceInfoForNotificationWithArray:resArray];
        }
    } else if (Device_Camera == device) {
        if (client.pid.intValue > 0) {
            //信息完整
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:client.name.UTF8String];
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:client.path.UTF8String];
            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
            dicItem[OWL_DEVICE_NAME] = event.device.localizedName;
            dicItem[OWL_BUNDLE_ID] = client.processBundleID;
            dicItem[OWL_PROC_DELTA] = @(state == NSControlStateValueOn ? 1 : -1);
            
            [resArray addObject:dicItem];
            [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! video %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            
        }  else if (client.processBundleID) {
            
            for (NSString *key in self.owlVedioItemDic) {
                NSMutableDictionary *dicItem = self.owlVedioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    if ([dicItem[OWL_BUNDLE_ID] isEqualToString:client.processBundleID]) {
                        dicItem[OWL_PROC_DELTA] = @(-1);
                        NSLog(@"!!!! camera %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                        [resArray addObject:dicItem];
                    }
                }
            }
            [self analyseDeviceInfoForNotificationWithArray:resArray];
        }
        else {
            for (NSString *key in self.owlVedioItemDic) {
                NSMutableDictionary *dicItem = self.owlVedioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
                    NSLog(@"!!!! camera %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                    [resArray addObject:dicItem];
                }
            }

            [self analyseDeviceInfoForNotificationWithArray:resArray];
        }
    } else if (device == Device_SystemAudio) {
        
        if (client.pid.intValue > 0) {
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:client.name.UTF8String];
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:client.path.UTF8String];
            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
            dicItem[OWL_BUNDLE_ID] = client.processBundleID;
            dicItem[OWL_PROC_DELTA] = @(state == NSControlStateValueOn ? 1 : -1);
            
            [resArray addObject:dicItem];
            [self.owlSystemAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! system audio %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            
        } else if (client.processBundleID) {
            
            for (NSString *key in self.owlSystemAudioItemDic) {
                NSMutableDictionary *dicItem = self.owlSystemAudioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    if ([dicItem[OWL_BUNDLE_ID] isEqualToString:client.processBundleID]) {
                        dicItem[OWL_PROC_DELTA] = @(-1);
                        NSLog(@"!!!! system audio %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                        [resArray addObject:dicItem];
                    }
                }
            }
            [self analyseDeviceInfoForNotificationWithArray:resArray];
        }
        else {
            for (NSString *key in self.owlSystemAudioItemDic) {
                NSMutableDictionary *dicItem = self.owlSystemAudioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    dicItem[OWL_PROC_DELTA] = @(-1);
                    NSLog(@"!!!! system audio %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                    [resArray addObject:dicItem];
                }
            }
            [self analyseDeviceInfoForNotificationWithArray:resArray];
        }
    }
}

- (void)doOwlProcResultWithDeviceState:(int)deviceState complete: (OwlCompleteBlock) complete{
    //11.3及以上系统暂时屏蔽隐私防护功能入口
#if DISABLED_PRIVACY_MAX1103
    if (@available(macOS 11.3, *)) {
        return;
    }
#endif
    if (!self.isWatchVideo && !self.isWatchAudio) {
        complete();
        return;
    }
    int deviceType = [self getDeviceType];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *resArray = [[McCoreFunction shareCoreFuction] getOwlDeviceProcInfo:deviceType deviceState:deviceState];
        NSLog(@"%s, resArray.count = %lu",__FUNCTION__,resArray.count);
        //NSLog(@"doOwlProcResultWithDeviceState: resArray %@", resArray);
        if (resArray.count == 0) {
            complete();
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //dic in array contain the follow three key:
            //OWL_PROC_ID/OWL_PROC_NAME/OWL_PROC_PATH/OWL_PROC_DELTA/OWL_DEVICE_TYPE
            [weakSelf.notificationDetailArray addObjectsFromArray:resArray];
            [weakSelf analyseDeviceInfoForNotificationWithArray:resArray];
            complete();
        });
    });
}

- (int)getDeviceType {
    int deviceType = 0;
    BOOL tempWatchingVedio = self.isWatchVideo;
    BOOL tempWatchingAudio = self.isWatchAudio;
    if (tempWatchingVedio && !tempWatchingAudio) {
        deviceType = 1;
    } else if (!tempWatchingVedio && tempWatchingAudio) {
        deviceType = 2;
    } else if (tempWatchingVedio && tempWatchingAudio) {
        deviceType = 4;
    }
    return deviceType;
}

- (NSString *)_audioName
{
    return [self.avMonitor.builtInMic.manufacturer stringByAppendingString:self.avMonitor.builtInMic.localizedName];
}

- (NSString *)_videoName
{
    return [self.avMonitor.builtInCamera.manufacturer stringByAppendingString:self.avMonitor.builtInCamera.localizedName];
}

@end

