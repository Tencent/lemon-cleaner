//
//  Owl2Manager+Notification.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Notification.h"
#import "NSUserNotification+QMExtensions.h"
#import "OwlConstant.h"
#import "LemonDaemonConst.h"
#import "Owl2Manager+Database.h"
#import <QMCoreFunction/LMReferenceDefines.h>
#import "utilities.h"
#import "Owl2NotificationItem.h"

NSNotificationName const Owl2WhiteListChangeNotication = @"OwlWhiteListChangeNotication";
NSNotificationName const Owl2LogChangeNotication = @"OwlLogChangeNotication";
NSNotificationName const Owl2ShowWindowNotication = @"OwlShowWindowNotication";

NSNotificationName const kOwl2VedioNotification = @"kOwlVedioNotification";
NSNotificationName const kOwl2AudioNotification = @"kOwlAudioNotification";
NSNotificationName const kOwl2VedioAndAudioNotification = @"kOwlVedioAndAudioNotification";
NSNotificationName const kOwl2SystemAudioNotification = @"kOwl2SystemAudioNotification";
NSNotificationName const kOwl2ScreenNotification = @"kOwl2ScreenNotification";


NSString * const kUNNotificationActionPreventButtonDidBlock = @"kUNNotificationActionPreventButtonDidBlock";

static NSString * const kSuffixApp = @".app/";
static NSString * const kSuffixAppex = @".appex/";

@interface Owl2ManagerNotificationCustomObject : NSObject
@property (nonatomic, copy) dispatch_block_t countdownCompleted;
@end

@implementation Owl2ManagerNotificationCustomObject @end


@implementation Owl2Manager (Notification)

- (void)registeNotificationDelegate
{
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2VedioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2AudioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2VedioAndAudioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2SystemAudioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2ScreenNotification];
}

- (void)analyseDeviceInfoForNotificationWithArray:(NSArray<NSDictionary *>*)itemArray;
{
    NSLog(@"analyseDeviceInfoForNotificationWithArray:, %@", itemArray);
    
    // 未开启
    if (!self.isWatchVideo && !self.isWatchAudio && !self.isWatchScreen) {
        return;
    }
    //过滤掉一次性音频会来多次数据的问题，此时为异常，丢弃音频数据
    NSArray *filterArray = [self filterDuplicateAudioWithArray:itemArray];
    
    for (NSDictionary *originDic in filterArray) {
        Owl2LogProcessItem *processItem = [[Owl2LogProcessItem alloc] initWithProcessDic:originDic];
        
        // 过滤无效项
        if (![self isValidDataWithProcessItem:processItem]) {
            NSLog(@"%s appName is %@, pid: %@, deviceType: %@", __PRETTY_FUNCTION__, processItem.name, processItem.pid, processItem.deviceType);
            continue;
        }
        
        // 命中白名单
        if ([self isWhitelistedWithProcessItem:processItem]) {
            continue;
        }
        
        // 对应开关关闭
        if (![self isSwitchStateMatchWithProcessItem:processItem]) {
            continue;
        }
        
        // 开始结束不成对
        if (![self startOrStopMatchWithProcessItem:processItem]) {
            continue;
        }
        // 递送通知
        [self createAndDeliverNotificationWithProcessItem:processItem];
    }
}

//过滤掉一次性音频会来多次数据的问题，此时为异常，丢弃音频数据
- (NSArray<NSDictionary *> *)filterDuplicateAudioWithArray:(NSArray<NSDictionary *>*)itemArray {
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
    return filterArray.copy;
}

// 判断是否有效
- (BOOL)isValidDataWithProcessItem:(Owl2LogProcessItem *)processItem {
    NSString *appName = processItem.name;
    if (!appName ||
        [appName isEqualToString:@""] ||
        [appName isEqualToString:@"corespeechd"] ||
        [appName isEqualToString:@"replayd"] ||
        [processItem.pid intValue] < 0) {
        return NO;
    }
    
    if ((processItem.convenient_hardware != Owl2LogHardwareVedio)
        && (processItem.convenient_hardware != Owl2LogHardwareAudio)
        && (processItem.convenient_hardware != Owl2LogHardwareSystemAudio)
        && (processItem.convenient_hardware != Owl2LogHardwareScreen)) {
        return NO;
    }
    return YES;
}

