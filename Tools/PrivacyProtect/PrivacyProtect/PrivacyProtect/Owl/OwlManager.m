//
//  OwlManager.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlManager.h"
#import <Cocoa/Cocoa.h>
#import "OwlConstant.h"
#import "LemonDaemonConst.h"
#import "CameraObserver.h"
#import "AudioObserver.h"
#import "QMUserNotificationCenter.h"
#import "Client.h"
#import "AVMonitor.h"
#import <QMCoreFunction/McCoreFunction.h>
#import <FMDB/FMDB.h>
#import "consts.h"
@import OSLog;

//log handle
os_log_t logHandle = nil;

NSNotificationName const OwlWhiteListChangeNotication = @"OwlWhiteListChangeNotication";
NSNotificationName const OwlLogChangeNotication = @"OwlLogChangeNotication";
NSNotificationName const OwlShowWindowNotication = @"OwlShowWindowNotication";

NSNotificationName const OwlWatchVedioStateChange = @"OwlWatchVedioStateChange";
NSNotificationName const OwlWatchAudioStateChange = @"OwlWatchAudioStateChange";

NSNotificationName const kOwlVedioNotification = @"kOwlVedioNotification";
NSNotificationName const kOwlAudioNotification = @"kOwlAudioNotification";
NSNotificationName const kOwlVedioAndAudioNotification = @"kOwlVedioAndAudioNotification";

@interface OwlManager () <NSUserNotificationCenterDelegate> {
    NSString *dbPath;
    FMDatabase *db;
}
@property (nonatomic, strong) NSThread *owlIOThread;
@property (nonatomic, strong) CameraObserver *cameraObserver;
@property (nonatomic, strong) AudioObserver *audioObserver;
@property (nonatomic, strong) NSMutableArray *notificationDetailArray;
@property (nonatomic, strong) NSMutableDictionary *owlVedioItemDic;
@property (nonatomic, strong) NSMutableDictionary *owlAudioItemDic;
@property (nonatomic, strong) NSTimer *watchingTimer;
@property (nonatomic, assign) BOOL isWatchingVedio;
@property (nonatomic, assign) BOOL isWatchingAudio;
@property (nonatomic, assign) int notificationCount;
@property (nonatomic, strong) NSMutableArray *allApps;
@property (nonatomic, strong) AVMonitor *avMonitor;
@end

@implementation OwlManager

typedef void (^OwlCompleteBlock)(void);

+ (OwlManager *)shareInstance{
    static OwlManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        logHandle = os_log_create("com.tencent.owl.avlogger", "application");

        _wlArray = [[NSMutableArray alloc] init];
        _logArray = [[NSMutableArray alloc] init];
        _notificationDetailArray = [[NSMutableArray alloc] init];
        _owlVedioItemDic = [[NSMutableDictionary alloc] init];
        _owlAudioItemDic = [[NSMutableDictionary alloc] init];
        _isWatchAudio = NO;
        _isWatchVedio = NO;
        _isFetchDataFinish = NO;
        _isWantShowOwlWindow = NO;
        _watchingTimer = nil;
        _isWatchingVedio = NO;
        _isWatchingAudio = NO;
        _notificationCount = 0;
        _allApps = [self getAllAppInfoWithIndexArray:nil];
        _avMonitor = [[AVMonitor alloc] init];
        
        __weak typeof(self) weakSelf = self;
        _avMonitor.completeBlock = ^(AVDevice device, NSControlStateValue state, Client *client) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    [weakSelf processedWatch:device state:state client:client];
                } @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                } @finally {
                    
                }
            });
        };
        
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:kOwlVedioNotification];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:kOwlAudioNotification];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:kOwlVedioAndAudioNotification];
    }
    return self;
}

- (void)dealloc{
    
}

- (NSMutableArray*)getAllAppInfoWithIndexArray:(NSArray*)indexArray{
    NSMutableArray *allAppArray = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *appsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)[0];
    NSError *error = nil;
    for (NSString *name in [fm contentsOfDirectoryAtPath:appsPath error:&error]) {
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
            NSString *appName = nil;
            if ([[[bubble localizedInfoDictionary] allKeys] containsObject:@"CFBundleDisplayName"]) {
                appName = [[bubble localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
            } else {
                if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleName"]) {
                    appName = [[bubble infoDictionary] objectForKey:@"CFBundleName"];
                } else {
                    appName = [[bubble infoDictionary] objectForKey:@"CFBundleExecutable"];
                }
            }
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
            [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
            [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
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
    return allAppArray;
}

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB{
    NSLog(@"setWatchVedio: %d, %d", _isWatchVedio, state);
    if (state != _isWatchVedio) {
        _isWatchVedio = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (state) {
                    [self.cameraObserver startCameraObserver];
                } else {
                    [self.cameraObserver stopCameraObserver];
                }
                [self setWatchVedioToDB:state];
            });
        }
    }
}
- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB{
    NSLog(@"setWatchAudio: %d, %d", _isWatchAudio, state);
    if (state != _isWatchAudio) {
        _isWatchAudio = state;
        if (toDB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (state) {
                    [self.audioObserver startAudioObserver];
                } else {
                    [self.audioObserver stopAudioObserver];
                }
                [self setWatchAudioToDB:state];
            });
        }
    }
}

- (void)resaveWhiteList{
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
    [self resaveWhiteListToDB];
}
- (void)addAppWhiteItem:(NSDictionary*)dic{
    NSLog(@"QMPIPE_CMD_OWL_DATA addAppWhiteItem: %@", dic);
    for (NSDictionary *subDic in self.wlArray) {
        if ([[subDic objectForKey:OwlIdentifier] isEqualToString:[dic objectForKey:OwlIdentifier]]) {
            return;
        }
    }
    [self.wlArray addObject:dic];
    [self addAppWhiteItemToDB:dic];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
}
- (void)removeAppWhiteItemIndex:(NSInteger)index{
    if (self.wlArray.count < index) {
        return;
    }
    NSDictionary *dic = [self.wlArray objectAtIndex:index];
    [self.wlArray removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
    [self removeAppWhiteItemToDB:dic];
}
- (void)replaceAppWhiteItemIndex:(NSInteger)index{
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
    //[[OwlXPCConnector shareInstance] startConnection];
    //[[OwlXPCConnector shareInstance] sendMsg:@{FUNCTIONKEY: APPLAUNCHED, PARAMETERKEY: @{}}];
    _wlArray = [[NSMutableArray alloc] init];
    _logArray = [[NSMutableArray alloc] init];
    _isFetchDataFinish = NO;
    NSLog(@"startOwlProtect begin: %d, %d", _isWatchVedio, _isWatchAudio);
    
    [self closeDB];
    [self loadDB];
    if (!self.cameraObserver) {
        self.cameraObserver = [[CameraObserver alloc] init];
    }
    if (!self.audioObserver) {
        self.audioObserver = [[AudioObserver alloc] init];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isWatchVedio) {
            [self.cameraObserver startCameraObserver];
        }
        if (self.isWatchAudio) {
            [self.audioObserver startAudioObserver];
        }
    });
    [self.avMonitor start];
    self.isFetchDataFinish = YES;
    NSLog(@"startOwlProtect end: %d, %d", _isWatchVedio, _isWatchAudio);
}

