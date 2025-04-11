//
//  Owl2Manager+Notification.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Notification.h"
#import "OwlConstant.h"
#import "LemonDaemonConst.h"
#import "Owl2Manager+Database.h"

NSNotificationName const Owl2WhiteListChangeNotication = @"OwlWhiteListChangeNotication";
NSNotificationName const Owl2LogChangeNotication = @"OwlLogChangeNotication";
NSNotificationName const Owl2ShowWindowNotication = @"OwlShowWindowNotication";

NSNotificationName const Owl2WatchVedioStateChange = @"OwlWatchVedioStateChange";
NSNotificationName const Owl2WatchAudioStateChange = @"OwlWatchAudioStateChange";

NSNotificationName const kOwl2VedioNotification = @"kOwlVedioNotification";
NSNotificationName const kOwl2AudioNotification = @"kOwlAudioNotification";
NSNotificationName const kOwl2VedioAndAudioNotification = @"kOwlVedioAndAudioNotification";

@implementation Owl2Manager (Notification)

- (void)registeNotificationDelegate
{
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2VedioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2AudioNotification];
    [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                   forKey:kOwl2VedioAndAudioNotification];
}

- (void)analyseDeviceInfoForNotificationWithArray:(NSArray<NSDictionary *>*)itemArray;
{
    //NSLog(@"analyseDeviceInfoForNotificationWithArray:, %@", itemArray);
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
                                                                                           key:kOwl2VedioNotification];
            } else if (deviceType == OwlProtectAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                           key:kOwl2AudioNotification];
            } else if (deviceType == OwlProtectVedioAndAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                           key:kOwl2VedioAndAudioNotification];
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
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwl2VedioNotification flagsBlock:nil];
            } else if (deviceType == OwlProtectAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwl2AudioNotification flagsBlock:nil];
            } else if (deviceType == OwlProtectVedioAndAudio) {
                [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kOwl2VedioAndAudioNotification flagsBlock:nil];
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
                    kill([[notification.userInfo objectForKey:OWL_PROC_ID] intValue], SIGKILL);
//                    [[McCoreFunction shareCoreFuction] killProcessByID:[[notification.userInfo objectForKey:OWL_PROC_ID] intValue]];
                }
                
                [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES  (?);", OwlProBlockTable, OwlExecutableName], executableName];
            } else {
                kill([[notification.userInfo objectForKey:OWL_PROC_ID] intValue], SIGKILL);
//                [[McCoreFunction shareCoreFuction] killProcessByID:[[notification.userInfo objectForKey:OWL_PROC_ID] intValue]];
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