// 是否命中白名单
- (BOOL)isWhitelistedWithProcessItem:(Owl2LogProcessItem *)processItem {
    [processItem.convenient_mainAppItem syncUpdateWL:self.wlDic];
    return [processItem convenient_hitWhiteList];
}

// 开关开启匹配
- (BOOL)isSwitchStateMatchWithProcessItem:(Owl2LogProcessItem *)processItem {
    if (processItem.convenient_hardware == Owl2LogHardwareVedio) {
        return self.isWatchVideo;
    }
    if (processItem.convenient_hardware == Owl2LogHardwareAudio) {
        return self.isWatchAudio;
    }
    if (processItem.convenient_hardware == Owl2LogHardwareSystemAudio) {
        return self.isWatchAudio;
    }
    if (processItem.convenient_hardware == Owl2LogHardwareScreen) {
        return self.isWatchScreen;
    }
    return NO;
}

// 当开始/结束不成对的时候，返回NO，否则返回YES
- (BOOL)startOrStopMatchWithProcessItem:(Owl2LogProcessItem *)processItem {
    if (processItem.convenient_hardware == Owl2LogHardwareVedio) {
        return [self __startOrStopMatchWithOwlItemDic:self.owlVideoItemDic processItem:processItem];
    }
    if (processItem.convenient_hardware == Owl2LogHardwareAudio) {
        return [self __startOrStopMatchWithOwlItemDic:self.owlAudioItemDic processItem:processItem];
    }
    if (processItem.convenient_hardware == Owl2LogHardwareSystemAudio) {
        return [self __startOrStopMatchWithOwlItemDic:self.owlSystemAudioItemDic processItem:processItem];
    }
    if (processItem.convenient_hardware == Owl2LogHardwareScreen) {
        return [self __startOrStopMatchWithOwlItemDic:self.owlScreenItemDic processItem:processItem];
    }
    return NO;
}

- (BOOL)__startOrStopMatchWithOwlItemDic:(NSMutableDictionary *)itemDic processItem:(Owl2LogProcessItem *)processItem {
    NSNumber *pid = processItem.pid;
    NSInteger count = processItem.delta.intValue;
    NSDictionary *startDic = [itemDic objectForKey:pid]; //appName
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
            return NO;
        } else {
            //完成配对，移除开始项
            //if ([self.owlItemDic allKeys].count == 1 && self.isWatchingVedio) {
            
            //}
            [itemDic removeObjectForKey:pid]; //appName
        }
    } else {
        // count == 0
        return NO;
    }
    return YES;
}