- (void)stopOwlProtect
{
    [self closeDB];
    [self.cameraObserver stopCameraObserver];
    [self.audioObserver stopAudioObserver];
    [self stopCameraWatchTimer];
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
- (void)owlIOThreadEntry{
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
- (BOOL)isMonitorRunning{
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MONITOR_APP_BUNDLEID].count==0)
    {
        return NO;
    }
    return YES;
}
- (BOOL)isLemonRunning{
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count==0)
    {
        return NO;
    }
    return YES;
}
- (void)createWhiteAppTable{
    NSString *strSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text NOT NULL, %@ text NOT NULL, %@ text NOT NULL, %@ text PRIMARY KEY NOT NULL, %@ text NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
    BOOL result = [db executeUpdate:strSQL];
    if (result)
    {
    } else {
        NSLog(@"Error owl create app_white table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}
- (void)createBlockTable{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, %@ text NOT NULL);", OwlProBlockTable, OwlExecutableName]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_block table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}
- (void)createProfileTable{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, %@ integer DEFAULT 0, %@ integer DEFAULT 0);", OwlProcProfileTable, OwlWatchCamera, OwlWatchAudio]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_profile table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}
- (void)createLogTable{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, time text NOT NULL, %@ text NOT NULL,  event text NOT NULL);", OwlProcLogTable, OwlAppName]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_log table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}
- (void)loadDB
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *home = NSHomeDirectory();
    NSString *support = [home stringByAppendingPathComponent:@"Library/Application Support/com.tencent.lemon/Owl"];
    dbPath = [support stringByAppendingPathComponent:@"owl.db"];
    if (![fm fileExistsAtPath:support]){
        NSError *error = nil;
        if (![fm createDirectoryAtPath:support withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"create owl support path fail");
        }
    }
    if (![fm fileExistsAtPath:dbPath]) {
        db = [FMDatabase databaseWithPath:dbPath];
        if ([db open])
        {
            [self createLogTable];
            [self createBlockTable];
            [self createProfileTable];
            
            NSString *strSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text NOT NULL, %@ text NOT NULL, %@ text NOT NULL, %@ text PRIMARY KEY NOT NULL, %@ text NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
            BOOL result = [db executeUpdate:strSQL];
            if (result)
            {
                NSString *appsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)[0];
                NSError *error = nil;
                for (NSString *name in [fm contentsOfDirectoryAtPath:appsPath error:&error]) {
                    if ([[name pathExtension] isEqualToString:@"app"]) {
                        if ([name isEqualToString:@"Siri.app"] ||
                            [name isEqualToString:@"Photo Booth.app"] ||
                            [name isEqualToString:@"FaceTime.app"]) {
                            [self addAppWhiteItem:[self getAppInfoWithPath:appsPath appName:name]];
                        } else {
                            //[self getAppInfoWithPath:appsPath appName:name];
                        }
                    }
                }
                //[db executeUpdate:@"INSERT INTO t_student (appName,executableName,bubblePath,identifier,appIcon,appleApp) VALUES  (?,?,?,?,?,?);" withArgumentsInArray:_wlArray];
            } else {
                NSLog(@"Error owl create app_white table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        } else {
            NSLog(@"Error owl open db fail %d: %@  path:%@", [db lastErrorCode], [db lastErrorMessage], dbPath);
        }
    } else {
        db = [FMDatabase databaseWithPath:dbPath];
        if ([db open])
        {
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlAppWhiteTable]];
            NSLog(@"[resultSet columnCount]: %d", [resultSet columnCount]);
            NSLog(@"columnNameToIndexMap: %@", [[resultSet columnNameToIndexMap] allKeys]);
            BOOL hasOwlWatchCameraAndAudio = NO;
            if ([[[resultSet columnNameToIndexMap] allKeys] containsObject:OwlWatchCamera] ||
                [[[resultSet columnNameToIndexMap] allKeys] containsObject:[OwlWatchCamera lowercaseString]]) {
                hasOwlWatchCameraAndAudio = YES;
            } else {
            }
            //NSLog(@"_wlArray: %@", _wlArray);
            while ([resultSet  next])
            {
                if (resultSet &&
                    [resultSet objectForColumn:OwlAppName] &&
                    [resultSet objectForColumn:OwlExecutableName] &&
                    [resultSet objectForColumn:OwlBubblePath] &&
                    [resultSet objectForColumn:OwlIdentifier] &&
                    [resultSet objectForColumn:OwlAppIcon]) {
                    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] initWithCapacity:8];
                    [appDic setObject:[resultSet objectForColumn:OwlAppName] forKey:OwlAppName];
                    [appDic setObject:[resultSet objectForColumn:OwlExecutableName] forKey:OwlExecutableName];
                    [appDic setObject:[resultSet objectForColumn:OwlBubblePath] forKey:OwlBubblePath];
                    [appDic setObject:[resultSet objectForColumn:OwlIdentifier] forKey:OwlIdentifier];
                    [appDic setObject:[resultSet objectForColumn:OwlAppIcon] forKey:OwlAppIcon];
                    if ([resultSet intForColumn:OwlAppleApp]) {
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlAppleApp]] forKey:OwlAppleApp];
                    } else {
                        [appDic setObject:[NSNumber numberWithInt:0] forKey:OwlAppleApp];
                    }
                    //NSLog(@"hasOwlWatchCameraAndAudio: %d, %d, %d", hasOwlWatchCameraAndAudio, [resultSet intForColumn:OwlWatchCamera], [resultSet intForColumn:OwlWatchAudio]);
                    if (hasOwlWatchCameraAndAudio) {
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlWatchCamera]] forKey:OwlWatchCamera];
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlWatchAudio]] forKey:OwlWatchAudio];
                    } else {
                        [appDic setObject:[NSNumber numberWithInt:1] forKey:OwlWatchCamera];
                        [appDic setObject:[NSNumber numberWithInt:1] forKey:OwlWatchAudio];
                    }
                    BOOL isExist = NO;
                    for (NSDictionary *dic in _wlArray) {
                        if ([[dic objectForKey:OwlIdentifier] isEqualToString:[resultSet objectForColumn:OwlIdentifier]]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [_wlArray addObject:appDic];
                    }
                }
            }
            if (!hasOwlWatchCameraAndAudio) {
                [db executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", OwlAppWhiteTable]];
                [self createWhiteAppTable];
                [self resaveWhiteList];
            }
            //NSLog(@"_wlArray: %@", _wlArray);
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createWhiteAppTable];
            }
            
            FMResultSet *resultSetLog = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProcLogTable]];
            while ([resultSetLog  next])
            {
                if (resultSetLog &&
                    [resultSetLog objectForColumn:@"time"] &&
                    [resultSetLog objectForColumn:@"event"] &&
                    [resultSetLog objectForColumn:OwlAppName]) {
                    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] initWithCapacity:3];
                    [appDic setObject:[resultSetLog objectForColumn:@"time"] forKey:@"time"];
                    [appDic setObject:[resultSetLog objectForColumn:@"event"] forKey:@"event"];
                    [appDic setObject:[resultSetLog objectForColumn:OwlAppName] forKey:OwlAppName];
                    [_logArray addObject:appDic];
                }
            }
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createLogTable];
            }
            [self resortLogArray];
            
            FMResultSet *resultProfile = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProcProfileTable]];
            int iprofile = 0;
            while ([resultProfile  next])
            {
                if (iprofile == 0) {
                    _isWatchVedio = [resultProfile intForColumn:OwlWatchCamera];
                    _isWatchAudio = [resultProfile intForColumn:OwlWatchAudio];
                }
                iprofile++;
            }
            //兼容历史数据，删除多余的row
            if (iprofile > 1) {
                [db executeUpdate:[NSString stringWithFormat:@"delete from %@", OwlProcProfileTable]];
                NSString *strSQL = [NSString stringWithFormat:@"INSERT INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
                [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:_isWatchVedio], [NSNumber numberWithInt:_isWatchAudio]];
            }
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createProfileTable];
            }
            
            [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProBlockTable]];
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createBlockTable];
            }
        } else {
            NSLog(@"Error owl open db fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }
}
- (void)closeDB{
    if (db) {
        [db close];
        db = nil;
    }
}

- (NSMutableDictionary *)getAppInfoWithPath:(NSString*)appPath appName:(NSString*)name{
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
    NSString *appName = @"";
    
    if ([[[bubble localizedInfoDictionary] allKeys] containsObject:@"CFBundleDisplayName"]) {
        appName = [[bubble localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    } else {
        if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleName"]) {
            appName = [[bubble infoDictionary] objectForKey:@"CFBundleName"];
        } else {
            appName = [[bubble infoDictionary] objectForKey:@"CFBundleExecutable"];
        }
    }
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
    [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
    [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
    
    return appDic;
}

- (void)setWatchVedioToDB:(BOOL)state{
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
    //这里要传oc对象类型，不支持传基础数据类型
    [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:_isWatchVedio], [NSNumber numberWithInt:_isWatchAudio]];
//    [db executeUpdate:strSQL, _isWatchVedio ? 1 : 0, _isWatchAudio ? 1 : 0];
//    [db executeUpdate:strSQL, @"1", @"0"];
}
- (void)setWatchAudioToDB:(BOOL)state{
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
    [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:_isWatchVedio], [NSNumber numberWithInt:_isWatchAudio]];
}

- (void)addAppWhiteItemToDB:(NSDictionary*)dic{
//    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlAppWhiteTable]];
//    NSLog(@"[resultSet columnCount]: %d", [resultSet columnCount]);
//    NSLog(@"columnNameToIndexMap: %@", [resultSet columnNameToIndexMap]);
//    BOOL hasNewOwlWatchCamera = YES;
//    if (![[[resultSet columnNameToIndexMap] allKeys] containsObject:OwlWatchCamera]) {
//        hasNewOwlWatchCamera = NO;
//    }
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@,%@,%@,%@,%@,%@) VALUES  (?,?,?,?,?,?,?,?);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
    [db executeUpdate:strSQL, [dic objectForKey:OwlAppName],[dic objectForKey:OwlExecutableName],[dic objectForKey:OwlBubblePath],[dic objectForKey:OwlIdentifier],[dic objectForKey:OwlAppIcon],[dic objectForKey:OwlAppleApp],[dic objectForKey:OwlWatchCamera],[dic objectForKey:OwlWatchAudio]];
}
- (void)resaveWhiteListToDB{
    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", OwlAppWhiteTable]];
    for (NSDictionary *dic in _wlArray) {
        [self addAppWhiteItemToDB:dic];
    }
}
- (void)removeAppWhiteItemToDB:(NSDictionary*)dic{
    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", OwlAppWhiteTable, OwlIdentifier], [dic objectForKey:OwlIdentifier]];
}

- (void)resortLogArray{
    NSArray *tmpLogArray = [self.logArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj2 objectForKey:@"time"] compare:((NSString *)[obj1 objectForKey:@"time"])];
    }];
    self.logArray = [NSMutableArray arrayWithArray:tmpLogArray];
}
- (void)addLogItem:(NSString*)log appName:(NSString*)appName{
    NSLog(@"addVedioLogItem: %@", log);
    NSDate * date = [NSDate date];
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate * currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    NSDateFormatter * df = [[NSDateFormatter alloc] init ];
    [df setDateFormat:@"yyyy.MM.dd  HH:mm:ss"];
    NSString *na = [df stringFromDate:currentDate];
    [self.logArray addObject:@{@"time": na, OwlAppName:appName, @"event": log}];
    [self resortLogArray];
    
    [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (time,%@,event) VALUES  (?,?,?);", OwlProcLogTable, OwlAppName], na,appName,log];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OwlLogChangeNotication object:nil];
    });
}


