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

NSNotificationName const Owl2WhiteListChangeNotication = @"OwlWhiteListChangeNotication";
NSNotificationName const Owl2LogChangeNotication = @"OwlLogChangeNotication";
NSNotificationName const Owl2ShowWindowNotication = @"OwlShowWindowNotication";

NSNotificationName const Owl2WatchVedioStateChange = @"OwlWatchVedioStateChange";
NSNotificationName const Owl2WatchAudioStateChange = @"OwlWatchAudioStateChange";

NSNotificationName const kOwl2VedioNotification = @"kOwlVedioNotification";
NSNotificationName const kOwl2AudioNotification = @"kOwlAudioNotification";
NSNotificationName const kOwl2VedioAndAudioNotification = @"kOwlVedioAndAudioNotification";
NSNotificationName const kOwl2SystemAudioNotification = @"kOwl2SystemAudioNotification";


static NSString * const kUNNotificationActionPreventButtonDidBlock = @"kUNNotificationActionPreventButtonDidBlock";

static NSString * const kSuffixApp = @".app/";
static NSString * const kSuffixAppex = @".appex/";

@interface Owl2ManagerNotificationCustomObject : NSObject
@property (nonatomic, copy) dispatch_block_t insertLog;
@property (nonatomic, copy) dispatch_block_t updateLog;
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
}