// 创建和投递通知
- (void)createAndDeliverNotificationWithProcessItem:(Owl2LogProcessItem *)processItem {
    NSString *appName = processItem.convenient_name;
    NSString *thirdAppActionStr = @"";
    NSString *deviceName = processItem.deviceName;    // 中文名（p0）-> 进程英文（P1）->pid(p2) ->未知（p3）
    
    BOOL isUnknowAppName = NO;
    if (appName.length == 0 && processItem.pid) {
        appName = [NSString stringWithFormat:@"%@", processItem.pid];
    }
    if (appName.length == 0) {
        appName = NSLocalizedStringFromTableInBundle(@"未知应用", nil, [NSBundle bundleForClass:[self class]], nil);
        isUnknowAppName = YES;
    }
    
    if (processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStart) {
        switch (processItem.convenient_hardware) {
            case Owl2LogHardwareSystemAudio:
                thirdAppActionStr = LMLocalizedSelfBundleString(@"开始录制", nil);
                break;
            case Owl2LogHardwareScreen:
                if ([processItem.deviceExtra boolValue]) {
                    thirdAppActionStr = LMLocalizedSelfBundleString(@"已截取", nil);
                } else {
                    thirdAppActionStr = LMLocalizedSelfBundleString(@"开始录制", nil);
                }
                break;
            default:
                thirdAppActionStr = LMLocalizedSelfBundleString(@"开始使用", nil);
                break;
        }
    } else if (processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStop) {
        switch (processItem.convenient_hardware) {
            case Owl2LogHardwareSystemAudio: // 贯穿
            case Owl2LogHardwareScreen:
                thirdAppActionStr = LMLocalizedSelfBundleString(@"结束录制", nil);
                break;
            default:
                thirdAppActionStr = LMLocalizedSelfBundleString(@"结束使用", nil);
                break;
        }
    }
    
    if (processItem.convenient_hardware == Owl2LogHardwareVedio) {
        deviceName = deviceName ?: NSLocalizedStringFromTableInBundle(@"摄像头", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    if (processItem.convenient_hardware == Owl2LogHardwareAudio) {
        deviceName = deviceName ?: NSLocalizedStringFromTableInBundle(@"麦克风", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    if (processItem.convenient_hardware == Owl2LogHardwareSystemAudio) {
        deviceName = NSLocalizedStringFromTableInBundle(@"扬声器音频", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    if (processItem.convenient_hardware == Owl2LogHardwareScreen) {
        deviceName = LMLocalizedSelfBundleString(@"屏幕内容", nil);
    }
    
    if (deviceName.length > 25) {
        deviceName = [[deviceName substringToIndex:25] stringByAppendingString:@"..."];
    }
    
    NSString *informativeText = nil;
    if (isUnknowAppName) {
        informativeText = [NSString stringWithFormat:@"%@ %@%@\n%@", appName, thirdAppActionStr, deviceName, LMLocalizedSelfBundleString(@"若需阻止请手动检查并关闭", nil)];
    } else {
        informativeText = [NSString stringWithFormat:@"%@ %@%@", appName, thirdAppActionStr, deviceName];
    }
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedStringFromTableInBundle(@"隐私保护提示", nil, [NSBundle bundleForClass:[self class]], nil);
    notification.informativeText = informativeText;
    notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type:%d count:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], processItem.deviceType.intValue, self.notificationCount, [[NSDate date] description]];
    self.notificationCount++;
    
    // Note: (v4.8.9)由于无法直接kill掉Siri，弹窗显示不带阻止按钮！
    BOOL notActions = [processItem.name isEqualToString:@"Siri"];
    
    if (processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStart && !notActions && !isUnknowAppName) {
        if (@available(macOS 10.14, *)) {
            notification.hasActionButton = YES;
            notification.actionButtonTitle = LMLocalizedSelfBundleString(@"本次允许", nil);
            notification.otherButtonTitle = LMLocalizedSelfBundleString(@"永久允许", nil);
            if (processItem.convenient_hardware == Owl2LogHardwareScreen && [processItem.deviceExtra boolValue]) {

                // 截图
            } else {
                QMUserNotificationAction *preventAction = [QMUserNotificationAction new];
                preventAction.actionIdentifier = kUNNotificationActionPreventButtonDidBlock;
                preventAction.title = LMLocalizedSelfBundleString(@"阻止", nil);
                preventAction.options = UNNotificationActionOptionForeground;
                notification.qm_actions = @[preventAction];
            }
        } else {
            if (processItem.convenient_hardware == Owl2LogHardwareScreen && [processItem.deviceExtra boolValue]) {
                // 截图
            } else {
                notification.hasActionButton = YES;
                notification.actionButtonTitle = LMLocalizedSelfBundleString(@"阻止", nil);
            }
        }
    } else if (processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStop || notActions || isUnknowAppName) {
        notification.hasActionButton = YES;
        notification.actionButtonTitle = NSLocalizedStringFromTableInBundle(@"关闭", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    
    NSString *notificationKey = nil;
    if (processItem.convenient_hardware == Owl2LogHardwareVedio) {
        notificationKey = kOwl2VedioNotification;
    } else if (processItem.convenient_hardware == Owl2LogHardwareAudio) {
        notificationKey = kOwl2AudioNotification;
    } else if (processItem.convenient_hardware == Owl2LogHardwareSystemAudio) {
        notificationKey = kOwl2SystemAudioNotification;
    } else if (processItem.convenient_hardware == Owl2LogHardwareScreen) {
        notificationKey = kOwl2ScreenNotification;
    }

    if (!notificationKey) {
        return;
    }
    
    Owl2NotificationItem *notifItem = [[Owl2NotificationItem alloc] initWithLogProcessItem:processItem];
    notification.userInfo = notifItem.userInfo;
    
    NSLog(@"notification deliver userInfo=%@", notification.userInfo);
    
    [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification key:notificationKey];
    
    // 通知过期60s，此处是防止用户未开通知权限时累积过多，属于兜底
    // 因为需求是默认20s消失，因此可以60s过期，如果需要长期驻留在用户的通知中心，则不能移除
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //移除尚未送达给用户的通知
        [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithIdentifier:notification.identifier];
    });
}

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    // 通知被展示
    NSLog(@"notification show: %@", notification.userInfo);
    
    Owl2NotificationItem *notifItem = [[Owl2NotificationItem alloc] initWithDic:notification.userInfo];
    
    BOOL isOwl2VedioNotification = [notifItem.notificationKey isEqualToString:kOwl2VedioNotification];
    BOOL isOwl2AudioNotification = [notifItem.notificationKey isEqualToString:kOwl2AudioNotification];
    BOOL isOwl2SystemAudioNotification = [notifItem.notificationKey isEqualToString:kOwl2SystemAudioNotification];
    BOOL isOwl2ScreenNotification = [notifItem.notificationKey isEqualToString:kOwl2ScreenNotification];
    
    if (!(isOwl2VedioNotification || isOwl2AudioNotification || isOwl2SystemAudioNotification || isOwl2ScreenNotification)) {
        // 防止其它通知传过来
        return;
    }

    Owl2ManagerNotificationCustomObject *customObject = [Owl2ManagerNotificationCustomObject new];
    [self.notificationInsertLogList setObject:customObject forKey:notifItem.uuid];
    
    if (notifItem.processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStart) {
        @weakify(self);
        customObject.countdownCompleted = ^{
            @strongify(self);
            // 更新日志的操作记录
            [self updateLogItemWithUuid:notifItem.uuid
                                appName:notifItem.processItem.convenient_name
                                appPath:notifItem.processItem.convenient_appPath
                              appAction:notifItem.processItem.convenient_thirdAppActionForLog
                             userAction:Owl2LogUserActionDefaultAllow
                               hardware:notifItem.processItem.deviceType.intValue];
        };
        [self countdownDidDismissWithNotification:notification item:notifItem duration:20];
    }
    else if (notifItem.processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStop) {
        // 停止
        @weakify(self);
        customObject.countdownCompleted = ^{
            @strongify(self);
        };
        [self countdownDidDismissWithNotification:notification item:notifItem duration:5];
    }
    
    @try{
        [self addLogItemWithUuid:notifItem.uuid
                         appName:notifItem.processItem.convenient_name
                         appPath:notifItem.processItem.convenient_appPath
                       appAction:notifItem.processItem.convenient_thirdAppActionForLog
                      userAction:Owl2LogUserActionNone
                        hardware:notifItem.processItem.deviceType.intValue];
    }@catch (NSException *exception) {}
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    // 通知被操作
    NSLog(@"notification didActivate: %@", notification.userInfo);
    
    Owl2NotificationItem *notifItem = [[Owl2NotificationItem alloc] initWithDic:notification.userInfo];
    
    BOOL isOwl2VedioNotification = [notifItem.notificationKey isEqualToString:kOwl2VedioNotification];
    BOOL isOwl2AudioNotification = [notifItem.notificationKey isEqualToString:kOwl2AudioNotification];
    BOOL isOwl2SystemAudioNotification = [notifItem.notificationKey isEqualToString:kOwl2SystemAudioNotification];
    BOOL isOwl2ScreenNotification = [notifItem.notificationKey isEqualToString:kOwl2ScreenNotification];
    
    if (!(isOwl2VedioNotification || isOwl2AudioNotification || isOwl2SystemAudioNotification || isOwl2ScreenNotification)) {
        // 防止其它通知传过来
        return;
    }
    
    [notifItem parseUserActionWithNotification:notification];
    
    Owl2LogUserAction userAction = notifItem.userAction;
    
    // 开始时
    if (notifItem.processItem.convenient_thirdAppAction == Owl2LogThirdAppActionStart) {
        if (userAction == Owl2LogUserActionAlwaysAllowed) {
            [self addWhiteListWithProcessItem:notifItem.processItem];
        }
        else if (userAction == Owl2LogUserActionPrevent) {
            @weakify(self);
            [self killWithProcessItem:notifItem.processItem completionHandler:^(BOOL prevent) {
                @strongify(self);
                @try{
                    [self updateLogItemWithUuid:notifItem.uuid
                                        appName:notifItem.processItem.convenient_name
                                        appPath:notifItem.processItem.convenient_appPath
                                      appAction:notifItem.processItem.convenient_thirdAppActionForLog
                                     userAction:prevent?userAction:Owl2LogUserActionAllow
                                       hardware:notifItem.processItem.convenient_hardware];
                } @catch (NSException *exception) {}
                [self killAppWithDictItem:notifItem.processItem.originalDic];
            }];
        }
        
        switch (userAction) {
            case Owl2LogUserActionAllow:
            case Owl2LogUserActionClose:
            case Owl2LogUserActionDefaultAllow:
            case Owl2LogUserActionAlwaysAllowed:
            {
                @try{
                    [self updateLogItemWithUuid:notifItem.uuid
                                        appName:notifItem.processItem.convenient_name
                                        appPath:notifItem.processItem.convenient_appPath
                                      appAction:notifItem.processItem.convenient_thirdAppActionForLog
                                     userAction:userAction
                                       hardware:notifItem.processItem.convenient_hardware];
                }@catch (NSException *exception) {}
            }
                break;
            case Owl2LogUserActionContent: // 点击内容不处理
            {
                // 更新日志的操作记录
                [self updateLogItemWithUuid:notifItem.uuid
                                    appName:notifItem.processItem.convenient_name
                                    appPath:notifItem.processItem.convenient_appPath
                                  appAction:notifItem.processItem.convenient_thirdAppActionForLog
                                 userAction:Owl2LogUserActionDefaultAllow
                                   hardware:notifItem.processItem.convenient_hardware];
            }
                break;
            case Owl2LogUserActionPrevent: // 点击阻止特殊处理
            case Owl2LogUserActionNone:
            default:
                break;
        }
    }
    
    if (userAction != Owl2LogUserActionNone) {
        // 移除倒计时中的自定义通知对象
        [self.notificationInsertLogList removeObjectForKey:notifItem.uuid];
    }
    
    // 移除通知
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotificationWithIdentifier:notification.identifier];
}

- (void)countdownDidDismissWithNotification:(NSUserNotification *)notification item:(Owl2NotificationItem *)item duration:(NSTimeInterval)duration {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[QMUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotificationWithIdentifier:notification.identifier];
        
        Owl2ManagerNotificationCustomObject *customObject = [self.notificationInsertLogList objectForKey:item.uuid];
        if (customObject.countdownCompleted) customObject.countdownCompleted();
    });
}