#pragma mark owl camera device watch
- (void)watchTimerRepeat{
    OwlCompleteBlock complete = ^{
        
    };
    [self doOwlProcResultWithDeviceState:1 complete: complete];
}
- (void)startWatchTimer{
    // Note: Change Device state, start monitor!
    //[self.avMonitor start];
    //[[McCoreFunction shareCoreFuction] changeOwlDeviceProcInfo:deviceType deviceState:1];
    
    
//    if (self.watchingTimer) {
//        return;
//    }
//    self.watchingTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(watchTimerRepeat) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.watchingTimer forMode:NSDefaultRunLoopMode];
}
- (void)stopWatchTimer{
    NSLog(@"stopWatchTimer, isWatchingVedio: %d, isWatchingAudio: %d", self.isWatchingVedio, self.isWatchingAudio);
    if (self.isWatchingVedio || self.isWatchingAudio) {
        return;
    }
    if (self.watchingTimer) {
        //[[McCoreFunction shareCoreFuction] changeOwlDeviceProcInfo:0 deviceState:0];
        [self.watchingTimer invalidate];
        self.watchingTimer = nil;
    }
//    NSDictionary *useDic = @{@"isWatchVedio": @(self.isWatchVedio), @"isWatchingVedio": @(self.isWatchingVedio), @"isWatchAudio": @(self.isWatchAudio), @"isWatchingAudio": @(self.isWatchingAudio)};
//    [self analyseDeviceInfoForNotificationUseDic:useDic];
}
- (void)processVedioEndItems{
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
- (void)processAudioEndItems{
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
- (void)startCameraWatchTimer{
    self.isWatchingVedio = YES;
    //__weak typeof(self) weakSelf = self;
//    OwlCompleteBlock complete = ^{
//    };
//    [self doOwlProcResultWithDeviceState:1 complete: complete];
    [self startWatchTimer];
    
    NSLog(@"startCameraWatchTimer, isWatchingVedio: %d, isWatchingAudio: %d", self.isWatchingVedio, self.isWatchingAudio);
}
- (void)stopCameraWatchTimer{
    __weak typeof(self) weakSelf = self;
    OwlCompleteBlock complete = ^{
        //停止检测
        weakSelf.isWatchingVedio = NO;
        [weakSelf stopWatchTimer];
        
        //处理没有配对的项
        //[weakSelf processVedioEndItems];
    };
    
    // Note: Change Device state, stop monitor!
    [self stopWatchWithComplete:complete];
    
    NSLog(@"stopCameraWatchTimer, isWatchingVedio: %d, isWatchingAudio: %d", self.isWatchingVedio, self.isWatchingAudio);
    
    //[self doOwlProcResultWithDeviceState:0 complete: complete];
}

- (void)startAudioWatchTimer{
    self.isWatchingAudio = YES;
    //__weak typeof(self) weakSelf = self;
//    OwlCompleteBlock complete = ^{
//    };
//    [self doOwlProcResultWithDeviceState:1 complete: complete];
    [self startWatchTimer];
    
    NSLog(@"startAudioWatchTimer, isWatchingVedio: %d, isWatchingAudio: %d", self.isWatchingVedio, self.isWatchingAudio);
}
- (void)stopAudioWatchTimer{
    __weak typeof(self) weakSelf = self;
    OwlCompleteBlock complete = ^{
        //停止检测
        weakSelf.isWatchingAudio = NO;
        [weakSelf stopWatchTimer];
        
        //处理没有配对的项
        //[weakSelf processAudioEndItems];
    };
    
    // Note: Change Device state, stop monitor!
    [self stopWatchWithComplete:complete];
    
    [self processedWatch:Device_Microphone state:NSControlStateValueOff client:nil];
    NSLog(@"stopAudioWatchTimer, isWatchingVedio: %d, isWatchingAudio: %d", self.isWatchingVedio, self.isWatchingAudio);
    
    //[self doOwlProcResultWithDeviceState:0 complete: complete];
}

- (void)stopWatchWithComplete:(OwlCompleteBlock) complete {
    // Note: Stop Device monitor!
    //[self.avMonitor stop];
    
    complete();
    //[[McCoreFunction shareCoreFuction] changeOwlDeviceProcInfo:deviceType deviceState:0];
}

- (void)processedWatch:(AVDevice)device state:(NSControlStateValue)state client:(Client *)client {
    NSMutableArray *resArray = [NSMutableArray array];
    if (Device_Microphone == device) {
        if (client) {
            //信息完整，开启，与单个关闭
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:client.name.UTF8String];
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:client.path.UTF8String];
            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
            
//            if (state == NSControlStateValueOn) {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//            } else {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//            }
            
            dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
            [resArray addObject:dicItem];
            [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            if (![self.owlAudioItemDic objectForKey:client.name]) {
                [self.notificationDetailArray addObjectsFromArray:resArray];
            }
            
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
        } else {
            //client 空（多个mic，全关才会回调
            if ([self.audioObserver isAudioDeviceActive]) {
                return;
            }
            [self.avMonitor.audioClients removeAllObjects];
            
            for (NSString *key in self.owlAudioItemDic) {
                NSMutableDictionary *dicItem = self.owlAudioItemDic[key];
                if ([dicItem isKindOfClass:[NSMutableDictionary class]]) {
                    dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
                    NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
                    [resArray addObject:dicItem];
                }
            }
//            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
//            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
//            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:"未知设备"];
//            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:VDCAssistantPath.UTF8String];
//            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
//            if (state == NSControlStateValueOn) {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//            } else {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//            }
//            [resArray addObject:dicItem];
//            [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
//            NSLog(@"!!!! mic %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
        }
    } else if (Device_Camera == device) {
        if (client) {
            //信息完整
            NSMutableDictionary *dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:client.name.UTF8String];
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:client.path.UTF8String];
            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
            
            if (state == NSControlStateValueOn) {
                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
            } else {
                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
            }
            
            [resArray addObject:dicItem];
            [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_ID]];
            [self.notificationDetailArray addObjectsFromArray:resArray];
            [self analyseDeviceInfoForNotificationWithArray:resArray];
            NSLog(@"!!!! video %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
        } else {
//            NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
//
//            dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:client.pid.intValue];
//            dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:"未知设备"];
//            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:VDCAssistantPath.UTF8String];
//            dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
//
//            if (state == NSControlStateValueOn) {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//            } else {
//                dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//            }
//
//            [resArray addObject:dicItem];
//            [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//
//            [self.notificationDetailArray addObjectsFromArray:resArray];
//            [self analyseDeviceInfoForNotificationWithArray:resArray];
//            NSLog(@"!!!! video %@ %@", dicItem[OWL_PROC_NAME], dicItem[OWL_PROC_DELTA]);
            
//            // #001
//            for (Client *cl in self.avMonitor.videoClients) {
//                NSMutableDictionary* dicItem = [self.owlVedioItemDic objectForKey:cl.name];
//                if (dicItem) {
//                    dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//                    [resArray addObject:dicItem];
//                    break;
//                } else if (resArray.count == 0) {
//
//                    NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
//
//                    dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:cl.pid.intValue];
//                    dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:cl.name.UTF8String];
//                    dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:cl.path.UTF8String];
//                    dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
//
//                    if (state == NSControlStateValueOn) {
//                        dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//                    } else {
//                        dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//                    }
//
//                    [resArray addObject:dicItem];
//
//                    if (device == Device_Camera) {
//                        [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                    } else {
//                        [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                    }
//                }
//            }
//            if (resArray.count == 0) {
//                for (Client *cl in self.avMonitor.audioClients) {
//                    NSMutableDictionary* dicItem = [self.owlAudioItemDic objectForKey:cl.name];
//                    if (dicItem) {
//                        dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//                        [resArray addObject:dicItem];
//                        break;
//                    } else if (resArray.count == 0) {
//
//                        NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
//
//                        dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:cl.pid.intValue];
//                        dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:cl.name.UTF8String];
//                        dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:cl.path.UTF8String];
//                        dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
//
//                        if (state == NSControlStateValueOn) {
//                            dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//                        } else {
//                            dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//                        }
//
//                        [resArray addObject:dicItem];
//
//                        if (device == Device_Camera) {
//                            [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                        } else {
//                            [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                        }
//                    }
//                }
//            }
//
//            // #002
//            if (resArray.count == 0) {
//
//                NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
//
//                dicItem[OWL_PROC_ID] = [NSNumber numberWithInt:0];
//                dicItem[OWL_DEVICE_TYPE] = [NSNumber numberWithInt:device];
//
//                if (state == NSControlStateValueOn) {
//                    dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:1];
//                } else {
//                    dicItem[OWL_PROC_DELTA] = [NSNumber numberWithInt:-1];
//                }
//
//                if (device == Device_Camera) {
//                    dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:"Device"];
//                    dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:VDCAssistantPath.UTF8String];
//
//                    [self.owlVedioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                } else {
//                    dicItem[OWL_PROC_NAME] = [NSString stringWithUTF8String:"Device"];
//                    dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:AudioAssistantPath.UTF8String];
//
//                    [self.owlAudioItemDic setObject:dicItem forKey:dicItem[OWL_PROC_NAME]];
//                }
//
//                [resArray addObject:dicItem];
//            }
//
//
//            // #003
//            int deviceType = [self getDeviceType];
//            if (device == Device_Camera && (deviceType == 1 || deviceType == 4)) {
//                if (resArray.count > 0) {
//                    [self.notificationDetailArray addObjectsFromArray:resArray];
//                    [self analyseDeviceInfoForNotificationWithArray:resArray];
//                } else {
//                    [self processVedioEndItems];
//                }
//                if (state == NSControlStateValueOff) {
//                    [self.avMonitor.videoClients removeAllObjects];
//                }
//            } else if (deviceType == 2 || deviceType == 4){
//                if (resArray.count > 0) {
//                    [self.notificationDetailArray addObjectsFromArray:resArray];
//                    [self analyseDeviceInfoForNotificationWithArray:resArray];
//                } else {
//                    [self processAudioEndItems];
//                }
//                if (state == NSControlStateValueOff) {
//                    [self.avMonitor.audioClients removeAllObjects];
//                }
//            }
        }
    }
}

