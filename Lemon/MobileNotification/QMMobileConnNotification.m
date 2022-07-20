//
//  QMMobileConnNotification.m
//  LemonMonitor
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QMMobileConnNotification.h"
#import "QMUserNotificationCenter.h"
#import "LemonDaemonConst.h"
#import <Cocoa/Cocoa.h>

#define kMobileNotificationKey  @"mobileconn"

@interface QMMobileConnNotification()
{
//    MobileDeviceAccess * _mobileDeviceAccess;
}
@property (nonatomic, assign) BOOL showNotification;

@end

#define kQQMacMgrBundle @"com.tencent.Lemon"

@implementation QMMobileConnNotification

- (id)init
{
    if (self = [super init])
    {
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:kMobileNotificationKey];
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            _mobileDeviceAccess = [MobileDeviceAccess singleton];
//            [_mobileDeviceAccess setListener:(id<MobileDeviceAccessListener>)self];
//
//            while (YES) {
//
//                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//                usleep(1000 * 10);
//            }
//        });
        
        NSNotificationCenter *  center = [[NSWorkspace sharedWorkspace] notificationCenter];
        
        // Install the notifications.
        [center addObserver:self
                   selector:@selector(appLaunched:)
                       name:NSWorkspaceDidLaunchApplicationNotification
                     object:nil];
    }
    return self;
}

- (BOOL)_qqMacMgrLaunched
{
    NSArray * array = [NSRunningApplication runningApplicationsWithBundleIdentifier:kQQMacMgrBundle];
    return [array count] > 0;
}

- (void)_removeUserNotification:(NSString *)uuid
{
    BOOL (^flags)(NSDictionary * info); //Block declaration returns BOOL, params inc. id and BOOL
    //body of block gets the block literal ^(id obj, NSUInteger idx, Bool *stop)... and the body logic
    if (uuid)
    {
        flags = ^ (NSDictionary * info) {
            if ([[info objectForKey:@"udid"] isEqualToString:uuid])
                return YES;
            return NO;
        };
    }
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kMobileNotificationKey
                                                                                      flagsBlock:flags];
}
         
#pragma mark-
#pragma mark launch application notification

- (void)appLaunched:(NSNotification *)notification
{
    NSDictionary * dict = [notification userInfo];
    if ([[dict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kQQMacMgrBundle])
        [self _removeUserNotification:nil];
}

#pragma mark-
#pragma mark ios device delegate

/// This method will be called whenever a device is connected
//- (void)deviceConnected:(AMDevice*)device
//{
//    if (!_showNotification)
//        return;
//    if (!device.udid || !device.deviceName || !device.productType)
//        return;
//
//    // 读取配置是否弹出通知
//    CFStringRef bundleRef = (__bridge CFStringRef)kQQMacMgrBundle;
//    NSNumber * num = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("MobileConnNotification"), bundleRef));
//    if (num && ![num boolValue])
//        return;
//    [self _removeUserNotification:device.udid];
//
//    NSUserNotification *notification = [[NSUserNotification alloc] init];
//    notification.title = [NSString stringWithFormat:@"%@已接入", device.deviceName];
//    notification.informativeText = @"马上使用电脑管家做个清理吧！";
//    notification.hasActionButton = YES;
//    notification.actionButtonTitle = @"立即清理";
//    notification.otherButtonTitle = @"关闭";
//    if ([notification respondsToSelector:NSSelectorFromString(@"set_alternateActionButtonTitles:")])
//        [notification setValue:@[@"立即清理", @"不再提示"] forKey:@"_alternateActionButtonTitles"];
//    if ([notification respondsToSelector:NSSelectorFromString(@"set_alwaysShowAlternateActionMenu:")])
//        [notification setValue:@(YES) forKey:@"_alwaysShowAlternateActionMenu"];
//    notification.deliveryDate = [NSDate dateWithTimeIntervalSinceNow:2];
//    notification.userInfo = @{@"udid" : device.udid};
//
//    [[QMUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification
//                                                                               key:kMobileNotificationKey];
//}
//
///// This method will be called whenever a device is disconnected
//- (void)deviceDisconnected:(AMDevice*)device
//{
//    [self _removeUserNotification:device.udid];
//}

#pragma mark-
#pragma mark user notification

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
}
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSNumber * num = nil;
    if ([notification respondsToSelector:NSSelectorFromString(@"_alternateActionIndex")])
    {
        num = [notification valueForKey:@"_alternateActionIndex"];
    }
    else
    {
        num = @(0);
    }
    
    if ([num integerValue] == 0)
    {
        NSDictionary * userInfo = [notification userInfo];
        NSString * udid = [userInfo objectForKey:@"udid"];
        if (udid)
        {
            NSArray * arguments = @[@"-tab", @"mc", @"-scan", udid];
            if (![self _qqMacMgrLaunched])
            {
                NSURL * url = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:DEFAULT_APP_PATH])
                    url = [NSURL fileURLWithPath:DEFAULT_APP_PATH];
                else
                    url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:kQQMacMgrBundle];
                if (url)
                {
                    NSDictionary * dict = @{NSWorkspaceLaunchConfigurationArguments: arguments};
                    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url
                                                                  options:NSWorkspaceLaunchDefault
                                                            configuration:dict
                                                                    error:nil];
                }
            }
            else
            {
            }
        }
    }
    else
    {
        if (![self _qqMacMgrLaunched])
        {
            CFStringRef bundleRef = (__bridge CFStringRef)kQQMacMgrBundle;
            CFPreferencesSetAppValue(CFSTR("MobileConnNotification"), (__bridge CFPropertyListRef)(@(NO)), bundleRef);
            CFPreferencesAppSynchronize(bundleRef);
        }
        else
        {
            
        }
    }
    
    [self _removeUserNotification:nil];
}

+ (instancetype)sharedMobileConn
{
    static QMMobileConnNotification * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance)
            instance = [[QMMobileConnNotification alloc] init];
    });
    return instance;
}

+ (void)startNotification
{
    [[QMMobileConnNotification sharedMobileConn] setShowNotification:YES];
}

+ (void)stopNotification
{
    [[QMMobileConnNotification sharedMobileConn] setShowNotification:NO];
}

@end
