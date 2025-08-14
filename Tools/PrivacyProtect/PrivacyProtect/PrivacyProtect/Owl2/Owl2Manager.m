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
#import "Owl2LogProcessItem.h"

#define PPCheckScreenShotFrameWindowTimeInterval 0.5

@import OSLog;

os_log_t logHandle = nil;

NSNotificationName const OwlWhiteListChangeNotication = @"OwlWhiteListChangeNotication";

NSNotificationName const OwlLogChangeNotication = @"OwlLogChangeNotication";

@interface Owl2Manager () <NSUserNotificationCenterDelegate>

@property (nonatomic, strong) NSThread *owlIOThread;
@property (nonatomic, strong) NSMutableArray *notificationDetailArray;
@property (nonatomic, strong) AVMonitor *avMonitor;
@property (nonatomic) BOOL avMonitorIsRunning;
@property (nonatomic) BOOL isAudioDeviceActive;
@property (nonatomic) NSMutableDictionary<NSString *, NSDate *> *appEventTimeDict;

@property (nonatomic) NSMutableArray *screenShotEventArray;
@property (nonatomic) NSTimer *screenShotTimer;
@property (nonatomic) NSMutableArray *dispatchedScreenCaptureEventArray;

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
        _wlDic = [[QMSafeMutableDictionary alloc] init];
        _logArray = [[QMSafeMutableArray alloc] init];
        _notificationDetailArray = [[NSMutableArray alloc] init];
        _owlVideoItemDic = [[NSMutableDictionary alloc] init];
        _owlAudioItemDic = [[NSMutableDictionary alloc] init];
        _owlSystemAudioItemDic = [[NSMutableDictionary alloc] init];
        _owlScreenItemDic = [[NSMutableDictionary alloc] init];
        _owlScreenItemArray = [NSMutableArray new];  //用来延迟判断是截图还是录屏
        _screenShotEventArray = [NSMutableArray new]; //用来等待蒙层消失之后发截屏通知
        _dispatchedScreenCaptureEventArray = [NSMutableArray new]; //用来处理截屏和录屏的通知冲突，优先展示录屏
        self.notificationInsertLogList = [[QMSafeMutableDictionary alloc] init];
        self.appEventTimeDict = [NSMutableDictionary new];
        
        // 初始化用户是否显示过老的guideview横幅
        [self initCurrentUserDidShowGuideInOldVersionCached];
        
        _avMonitor = [[AVMonitor alloc] init];
        __weak typeof(self) weakSelf = self;
        _avMonitor.eventCallback = ^(Event *event) {
            dispatch_async(dispatch_get_main_queue(), ^{
               @try {
                   [weakSelf processEvent:event];
               } @catch (NSException *exception) {
                   NSLog(@"%@", exception);
               }
           });
        };
        [self registeNotificationDelegate];
    }
    return self;
}


- (NSArray<Owl2AppItem *> *)getAllAppInfo
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
                Owl2AppItem *appItem = [[Owl2AppItem alloc] initWithAppPath:path];
                [allAppArray addObject:appItem];
            }
        }
    };
    
    NSString *systemAppsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)[0];
    block(systemAppsPath);
    NSString *userAppsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES)[0];
    block(userAppsPath);
    
    return allAppArray.copy;
}

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB
{
    NSLog(@"setWatchVedio: %d, %d", _isWatchVideo, state);
    if (state != _isWatchVideo) {
        _isWatchVideo = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAllWatch];
            });
        }
        [self someFeatureSwitchValueDidChange];
    }
}

- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB
{
    NSLog(@"setWatchAudio: %d, %d", _isWatchAudio, state);
    if (state != _isWatchAudio) {
        _isWatchAudio = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAllWatch];
            });
        }
        [self someFeatureSwitchValueDidChange];
    }
}

- (void)setWatchScreen:(BOOL)state toDb:(BOOL)toDB {
    NSLog(@"setWatchScreen: %d, %d", _isWatchScreen, state);
    if (state != _isWatchScreen) {
        _isWatchScreen = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAllWatch];
            });
        }
        [self someFeatureSwitchValueDidChange];
    }
}