- (void)postVedioChangeNotifocationForUsingStatue:(BOOL)isUsing{
    NSLog(@"postVedioChangeNotifocationForUsingStatue: %d", self.isWatchingVedio);
    if (self.isWatchingVedio != isUsing) {
        return;
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    NSString *stringTitle = self.cameraObserver.cameraName;
    if (isUsing) {
        notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_postVedioChangeNotifocationForUsingStatue_notification_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else {
        notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_postVedioChangeNotifocationForUsingStatue_notification_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    //[notification setValue:[NSImage imageNamed:NSImageNameApplicationIcon] forKey:@"_identityImage"];
    //notification.contentImage = [NSImage imageNamed:NSImageNameApplicationIcon];
    notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type: %ld count:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], (long)OwlProtectVedio, self.notificationCount, [[NSDate date] description]];
    self.notificationCount++;
    notification.informativeText = self.cameraObserver.cameraName;
    notification.hasActionButton = NO;
    notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlManager_postVedioChangeNotifocationForUsingStatue_1553136870_3", nil, [NSBundle bundleForClass:[self class]], @"");
    notification.userInfo = @{OWL_PROC_NAME : @"FindNull", OWL_PROC_PATH :  @"FindNull", OWL_PROC_ID :  @"FindNull", @"TYPE": @"nothing", @"APPTYPE": @(OwlProtectVedio)};
    
    [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                               key:kOwlVedioNotification];
    
    if (isUsing) {
        [self addLogItem:[stringTitle stringByAppendingString:@" 使用中"] appName:@""];
    } else {
        [self addLogItem:[stringTitle stringByAppendingString:@" 已停止使用"] appName:@""];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center removeDeliveredNotification:notification];
    });
}
- (void)postAudioChangeNotifocationForUsingStatue:(BOOL)isUsing{
    NSLog(@"postAudioChangeNotifocationForUsingStatue: %d", self.isWatchingAudio);
    if (self.isWatchingAudio != isUsing) {
        return;
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    NSString *stringTitle = self.audioObserver.audioName;
    if (isUsing) {
        notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_postAudioChangeNotifocationForUsingStatue_notification_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else {
        notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_postAudioChangeNotifocationForUsingStatue_notification_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    //[notification setValue:[NSImage imageNamed:NSImageNameApplicationIcon] forKey:@"_identityImage"];
    //notification.contentImage = [NSImage imageNamed:NSImageNameApplicationIcon];
    notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type: %ld count:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], (long)OwlProtectAudio, self.notificationCount, [[NSDate date] description]];
    self.notificationCount++;
    notification.informativeText = self.audioObserver.audioName;
    notification.hasActionButton = NO;
    notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlManager_postAudioChangeNotifocationForUsingStatue_1553136870_3", nil, [NSBundle bundleForClass:[self class]], @"");
    notification.userInfo = @{OWL_PROC_NAME : @"FindNull", OWL_PROC_PATH :  @"FindNull", OWL_PROC_ID :  @"FindNull", @"TYPE": @"nothing", @"APPTYPE": @(OwlProtectAudio)};
    
    [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                               key:kOwlVedioNotification];
    
    if (isUsing) {
        [self addLogItem:[stringTitle stringByAppendingString:@" 使用中"] appName:@""];
    } else {
        [self addLogItem:[stringTitle stringByAppendingString:@" 已停止使用"] appName:@""];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center removeDeliveredNotification:notification];
    });
}
- (void)analyseDeviceInfoForNotificationWithArray:(NSArray*)itemArray{
    //NSLog(@"analyseDeviceInfoForNotificationWithArray:, %@", itemArray);
    if (!self.isWatchVedio && !self.isWatchAudio) {
        return;
    }
    //过滤掉一次性音频会来多次数据的问题，此时为异常，丢弃音频数据
    NSMutableArray *filterArray = [[NSMutableArray alloc] init];
    int audioCount = 0;
    for (NSDictionary *dic in itemArray) {
        int deviceType = [dic[OWL_DEVICE_TYPE] intValue];
        if (deviceType == OwlProtectAudio) {
            audioCount++;
        }
    }
    if (audioCount >= 3) {
        for (NSDictionary *dic in itemArray) {
            int deviceType = [dic[OWL_DEVICE_TYPE] intValue];
            if (deviceType != OwlProtectAudio) {
                [filterArray addObject:dic];
            }
        }
    } else {
        [filterArray addObjectsFromArray:itemArray];
    }
    for (NSDictionary *dic in filterArray) {
        //OWL_PROC_ID/OWL_PROC_NAME/OWL_PROC_PATH/OWL_PROC_DELTA/OWL_DEVICE_TYPE
        int deviceType = [dic[OWL_DEVICE_TYPE] intValue];
        int count = [[dic objectForKey:OWL_PROC_DELTA] intValue];
        NSString *appName = dic[OWL_PROC_NAME];
        if (!appName || [appName isEqualToString:@""] || [dic[OWL_PROC_ID] intValue] < 0) {
            NSLog(@"%s appName is %@, pid: %d", __FUNCTION__, appName, [dic[OWL_PROC_ID] intValue]);
            continue;
        }
        
        BOOL isWhite = NO;
        for (NSDictionary *item in self.wlArray) {
            if ([[item objectForKey:OwlExecutableName] isEqualToString:dic[OWL_PROC_NAME]]) {
                if (deviceType == OwlProtectVedio) {
                    if ([[item objectForKey:OwlWatchCamera] boolValue]) {
                        isWhite = YES;
                        break;
                    }
                } else if (deviceType == OwlProtectAudio) {
                    if ([[item objectForKey:OwlWatchAudio] boolValue]) {
                        isWhite = YES;
                        break;
                    }
                } else if (deviceType == OwlProtectVedioAndAudio) {
                    isWhite = NO;
                    break;
                }
                break;
            }
        }
        if (isWhite) {
            continue;
        }
        for (NSDictionary *item in self.allApps) {
            if ([[item objectForKey:OwlExecutableName] isEqualToString:dic[OWL_PROC_NAME]]) {
                NSLog(@"AppName: %@, %@, %@", appName, [item objectForKey:OwlExecutableName], [item objectForKey:OwlAppName]);
                //get bubble name to show and log（not use the excuName）
                //TODO: when if vedio or audio is stop， no get the strAppPath（path is nil）, for the performance, use the CFBundleExecutable
                //                NSFileManager *fm = [NSFileManager defaultManager];
                //                NSString *appPath = [item objectForKey:OwlBubblePath];
                //                if ([[appPath pathExtension] isEqualToString:@"app"]) {
                //                    if (![fm fileExistsAtPath:appPath]){
                //                        continue ;
                //                    }
                //                    NSBundle *bubble = [NSBundle bundleWithPath:appPath];
                //                    if (!bubble) {
                //                        continue ;
                //                    }
                //
                //                    if ([[[bubble localizedInfoDictionary] allKeys] containsObject:@"CFBundleDisplayName"]) {
                //                        appName = [[bubble localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
                //                    } else {
                //                        if ([[[bubble infoDictionary] allKeys] containsObject:@"CFBundleName"]) {
                //                            appName = [[bubble infoDictionary] objectForKey:@"CFBundleName"];
                //                        } else {
                //                            appName = [[bubble infoDictionary] objectForKey:@"CFBundleExecutable"];
                //                        }
                //                    }
                //                }
                //        NSLog(@"appPath: %@， AppName: %@", appPath, appName);
                appName = [item objectForKey:OwlAppName];
            }
        }
        if (appName == nil) {
            continue;
        }
        NSString *stringTitle = @"";
        
        NSNumber *appIdentifier = dic[OWL_PROC_ID]; // appName maybe repeat!
        //according to the agreement,
        //when count > 0, the corresponding process is start using camera
        //when count < 0, the corresponding process is stop using camera
        //when count = 0, nonthing
        if (deviceType == OwlProtectVedio) {
            if (!self.isWatchVedio) {
                continue;
            }
            NSDictionary *startDic = [self.owlVedioItemDic objectForKey:appIdentifier]; //appName
            if (count > 0) {
                //开始项count大于0
                if (startDic && [[startDic objectForKey:OWL_PROC_DELTA] intValue] > 0) {
                    //如果已经有开始过的，丢弃
                    //continue;
                }
                //[self.owlVedioItemDic setObject:dic forKey:appIdentifier]; //appName
            } else if (count < 0) {
                if (startDic == nil) {
                    //没有开始就结束的项，为检测异常项，丢弃
                    continue;
                } else {
                    //完成配对，移除开始项
                    //if ([self.owlItemDic allKeys].count == 1 && self.isWatchingVedio) {
                    
                    //}
                    [self.owlVedioItemDic removeObjectForKey:appIdentifier]; //appName
                }
            }
        }
        if (deviceType == OwlProtectAudio) {
            if (!self.isWatchAudio) {
                continue;
            }
            NSDictionary *startDic = [self.owlAudioItemDic objectForKey:appIdentifier]; //appName
            if (count > 0) {
                //开始项count大于0
                if (startDic && [[startDic objectForKey:OWL_PROC_DELTA] intValue] > 0) {
                    //如果已经有开始过的，丢弃
                    //continue;
                }
                //[self.owlAudioItemDic setObject:dic forKey:appIdentifier]; //appName
            } else if (count < 0) {
                if (startDic == nil) {
                    //没有开始就结束的项，为检测异常项，丢弃
                    continue;
                } else {
                    //完成配对，移除开始项
                    //if ([self.owlItemDic allKeys].count == 1 && self.isWatchingVedio) {
                    
                    //}
                    [self.owlAudioItemDic removeObjectForKey:appIdentifier]; //appName
                }
            }
        }
        if ((deviceType != OwlProtectVedio) && (deviceType != OwlProtectAudio) && (deviceType != OwlProtectVedioAndAudio)) {
            continue;
        }
        NSString *strLanguageKey = @"";
        if (count > 0) {
            if (deviceType == OwlProtectVedio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_1";
            } else if (deviceType == OwlProtectAudio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_2";
            } else if (deviceType == OwlProtectVedioAndAudio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_3";
            }
        } else if (count < 0) {
            if (deviceType == OwlProtectVedio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_4";
            } else if (deviceType == OwlProtectAudio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_5";
            } else if (deviceType == OwlProtectVedioAndAudio) {
                strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_6";
            }
        } else {
            continue;
        }
        stringTitle = [NSString stringWithFormat:@"%@  %@", appName, NSLocalizedStringFromTableInBundle(strLanguageKey, nil, [NSBundle bundleForClass:[self class]], @"")];
        if ([dic[OWL_PROC_NAME] length] == 0) {
            continue;
        }
        
        if (count != 0) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            if (count > 0) {
                if (deviceType == OwlProtectVedio) {
                    //notification.title = cameraObserver.cameraName;
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_7", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectAudio) {
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_8", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectVedioAndAudio) {
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_9", nil, [NSBundle bundleForClass:[self class]], @"");
                }
            } else if (count < 0) {
                if (deviceType == OwlProtectVedio) {
                    //notification.title = cameraObserver.cameraName;
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_10", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectAudio) {
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_11", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectVedioAndAudio) {
                    notification.title = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_notification_12", nil, [NSBundle bundleForClass:[self class]], @"");
                }
            }
            //[notification setValue:[NSImage imageNamed:NSImageNameApplicationIcon] forKey:@"_identityImage"];
            //notification.contentImage = [NSImage imageNamed:NSImageNameApplicationIcon];
            notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type:%d count:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], deviceType, self.notificationCount, [[NSDate date] description]];
            self.notificationCount++;
            notification.informativeText = stringTitle;
            
            // Note: (v4.8.9)由于无法直接kill掉Siri，弹窗显示不带阻止按钮！
            BOOL notActions = [dic[OWL_PROC_NAME] isEqualToString:@"Siri"];
            
            if (count > 0 && !notActions) {
                notification.hasActionButton = YES;
                notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_1553136870_13", nil, [NSBundle bundleForClass:[self class]], @"");
                notification.actionButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_1553136870_14", nil, [NSBundle bundleForClass:[self class]], @"");
                notification.userInfo = @{OWL_PROC_NAME : dic[OWL_PROC_NAME], OWL_PROC_PATH : dic[OWL_PROC_PATH], OWL_PROC_ID : dic[OWL_PROC_ID], @"TYPE": @"allow", @"APPTYPE": @(deviceType)};
            } else if (count < 0 || notActions) {
                notification.hasActionButton = NO;
                notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlManager_analyseDeviceInfoForNotificationWithArray_1553136870_15", nil, [NSBundle bundleForClass:[self class]], @"");
                notification.userInfo = @{OWL_PROC_NAME : dic[OWL_PROC_NAME], OWL_PROC_PATH : dic[OWL_PROC_PATH], OWL_PROC_ID : dic[OWL_PROC_ID], @"TYPE": @"nothing", @"APPTYPE": @(deviceType)};
            } else {
            }
            
            if (deviceType == OwlProtectVedio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                           key:kOwlVedioNotification];
            } else if (deviceType == OwlProtectAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                           key:kOwlAudioNotification];
            } else if (deviceType == OwlProtectVedioAndAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                           key:kOwlVedioAndAudioNotification];
            }
            //NSLog(@"postAudioChangeNotifocationForUsingStatue: %@", notification.userInfo);
            //[[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
            @try{
                //[self addLogItem:[stringTitle stringByReplacingOccurrencesOfString:appName withString:@""] appName:appName];
                [self addLogItem:strLanguageKey appName:appName];
            }
            @catch (NSException *exception) {
                
            }
            //[self performSelectorOnMainThread:@selector(addLogItem:appName:) withObject:stringTitle waitUntilDone:NO];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