- (void)analyseDeviceInfoForNotificationWithArray:(NSArray<NSDictionary *>*)itemArray;
{
    NSLog(@"analyseDeviceInfoForNotificationWithArray:, %@", itemArray);
    
    if (!self.isWatchVideo && !self.isWatchAudio) {
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
    for (NSDictionary *originDic in filterArray) {
        NSDictionary *dic = originDic;
        //OWL_PROC_ID/OWL_PROC_NAME/OWL_PROC_PATH/OWL_PROC_DELTA/OWL_DEVICE_TYPE
        int deviceType = [dic[OWL_DEVICE_TYPE] intValue];
        int count = [[dic objectForKey:OWL_PROC_DELTA] intValue];
        NSString *appName = dic[OWL_PROC_NAME];
        NSString *appPath = dic[OWL_PROC_PATH];
        if (!appName ||
            [appName isEqualToString:@""] ||
            [appName isEqualToString:@"corespeechd"] ||
            [appName isEqualToString:@"replayd"] ||
            [dic[OWL_PROC_ID] intValue] < 0) {
            NSLog(@"%s appName is %@, pid: %d", __FUNCTION__, appName, [dic[OWL_PROC_ID] intValue]);
            continue;
        }
        
        BOOL isWhite = NO;
        
        // 找到主app, mainAppInfo 可能为nil
        // 主app可能为应用本身
        NSDictionary *mainAppInfo = [self mainAppInfoWithPath:appPath];
        NSString *mainAppIdentifier = mainAppInfo[OwlIdentifier];
        if (mainAppIdentifier) {
            for (NSDictionary *item in self.wlArray) {
                if ([[item objectForKey:OwlIdentifier] isEqualToString:mainAppIdentifier]) {
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
                    } else if (deviceType == OwlProtectSystemAudio) {
                        if ([[item objectForKey:OwlWatchSpeaker] boolValue]) {
                            isWhite = YES;
                            break;
                        }
                    }
                    break;
                }
            }
            
            // 将主app的信息添加到原始数据中
            NSMutableDictionary *targetDict = mainAppInfo.mutableCopy;
            [targetDict addEntriesFromDictionary:dic];
            dic = targetDict.copy;
            // 统一替换为主app的
            appName = [mainAppInfo objectForKey:OwlAppName];
        }
        
        if (isWhite) {
            continue;
        }
        
        if (appName == nil) { // 进程名
            // 中文名（p0）-> 进程英文（P1）->pid(p2) ->未知（p3）
            appName = [NSString stringWithFormat:@"%@", dic[OWL_PROC_ID]];
        }
        if (appName == nil) { // 未知
            // 中文名（p0）-> 进程英文（P1）->pid(p2) ->未知（p3）
            appName = NSLocalizedStringFromTableInBundle(@"未知应用", nil, [NSBundle bundleForClass:[self class]], nil);
        }
        NSString *stringTitle = @"";
        
        NSNumber *appIdentifier = dic[OWL_PROC_ID]; // appName maybe repeat!
        //according to the agreement,
        //when count > 0, the corresponding process is start using camera
        //when count < 0, the corresponding process is stop using camera
        //when count = 0, nonthing
        if (deviceType == OwlProtectVedio) {
            if (!self.isWatchVideo) {
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
        if (deviceType == OwlProtectSystemAudio) {
            if (!self.isWatchAudio) {
                continue;
            }
            NSDictionary *startDic = [self.owlSystemAudioItemDic objectForKey:appIdentifier]; //appName
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
                    [self.owlSystemAudioItemDic removeObjectForKey:appIdentifier]; //appName
                }
            }
        }
        if ((deviceType != OwlProtectVedio) && (deviceType != OwlProtectAudio) && deviceType != OwlProtectSystemAudio) {
            continue;
        }
        NSString *strLanguageKey = @"";
        NSString *deviceName = dic[OWL_DEVICE_NAME];
        if (count > 0) {
            if (deviceType == OwlProtectSystemAudio) {
                strLanguageKey = @"开始录制";
            } else {
                strLanguageKey = @"开始使用";
            }
        } else if (count < 0) {
            if (deviceType == OwlProtectSystemAudio) {
                strLanguageKey = @"结束录制";
            } else {
                strLanguageKey = @"结束使用";
            }
        } else {
            continue;
        }
        if (deviceType == OwlProtectVedio) {
            deviceName = deviceName?:@"摄像头";
        } else if (deviceType == OwlProtectAudio) {
            deviceName = deviceName?:@"麦克风";
        } else if (deviceType == OwlProtectSystemAudio) {
            deviceName = NSLocalizedStringFromTableInBundle(@"扬声器音频", nil, [NSBundle bundleForClass:[self class]], @"");
        }
        if (deviceName.length > 25) {
            deviceName = [[deviceName substringToIndex:25] stringByAppendingString:@"..."];
        }
        
        BOOL unkonwApp = [appName isEqualToString:NSLocalizedStringFromTableInBundle(@"未知应用", nil, [NSBundle bundleForClass:[self class]], nil)];
        if (unkonwApp) {
            stringTitle = [NSString stringWithFormat:@"%@ %@ %@\n%@", appName, NSLocalizedStringFromTableInBundle(strLanguageKey, nil, [NSBundle bundleForClass:[self class]], @""), deviceName, NSLocalizedStringFromTableInBundle(@"若需阻止请手动检查并关闭", nil, [NSBundle bundleForClass:[self class]], nil)];
        } else {
            stringTitle = [NSString stringWithFormat:@"%@ %@ %@", appName, NSLocalizedStringFromTableInBundle(strLanguageKey, nil, [NSBundle bundleForClass:[self class]], @""), deviceName];
        }
        // 允许弹出未知应用 - 产品需求 Lemon 5.1.14
//        if ([dic[OWL_PROC_NAME] length] == 0) {
//            continue;
//        }
        
        if (count != 0) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = NSLocalizedStringFromTableInBundle(@"隐私保护提示", nil, [NSBundle bundleForClass:[self class]], nil);
            //[notification setValue:[NSImage imageNamed:NSImageNameApplicationIcon] forKey:@"_identityImage"];
            //notification.contentImage = [NSImage imageNamed:NSImageNameApplicationIcon];
            notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type:%d count:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], deviceType, self.notificationCount, [[NSDate date] description]];
            self.notificationCount++;
            notification.informativeText = stringTitle;
            
            // Note: (v4.8.9)由于无法直接kill掉Siri，弹窗显示不带阻止按钮！
            BOOL notActions = [dic[OWL_PROC_NAME] isEqualToString:@"Siri"];
            
            Owl2LogAppAction appAction = Owl2LogAppActionNone;
            NSString *uuid = [[NSUUID UUID] UUIDString];
            // Note: 未知应用不提供kill能力
            if (count > 0 && !notActions && !unkonwApp) {
                appAction = Owl2LogAppActionStart;
                if (@available(macOS 10.14, *)) {
                    notification.hasActionButton = YES;
                    notification.actionButtonTitle = NSLocalizedStringFromTableInBundle(@"本次允许", nil, [NSBundle bundleForClass:[self class]], nil);
                    notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"永久允许", nil, [NSBundle bundleForClass:[self class]], nil);
                    QMUserNotificationAction *preventAction = [QMUserNotificationAction new];
                    preventAction.actionIdentifier = kUNNotificationActionPreventButtonDidBlock;
                    preventAction.title = NSLocalizedStringFromTableInBundle(@"阻止", nil, [NSBundle bundleForClass:[self class]], nil);
                    preventAction.options = UNNotificationActionOptionForeground;
                    notification.qm_actions = @[preventAction];
                } else {
                    notification.hasActionButton = YES;
                    notification.actionButtonTitle = NSLocalizedStringFromTableInBundle(@"阻止", nil, [NSBundle bundleForClass:[self class]], nil);
                }
                
                NSMutableDictionary *userInfo = dic.mutableCopy;
                [userInfo setObject:@(appAction) forKey:OwlAppAction];
                [userInfo setObject:@(deviceType) forKey:OwlHardware];
                [userInfo setObject:uuid forKey:OwlUUID];
                notification.userInfo = userInfo;
                
            } else if (count < 0 || notActions || unkonwApp) {
                appAction = Owl2LogAppActionStop;
                notification.hasActionButton = YES;
                notification.actionButtonTitle = NSLocalizedStringFromTableInBundle(@"关闭", nil, [NSBundle bundleForClass:[self class]], @"");
                
                NSMutableDictionary *userInfo = dic.mutableCopy;
                [userInfo setObject:@(appAction) forKey:OwlAppAction];
                [userInfo setObject:@(deviceType) forKey:OwlHardware];
                [userInfo setObject:uuid forKey:OwlUUID];
                notification.userInfo = userInfo;
                
            } else {
            }
            
            NSLog(@"notification deliver deviceType=%@, userInfo=%@", @(deviceType), notification.userInfo);
            if (deviceType == OwlProtectVedio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification key:kOwl2VedioNotification];
            } else if (deviceType == OwlProtectAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification key:kOwl2AudioNotification];
            } else if (deviceType == OwlProtectSystemAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification key:kOwl2SystemAudioNotification];
            }
                        
            // 通知过期60s，此处是防止用户未开通知权限时累积过多，属于兜底
            // 因为需求是默认20s消失，因此可以60s过期，如果需要长期驻留在用户的通知中心，则不能移除
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //移除尚未送达给用户的通知
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithIdentifier:notification.identifier];
            });
        }
    }
}