- (void)setWatchAutomatic:(BOOL)state toDb:(BOOL)toDB {
    NSLog(@"setWatchAutomatic: %d, %d", _isWatchAutomatic, state);
    if (state != _isWatchAutomatic) {
        _isWatchAutomatic = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAllWatch];
            });
        }
        [self someFeatureSwitchValueDidChange];
    }
}

- (void)addWhiteWithAppItem:(Owl2AppItem *)appItem {
    // 临时补丁，仅是可执行文件不允许添加到白名单
    if (![appItem.identifier isKindOfClass:NSString.class]) {
        return;
    }
    if (appItem.identifier.length == 0) {
        return;
    }
    
    Owl2AppItem *oldAppItem = [self.wlDic objectForKey:appItem.identifier];
    if (oldAppItem) {
        [oldAppItem mergeWithAnother:appItem];
    } else {
        oldAppItem = appItem;
    }
    // 更新白名单
    [self.wlDic setObject:oldAppItem forKey:oldAppItem.identifier];
    [self addAppWhiteItemToDB:oldAppItem.toDictionary];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
}

- (void)removeAppWhiteItemWithIdentifier:(NSString *)identifier {
    if (![identifier isKindOfClass:NSString.class]) {
        return;
    }
    Owl2AppItem *oldAppItem = [self.wlDic objectForKey:identifier];
    [self.wlDic removeObjectForKey:identifier];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
    [self removeAppWhiteItemToDB:oldAppItem.toDictionary];
}

- (void)loadOwlDataFromMonitor{
    
}

#pragma mark protect controll
- (void)startOwlProtect
{
    _wlDic = [[QMSafeMutableDictionary alloc] init];
    _logArray = [[NSMutableArray alloc] init];
    _isFetchDataFinish = NO;
    NSLog(@"startOwlProtect begin: %d, %d, %d, %d", _isWatchVideo, _isWatchAudio, _isWatchScreen, _isWatchAutomatic);
    
    [self closeDB];
    [self loadDB];
    NSArray *wlList = [self getWhiteList];
    for (NSDictionary *appDic in wlList) {
        Owl2AppItem *item = [[Owl2AppItem alloc] initWithDic:appDic];
        if ([item.identifier isKindOfClass:NSString.class]) {
            [self.wlDic setObject:item forKey:item.identifier];
        }
    }
    if (self.isWatchAudio || self.isWatchVideo || self.isWatchScreen || self.isWatchAutomatic) {
        [self starAvMonitor];
    }
    self.isFetchDataFinish = YES;
    NSLog(@"startOwlProtect end: %d, %d, %d, %d", _isWatchVideo, _isWatchAudio, _isWatchScreen, _isWatchAutomatic);
}

- (void)stopOwlProtect
{
    [self closeDB];
    self.isWatchAudio = NO;
    self.isWatchVideo = NO;
    self.isWatchScreen = NO;
    self.isWatchAutomatic = NO;
    [self stopAvMonitor];
}

- (void)someFeatureSwitchValueDidChange {
    dispatch_block_t block = ^{
        if (self.isWatchAudio || self.isWatchVideo || self.isWatchScreen || self.isWatchAutomatic) {
            [self starAvMonitor];
        } else {
            [self stopAvMonitor];
        }
    };
    
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)starAvMonitor {
    if (!self.avMonitorIsRunning) {
        self.avMonitorIsRunning = YES;
        [self.avMonitor start];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isWatchVideo ? [self.avMonitor watchAllVideoDevice] : [self.avMonitor unwatchAllVideoDevice];
        self.isWatchAudio ? [self.avMonitor watchAllAudioDevice] : [self.avMonitor unwatchAllAudioDevice];
        self.isWatchScreen ? [self.avMonitor watchAllScreen] : [self.avMonitor unwatchAllScreen];
        self.isWatchAutomatic ? [self.avMonitor watchAutomatic] : [self.avMonitor unwatchAutomatic];
    });
}