// 添加白名单
- (void)addWhiteListWithProcessItem:(Owl2LogProcessItem *)processItem {
    [processItem.convenient_mainAppItem setWatchValue:YES forHardware:processItem.convenient_hardware];
    [self addWhiteWithAppItem:processItem.convenient_mainAppItem];
}

// kill app
- (void)killWithProcessItem:(Owl2LogProcessItem *)item completionHandler:(void(^)(BOOL prevent))handler {
    
    Owl2LogHardware hardware = item.convenient_hardware;
    
    // 每次均提示是否阻止
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    NSDictionary *copywriting = @{
        @(Owl2LogHardwareVedio): @"App会被强制退出，以防继续使用摄像头",
        @(Owl2LogHardwareAudio): @"App会被强制退出，以防继续使用麦克风",
        @(Owl2LogHardwareSystemAudio): @"App会被强制退出，以防继续使用扬声器",
        @(Owl2LogHardwareScreen): @"App会被强制退出，以防继续使用屏幕内容",
    };
    alert.messageText = QMRetStrIfEmpty(LMLocalizedSelfBundleString(copywriting[@(hardware)], nil));
    alert.informativeText = LMLocalizedSelfBundleString(@"确定要阻止吗？", nil);
    [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"确定", nil)];
    [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"取消", nil)];
    
    NSInteger responseTag = [alert runModal];
    if (responseTag == NSAlertFirstButtonReturn) {
        if (handler) handler(YES);
        kill(item.pid.intValue, SIGKILL);
    } else {
        if (handler) handler(NO);
    }
}

@end