#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    // 通知被展示
    NSLog(@"notification show: %@", notification.userInfo);
    
    NSDictionary *userInfo = notification.userInfo;
    Owl2LogAppAction appAction = [[userInfo objectForKey:OwlAppAction] integerValue];
    Owl2LogHardware hardware = [[userInfo objectForKey:OwlHardware] integerValue];
    Owl2LogUserAction userAction = Owl2LogUserActionNone;
    NSString *appName = [userInfo objectForKey:OwlAppName];
    if (!appName) appName = [userInfo objectForKey:OWL_PROC_NAME];
    NSString *appPath = [userInfo objectForKey:OwlBubblePath];
    NSString *processPath = [userInfo objectForKey:OWL_PROC_PATH];
    if (appPath.length == 0) appPath = processPath;
    NSString *uuid = [userInfo objectForKey:OwlUUID];
    NSString *identifier = [userInfo objectForKey:OwlIdentifier];
    
    if (appAction == Owl2LogAppActionStart) {
        
        // 放在前面是防止block引用了Owl2ManagerNotificationCustomObject对象
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"notification 20s atuo diss: %@", notification.userInfo);
            // 20s移除通知
            [[QMUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotificationWithIdentifier:notification.identifier];
            
            NSString *uuid = [userInfo objectForKey:OwlUUID];
            Owl2ManagerNotificationCustomObject *customObject = [self.notificationInsertLogList objectForKey:uuid];
            // 更新为默认允许
            if (customObject.updateLog) customObject.updateLog();
        });
        
        @weakify(self);
        Owl2ManagerNotificationCustomObject *customObject = [Owl2ManagerNotificationCustomObject new];
        customObject.updateLog = ^{
            @strongify(self);
            // 更新日志的操作记录
            [self updateLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:Owl2LogUserActionDefaultAllow hardware:hardware];
        };
        [self.notificationInsertLogList setObject:customObject forKey:uuid];
        
        // 开始
        @try{
            [self addLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:userAction hardware:hardware];
        }@catch (NSException *exception) {}
    }
    
    if (appAction == Owl2LogAppActionStop) {
        // 停止
        
        // 5s 后通知消失
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"notification 5s atuo diss: %@", notification.userInfo);
            [[QMUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotificationWithIdentifier:notification.identifier];
        });
        
        @try{
            [self addLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:userAction hardware:hardware];
        }@catch (NSException *exception) {}
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    // 通知被操作
    NSLog(@"notification didActivate: %@", notification.userInfo);
    
    NSDictionary *userInfo = notification.userInfo;
    Owl2LogAppAction appAction = [[userInfo objectForKey:OwlAppAction] integerValue];
    Owl2LogHardware hardware = [[userInfo objectForKey:OwlHardware] integerValue];
    Owl2LogUserAction userAction = Owl2LogUserActionNone;
    NSString *appName = [userInfo objectForKey:OwlAppName];
    if (!appName) appName = [userInfo objectForKey:OWL_PROC_NAME];
    NSString *appPath = [userInfo objectForKey:OwlBubblePath];
    NSString *processPath = [userInfo objectForKey:OWL_PROC_PATH];
    if (appPath.length == 0) appPath = processPath;
    NSString *uuid = [userInfo objectForKey:OwlUUID];
    NSString *identifier = [userInfo objectForKey:OwlIdentifier];
    int count = [[userInfo objectForKey:OWL_PROC_DELTA] intValue];
    // 开始时
    if (appAction == Owl2LogAppActionStart) {
        
        if (@available(macOS 10.14, *)) {
            NSString *actionId = [notification.userInfo objectForKey:@"ACTION_ID"];
            if ([actionId isEqualToString:UNNotificationDismissActionIdentifier]) {
                // 点击了左上角的x
                userAction = Owl2LogUserActionClose;
            }
            
            if ([actionId isEqualToString:UNNotificationDefaultActionIdentifier]) {
                //点击了内容
                // do nothing
                userAction = Owl2LogUserActionContent;
            }
            
            if ([actionId isEqualToString:UNNotificationActionButtonDidBlock]) {
                //本次允许
                userAction = Owl2LogUserActionAllow;
            }
            
            if ([actionId isEqualToString:UNNotificationActionOtherButtonDidBlock]) {
                // 点击了永久允许,添加到白名单中
                userAction = Owl2LogUserActionAlwaysAllowed;
                [self addWhiteListWith:userInfo hardware:hardware];
            }
            
            if ([actionId isEqualToString:kUNNotificationActionPreventButtonDidBlock]) {
                // 点击了阻止
                userAction = Owl2LogUserActionPrevent;
                
                NSString *uuid = [userInfo objectForKey:OwlUUID];
                @weakify(self);
                [self killWithUserInfo:userInfo completionHandler:^(BOOL prevent) {
                    @strongify(self);
                    @try{
                        [self updateLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:prevent?userAction:Owl2LogUserActionAllow hardware:hardware];
                    } @catch (NSException *exception) {}
                }];
            }
            
        } else {
            // 无法监听或者没有X关闭
            
            if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
                // 点击了内容
                userAction = Owl2LogUserActionContent;
            }
            
            if (notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
                // 点击了阻止 （也只有阻止）
                userAction = Owl2LogUserActionPrevent;
                
                NSString *uuid = [userInfo objectForKey:OwlUUID];
                @weakify(self);
                [self killWithUserInfo:userInfo completionHandler:^(BOOL prevent) {
                    @strongify(self);
                    if (prevent) {
                        @try{
                            [self updateLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:userAction hardware:hardware];
                        }@catch (NSException *exception) {}
                    }
                }];
            }
        }
        
        // 点击内容不处理
        // 点击阻止特殊处理
        switch (userAction) {
            case Owl2LogUserActionAllow:
            case Owl2LogUserActionClose:
            case Owl2LogUserActionDefaultAllow:
            case Owl2LogUserActionAlwaysAllowed:
            {
                @try{
                    [self updateLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:userAction hardware:hardware];
                }@catch (NSException *exception) {}
            }
                break;
            case Owl2LogUserActionContent:
            {
                // 更新日志的操作记录
                [self updateLogItemWithUuid:uuid appName:appName appPath:appPath appAction:appAction userAction:Owl2LogUserActionDefaultAllow hardware:hardware];
            }
                break;
            case Owl2LogUserActionPrevent:
            case Owl2LogUserActionNone:
            default:
                break;
        }
        
        if (userAction != Owl2LogUserActionNone) {
            // 取消20s延时的默认允许上报
            [self.notificationInsertLogList removeObjectForKey:uuid];
        }
    }
    
    
    if (appAction == Owl2LogAppActionStop) {
        // 停止时操作
        // 不做任何记录
    }
    
    // 移除通知
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotificationWithIdentifier:notification.identifier];
}