- (void)stopAvMonitor {
    if (!self.avMonitorIsRunning) return;
    self.avMonitorIsRunning = NO;
    [self.avMonitor unwatchAllAudioDevice];
    [self.avMonitor unwatchAllVideoDevice];
    [self.avMonitor unwatchAllScreen];
    [self.avMonitor unwatchAutomatic];
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

#pragma mark -

- (void)processEvent:(Event *)event
{
    if (event.deviceType == LMDevice_Camera || event.deviceType == LMDevice_Microphone) {
        if (![event.device.manufacturer containsString:@"Apple"]) {
            return;
        }
    }

    LMDeviceType deviceType = event.deviceType;
    Client *client = event.client;

    NSMutableArray *resArray = [NSMutableArray array];
    if (LMDevice_Microphone == deviceType) {
        if (client.pid.intValue > 0) {
            //信息完整，开启
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            [self _setDictItem:dicItem event:event];
            
            [resArray addObject:dicItem];
            [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            if (![self.owlAudioItemDic objectForKey:client.name]) {
                [self.notificationDetailArray addObjectsFromArray:resArray];
            }
            
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
        } else {
            [self _processDictItem:self.owlAudioItemDic offEvent:event];
        }
    } else if (LMDevice_Camera == deviceType) {
        if (client.pid.intValue > 0) {
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            [self _setDictItem:dicItem event:event];
            
            [resArray addObject:dicItem];
            [self.owlVideoItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! video %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            
        } else {
            [self _processDictItem:self.owlVideoItemDic offEvent:event];
        }
    } else if (deviceType == LMDevice_SystemAudio) {
        
        if (client.pid.intValue > 0) {
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            [self _setDictItem:dicItem event:event];
            
            [resArray addObject:dicItem];
            [self.owlSystemAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! system audio %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            
        } else {
            [self _processDictItem:self.owlSystemAudioItemDic offEvent:event];
        }
    } else if (deviceType == LMDevice_Screen) {
        
        if (client.pid.intValue > 0) {
            
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            [self _setDictItem:dicItem event:event];
            
            if (event.deviceExtra) {
                [self _consumeScreenItem:dicItem screenShot:YES]; //是截屏
            } else {
                [self.owlScreenItemArray addObject:dicItem];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([self.owlScreenItemArray containsObject:dicItem]) {
                        [self.owlScreenItemArray removeObject:dicItem];
                        [self _processScreenCaptureAndShotConflicts:event];
                        [self _consumeScreenItem:dicItem screenShot:NO]; // 一秒后没有结束事件判断是录屏
                    }
                });
            }
            
        } else { //收到结束事件
            BOOL isScreenShot = NO;
            NSDictionary *deleteItem = nil;
            for (NSMutableDictionary *item in self.owlScreenItemArray) {
                if ([item[OWL_BUNDLE_ID] isEqualToString:client.processBundleID]) { //说明一秒内结束
                    isScreenShot = YES;
                    deleteItem = item;
                    [self _consumeScreenItem:item screenShot:YES]; //是截屏
                    break;
                }
            }
            
            if (!isScreenShot) {
                [self _processScreenCaptureAndShotConflicts:event];  //结束录屏加入时限标识，时限内不展示截图通知
                [self _processDictItem:self.owlScreenItemDic offEvent:event];
            } else {
                [self.owlScreenItemArray removeObject:deleteItem];
            }
        }
    } else if (LMDevice_Automatic == deviceType) {
        NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
        [self _setDictItem:dicItem event:event];
        [self.notificationDetailArray addObjectsFromArray:@[dicItem]];
        [self analyseDeviceInfoForNotificationWithArray:@[dicItem]];
    }
}

- (void)_consumeScreenItem:(NSMutableDictionary *)dicItem screenShot:(BOOL)isScreenShot
{
    NSMutableArray *resArray = [NSMutableArray array];
    [resArray addObject:dicItem];
    if (isScreenShot) {
        NSString *bundleID = dicItem[OWL_BUNDLE_ID];
        NSDate *lastScreenShotDate = self.appEventTimeDict[bundleID];
        self.appEventTimeDict[bundleID] = [NSDate date];
        if (lastScreenShotDate && -[lastScreenShotDate timeIntervalSinceNow] < 5) {
            return; //过滤连续截屏事件
        }
        dicItem[OWL_DEVICE_EXTRA] = @(isScreenShot);
        [self _processScreenShotEvent:dicItem];
    } else {
        //录屏需要配对
        [self.owlScreenItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
        [self.notificationDetailArray addObjectsFromArray:resArray];
        [self analyseDeviceInfoForNotificationWithArray:resArray];
        NSLog(@"screen event %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
    }
}

- (void)_processScreenCaptureAndShotConflicts:(Event *)event
{
    // 录屏的时候同时有截屏的通知，过滤截屏的
    [self.dispatchedScreenCaptureEventArray addObject:event];
    // 屏蔽截图两秒钟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.dispatchedScreenCaptureEventArray removeObject:event];
    });
}


// 目标app截图蒙版消失后再出现截屏通知
- (void)_processScreenShotEvent:(NSDictionary *)dictItem
{
    if (!dictItem) return;
    NSLog(@"screenshot event incoming %@", dictItem[OWL_PROC_NAME]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        pid_t pid = [dictItem[OWL_PROC_ID] intValue];
        NSDictionary *frameWindow = [self _getScreenShotFrameWindowWithPid:pid];
        if (!frameWindow) { //没有蒙版直接发通知
            [self _dispathScreenShotEvent:dictItem];
            NSLog(@"screenshot event no frame window %@", dictItem[OWL_PROC_NAME]);
        } else {
            if (!self.screenShotTimer) {
                self.screenShotTimer = [NSTimer scheduledTimerWithTimeInterval:PPCheckScreenShotFrameWindowTimeInterval target:self selector:@selector(_checkScreenShotFrameWindowDisappear) userInfo:nil repeats:YES];
            }
            [self.screenShotEventArray addObject:dictItem];
        }
    });
}

- (void)_checkScreenShotFrameWindowDisappear
{
    NSMutableArray *updatedArray = [NSMutableArray new];
    for (NSMutableDictionary *item in [self.screenShotEventArray copy]) {
        NSString *frameCountKey = @"__frame_count";
        pid_t pid = [item[OWL_PROC_ID] intValue];
        int count = [item[frameCountKey] intValue];
        count++;
        item[frameCountKey] = @(count);
        NSDictionary *frameWindow = [self _getScreenShotFrameWindowWithPid:pid];
        if (frameWindow) {
            if (count > 3600/PPCheckScreenShotFrameWindowTimeInterval) {//1小时超时
                // 丢弃通知
                NSLog(@"screenshot event frame window exist over time %@ %@", item[OWL_PROC_NAME], item[frameCountKey]);
            } else {
                [updatedArray addObject:item];
                NSLog(@"screenshot event frame window still exist %@ %@", item[OWL_PROC_NAME], item[frameCountKey]);
            }
        } else {
            item[frameCountKey] = nil;
            [self _dispathScreenShotEvent:item];
            NSLog(@"screenshot event frame window disappear %@", item[OWL_PROC_NAME]);
        }
    }
    if (updatedArray.count <= 0) {
        [self.screenShotTimer invalidate];
        self.screenShotTimer = nil;
    }
    self.screenShotEventArray = updatedArray;
    NSLog(@"screenshot event array count %ld", updatedArray.count);
}

- (void)_dispathScreenShotEvent:(NSDictionary *)item
{
    //截屏通知之前两秒内有录屏的，不发送截屏的
    for (Event *event in [self.dispatchedScreenCaptureEventArray copy]) {
        if ([event.client.processBundleID isEqualToString:item[OWL_BUNDLE_ID]]) {
            return;
        }
    }
    [self.notificationDetailArray addObjectsFromArray:@[item]];
    [self analyseDeviceInfoForNotificationWithArray:@[item]];
}

// 获取截图蒙层窗口，根据大小和无name进行猜测判断
- (NSDictionary *)_getScreenShotFrameWindowWithPid:(pid_t)pid
{
    NSArray *windowList = [self _getCurrentWindows];
    for (NSDictionary *window in windowList) {
        pid_t windowPid = [window[(id)kCGWindowOwnerPID] intValue];
        CFDictionaryRef boundsDict = (__bridge CFDictionaryRef)(window[(id)kCGWindowBounds]);
        CGRect bounds = CGRectZero;
        CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds);
        CGRect mainBounds = [NSScreen mainScreen].frame;
        NSString *name = window[(id)kCGWindowName];
        if (windowPid == pid && CGSizeEqualToSize(bounds.size, mainBounds.size) && name.length == 0) {
            return window;
        }
    }
    return nil;
}