//                [center removeDeliveredNotification:notification];
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
            });
        }
    }
    //}
}
- (void)doOwlProcResultWithDeviceState:(int)deviceState complete: (OwlCompleteBlock) complete{
    //11.3及以上系统暂时屏蔽隐私防护功能入口
#if DISABLED_PRIVACY_MAX1103
    if (@available(macOS 11.3, *)) {
        return;
    }
#endif
    if (!self.isWatchVedio && !self.isWatchAudio) {
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
    BOOL tempWatchingVedio = self.isWatchVedio;
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

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([[notification.userInfo objectForKey:@"TYPE"] isEqualToString:@"allow"]) {
        int deviceType = [[notification.userInfo objectForKey:@"APPTYPE"] intValue];
        
        // Note: `UNNotificationActionDidAllow` 从`UNNotification` 中触发的操作
        NSString *actionId = [notification.userInfo objectForKey:@"ACTION_ID"];
        if (notification.activationType == NSUserNotificationActivationTypeContentsClicked
            || ![actionId isEqualToString:UNNotificationActionDidBlock]) {
            if (deviceType == OwlProtectVedio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwlVedioNotification flagsBlock:nil];
            } else if (deviceType == OwlProtectAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwlAudioNotification flagsBlock:nil];
            } else if (deviceType == OwlProtectVedioAndAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwlVedioAndAudioNotification flagsBlock:nil];
            }
        } else if (notification.activationType == NSUserNotificationActivationTypeActionButtonClicked
                   || [actionId isEqualToString:UNNotificationActionDidBlock]) {
            NSString *executableName = [notification.userInfo objectForKey:OWL_PROC_NAME];
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProBlockTable]];
            BOOL exist = NO;
            while ([resultSet next]) {
                if ([[resultSet objectForColumn:OwlExecutableName] isEqualToString:executableName]) {
                    exist = YES;
                }
            }
            if (!exist)
            {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.alertStyle = NSAlertStyleInformational;
                if (deviceType == OwlProtectVedio) {
                    alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectAudio) {
                    alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_2", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if (deviceType == OwlProtectVedioAndAudio) {
                    alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_3", nil, [NSBundle bundleForClass:[self class]], @"");
                }
                alert.informativeText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_4", nil, [NSBundle bundleForClass:[self class]], @"");
                [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_ok_2", nil, [NSBundle bundleForClass:[self class]], @"")];
                [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_cancel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
                
                NSInteger responseTag = [alert runModal];
                if (responseTag == NSAlertFirstButtonReturn) {
                    [[McCoreFunction shareCoreFuction] killProcessByID:[[notification.userInfo objectForKey:OWL_PROC_ID] intValue]];
                }
                
                [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES  (?);", OwlProBlockTable, OwlExecutableName], executableName];
            } else {
                [[McCoreFunction shareCoreFuction] killProcessByID:[[notification.userInfo objectForKey:OWL_PROC_ID] intValue]];
            }
        } else {
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
    NSLog(@"notification.userInfo: %@", notification.userInfo);
    if ([[notification.userInfo objectForKey:@"TYPE"] isEqualToString:@"allow"]) {
        int deviceType = [[notification.userInfo objectForKey:@"APPTYPE"] intValue];
        NSNumber *watchCamera = [NSNumber numberWithBool:NO];
        NSNumber *watchAudio = [NSNumber numberWithBool:NO];
        if (deviceType == OwlProtectVedio) {
            watchCamera = [NSNumber numberWithBool:YES];
            watchAudio = [NSNumber numberWithBool:NO];
        } else if (deviceType == OwlProtectAudio) {
            watchCamera = [NSNumber numberWithBool:NO];
            watchAudio = [NSNumber numberWithBool:YES];
        } else if (deviceType == OwlProtectVedioAndAudio) {
            watchCamera = [NSNumber numberWithBool:YES];
            watchAudio = [NSNumber numberWithBool:YES];
        }
        NSString *executableName = [notification.userInfo objectForKey:OWL_PROC_NAME];
        if (executableName == nil) {
            return;
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_5", nil, [NSBundle bundleForClass:[self class]], @"");
        alert.informativeText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_6", nil, [NSBundle bundleForClass:[self class]], @"");
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_7", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_8", nil, [NSBundle bundleForClass:[self class]], @"")];
        
        NSInteger responseTag = [alert runModal];
        if (responseTag == NSAlertFirstButtonReturn) {
            BOOL isExist = NO;
            for (NSMutableDictionary *subDic in self.wlArray) {
                if ([[subDic objectForKey:OwlExecutableName] isEqualToString:executableName]) {
                    isExist = YES;
                    int index = (int)[self.wlArray indexOfObject:subDic];
                    if (deviceType == OwlProtectVedio) {
                        [subDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
                    } else if (deviceType == OwlProtectAudio) {
                        [subDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
                    } else if (deviceType == OwlProtectVedioAndAudio) {
                        [subDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
                        [subDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
                    }
                    [self.wlArray replaceObjectAtIndex:index withObject:subDic];
                    [self replaceAppWhiteItemIndex:index];
                    [[NSNotificationCenter defaultCenter] postNotificationName:OwlWhiteListChangeNotication object:nil];
                    break;
                }
            }
            if (!isExist) {
                NSString *proc_path = [notification.userInfo objectForKey:OWL_PROC_PATH];
                NSLog(@"proc_path: %@", proc_path);
                // /Applications/Photo Booth.app/Contents/MacOS/Photo Booth
                NSString *appPath = [[[proc_path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
                if ([[appPath pathExtension] isEqualToString:@"app"]) {
                    NSString *appName = [appPath lastPathComponent];
                    NSMutableDictionary *resDic = [self getAppInfoWithPath:[appPath stringByDeletingLastPathComponent] appName:appName];
                    if (resDic) {
                        [resDic setObject:watchCamera forKey:OwlWatchCamera];
                        [resDic setObject:watchAudio forKey:OwlWatchAudio];
                        [self addAppWhiteItem:resDic];
                    }
                } else {
                    NSLog(@"proc is not app type");
                    NSNumber *appleApp;
                    if ([executableName hasPrefix:@"com.apple"]) {
                        appleApp = [NSNumber numberWithBool:YES];
                    } else {
                        appleApp = [NSNumber numberWithBool:NO];
                    }
                    if (proc_path == nil) {
                        proc_path = @"";
                    }
                    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] init];
                    [appDic setObject:executableName forKey:OwlAppName];
                    [appDic setObject:executableName forKey:OwlExecutableName];
                    [appDic setObject:proc_path forKey:OwlBubblePath];
                    [appDic setObject:executableName forKey:OwlIdentifier];
                    [appDic setObject:@"console" forKey:OwlAppIcon];
                    [appDic setObject:appleApp forKey:OwlAppleApp];
                    [appDic setObject:watchCamera forKey:OwlWatchCamera];
                    [appDic setObject:watchAudio forKey:OwlWatchAudio];
                    [appDic setObject:executableName forKey:OwlAppName];
                    [self addAppWhiteItem:appDic];
                }
            }
        } else {
            
        }
    } else {
        
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