// 将内嵌app转换为非内嵌主app，如果不是内嵌app，则返回app本身的信息
- (NSDictionary *)mainAppInfoWithPath:(NSString *)appPath {
    if (![appPath isKindOfClass:NSString.class]) {
        return nil;
    }
    // 从左往右找到父app
    NSString *parentAppPath = [self appPathFromExecutablePath:appPath fileExtension:kSuffixApp options:0];
    if (!parentAppPath) {
        parentAppPath = [self appPathFromExecutablePath:appPath fileExtension:kSuffixAppex options:0];
    }
    
    if (parentAppPath) {
        return [self getAppInfoWithPath:parentAppPath appName:@""];
    }
    return [self getAppInfoWithPath:appPath appName:@""];
}

// 添加白名单
- (void)addWhiteListWith:(NSDictionary *)dict hardware:(Owl2LogHardware)hardware {
    NSMutableDictionary *muDict = dict.mutableCopy;
    switch (hardware) {
        case Owl2LogHardwareAudio:
            [muDict setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
            break;
        case Owl2LogHardwareVedio:
            [muDict setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
            break;
        case Owl2LogHardwareSystemAudio:
            [muDict setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchSpeaker];
            break;
        default:
            break;
    }
    
    [self addAppWhiteItem:muDict.copy];
}

// kill app
- (void)killWithUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(BOOL prevent))handler {
    
    Owl2LogHardware hardware = [[userInfo objectForKey:OwlHardware] integerValue];
    
    // 每次均提示是否阻止
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    if (hardware == Owl2LogHardwareVedio) {
        alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else if (hardware == Owl2LogHardwareAudio) {
        alert.messageText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_2", nil, [NSBundle bundleForClass:[self class]], @"");
    } else if (hardware == Owl2LogHardwareSystemAudio) {
        NSLocalizedStringFromTableInBundle(@"App会被强制退出，以防继续使用扬声器", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    alert.informativeText = NSLocalizedStringFromTableInBundle(@"OwlManager_userNotificationCenter_alert_4", nil, [NSBundle bundleForClass:[self class]], @"");
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_ok_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_cancel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    NSInteger responseTag = [alert runModal];
    if (responseTag == NSAlertFirstButtonReturn) {
        if (handler) handler(YES);
        kill([[userInfo objectForKey:OWL_PROC_ID] intValue], SIGKILL);
    } else {
        if (handler) handler(NO);
    }
}

- (NSString *)appPathFromExecutablePath:(NSString *)executablePath fileExtension:(NSString *)fileExtension options:(NSStringCompareOptions)mask {
    NSRange range = [executablePath rangeOfString:fileExtension options:mask];
    if (range.location != NSNotFound) {
        return [executablePath substringToIndex:range.location + range.length];
    }
    return nil;
}

@end