- (NSArray<NSDictionary*> *)_getCurrentWindows {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID
    );
    NSArray *array = (__bridge NSArray *)(windowList);
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *dict in array) {
        NSInteger windowLevel = [dict[(id)kCGWindowLayer] integerValue];
        if (windowLevel != kCGStatusWindowLevel && windowLevel != kCGDockWindowLevel) {
            [result addObject:dict];
        }
    }
    CFBridgingRelease(windowList);
    return result;
}

- (void)_processDictItem:(NSMutableDictionary *)dict offEvent:(Event *)event
{
    Client *client = event.client;
    NSMutableArray *resArray = [NSMutableArray array];
    //如果无 pid 且有 bundleID 说明用户单独阻止，进行单独配对
    if (client.processBundleID) {
        [self _matchDictItem:dict event:event resArray:resArray];
        [self analyseDeviceInfoForNotificationWithArray:resArray];
    }
    else {
        [self _matchAllDictItem:dict resArray:resArray];
        [self analyseDeviceInfoForNotificationWithArray:resArray];
    }
}

- (void)_setDictItem:(NSMutableDictionary *)dict event:(Event *)event
{
    NSControlStateValue state = event.state;
    Client *client = event.client;
    dict[OWL_PROC_ID] = client.pid;
    dict[OWL_PROC_NAME] = client.name;
    dict[OWL_PROC_PATH] = client.path;
    dict[OWL_DEVICE_TYPE] = @(event.deviceType);
    dict[OWL_DEVICE_NAME] = event.device.localizedName;
    dict[OWL_BUNDLE_ID] = client.processBundleID;
    dict[OWL_PROC_DELTA] = @(state == NSControlStateValueOn ? 1 : -1);
    dict[OWL_TARGET_PROC_ID] = client.targetPid;
    dict[OWL_TARGET_PROC_NAME] = client.targetName ?: @"";
    dict[OWL_TARGET_PROC_PATH] = client.targetPath ?: @"";
}

- (void)_matchDictItem:(NSDictionary *)dict event:(Event *)event resArray:(NSMutableArray *)resArray;
{
    Client *client = event.client;
    for (NSString *key in dict) {
        NSMutableDictionary *dicItem = dict[key];
        if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
            if ([dicItem[OWL_BUNDLE_ID] isEqualToString:client.processBundleID]) {
                dicItem[OWL_PROC_DELTA] = @(-1);
                NSLog(@"!!!! deviceType:%@ %@ %@", dicItem[OWL_DEVICE_TYPE], dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                [resArray addObject:dicItem];
            }
        }
    }
}

- (void)_matchAllDictItem:(NSDictionary *)dict resArray:(NSMutableArray *)resArray;
{
    for (NSString *key in dict) {
        NSMutableDictionary *dicItem = dict[key];
        if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
            dicItem[OWL_PROC_DELTA] = @(-1);
            NSLog(@"!!!! deviceType:%@ %@ %@", dicItem[OWL_DEVICE_TYPE], dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            [resArray addObject:dicItem];
        }
    }
}

- (NSString *)_audioName
{
    return [self.avMonitor.builtInMic.manufacturer stringByAppendingString:self.avMonitor.builtInMic.localizedName];
}

- (NSString *)_videoName
{
    return [self.avMonitor.builtInCamera.manufacturer stringByAppendingString:self.avMonitor.builtInCamera.localizedName];
}

- (void)killAppWithDictItem:(NSDictionary *)dictItem;
{
    if ([dictItem[OWL_DEVICE_TYPE] intValue] == LMDevice_Screen) {
        [self.avMonitor killScreenCaptureAppWithBundleID:dictItem[OWL_BUNDLE_ID]];
    }
}

- (void)getFrontMostAppBundleIdWithCompletion:(void (^)(NSString *))completion {
    [self.avMonitor updateFrontMostWindowWithCompletion:completion];
}

@end

