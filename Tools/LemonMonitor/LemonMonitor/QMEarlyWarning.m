//
//  QMEarlyWarning.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMEarlyWarning.h"
#import "LemonDaemonConst.h"
#import "QMDataConst.h"
#import "QMDataCenter.h"
#import <PrivacyProtect/QMUserNotificationCenter.h>

#define EARLY_NODE @"earlywarning"
#define EARLY_VERSION @"version"
#define EARLY_DATE @"date"
#define EARLY_DURATION @"duration"
#define EARLY_TITLE @"title"
#define EARLY_SUBTITLE @"subtitle"
#define EARLY_INFORMATIVE @"informativeText"
#define EARLY_ACTION_TYPE @"actionType"
#define EARLY_ACTION_VALUE @"actionValue"

#define EARLY_OPEN_MGR 1
#define EARLY_OPEN_URL 2

#define kEarlyNotificationKey    @"earlywarn"

@interface QMEarlyWarning ()<NSUserNotificationCenterDelegate>
@end

@implementation QMEarlyWarning

+ (id)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        //数据文件更新的通知
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(networkFileDidChanged:)
//                                                     name:kQMNetworkFileChangedNotificaton
//                                                   object:nil];
//
//        [[QMNetworkDataQuery sharedInstance] queryFileWithKey:kQMNetworkFileWelcomID];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:kEarlyNotificationKey];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- (void)networkFileDidChanged:(NSNotification *)notify
//{
//    NSString *fileKey = [notify.userInfo objectForKey:kQMNetworkFileKeyID];
//    if (![fileKey isEqualToString:kQMNetworkFileWelcomID])
//        return;
//
//    NSData *fileData = [[QMNetworkDataQuery sharedInstance] contentWithKey:kQMNetworkFileWelcomID];
//    if (!fileData)
//        return;
//
//    NSXMLDocument *fileDoc = [[NSXMLDocument alloc] initWithData:fileData options:0 error:NULL];
//    if (!fileDoc)
//        return;
//
//    NSXMLElement *rootElement = [fileDoc rootElement];
//    NSXMLElement *baseElement = [[rootElement elementsForName:EARLY_NODE] lastObject];
//    if (!baseElement)
//        return;
//
//    //查询版本号,并与已经预警过的版本号比对
//    NSXMLElement *versionElement = [[baseElement elementsForName:EARLY_VERSION] lastObject];
//    NSString *versionString = [versionElement stringValue];
//    if (!versionString)
//        return;
//    NSString *currentVersion = [[QMDataCenter defaultCenter] stringForKey:kQMMonitorEarlyWarning];
//    if (currentVersion && [versionString isEqualToString:currentVersion])
//        return;
//    [[QMDataCenter defaultCenter] setString:versionString forKey:kQMMonitorEarlyWarning];
//
//    //判定预警的时间是否已经过期
//    NSXMLElement *dateElement = [[baseElement elementsForName:EARLY_DATE] lastObject];
//    double warningDate = [[dateElement stringValue] doubleValue];
//
//    NSXMLElement *durationElement = [[baseElement elementsForName:EARLY_DURATION] lastObject];
//    double warningDuration = [[durationElement stringValue] doubleValue];
//
//    CFTimeInterval currentDate = CFAbsoluteTimeGetCurrent();
//    if (currentDate < warningDate || currentDate > warningDate+warningDuration)
//        return;
//
//    //标题
//    NSXMLElement *titleElement = [[baseElement elementsForName:EARLY_TITLE] lastObject];
//    NSString *titleString = [titleElement stringValue];
//    if (titleString.length == 0)
//        return;
//
//    //副标题
//    NSXMLElement *subTitleElement = [[baseElement elementsForName:EARLY_SUBTITLE] lastObject];
//    NSString *subTitleString = [subTitleElement stringValue];
//
//    //详细描述
//    NSXMLElement *infomativeElement = [[baseElement elementsForName:EARLY_INFORMATIVE] lastObject];
//    NSString *infomativeString = [infomativeElement stringValue];
//
//    //行为类型
//    NSXMLElement *actionTypeElement = [[baseElement elementsForName:EARLY_ACTION_TYPE] lastObject];
//    int actionType = [[actionTypeElement stringValue] intValue];
//
//    //行为数据
//    NSXMLElement *actionValueElement = [[baseElement elementsForName:EARLY_ACTION_VALUE] lastObject];
//    NSString *actionValue = [actionValueElement stringValue];
//
//    //创建通知
//    NSUserNotification *notification = [[NSUserNotification alloc] init];
//    notification.title = titleString;
//    if (subTitleString.length > 0) notification.subtitle = subTitleString;
//    if (infomativeString.length > 0) notification.informativeText = infomativeString;
//
//    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
//    [userInfo setObject:@(actionType) forKey:EARLY_ACTION_TYPE];
//    if (actionValue.length > 0)
//        [userInfo setObject:actionValue forKey:EARLY_ACTION_VALUE];
//    notification.userInfo = userInfo;
//
//    //递交通知
//    [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
//                                                                               key:kEarlyNotificationKey];
//}

#pragma mark -
#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    //通知已经递交！
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //用户点击了通知！
    NSDictionary *userInfo = [notification userInfo];
    int earlyType = [userInfo[EARLY_ACTION_TYPE] intValue];
    
    if (earlyType == EARLY_OPEN_MGR)
    {
        [[NSWorkspace sharedWorkspace] launchApplication:DEFAULT_APP_PATH];
    }
    else if (earlyType == EARLY_OPEN_URL)
    {
        NSString *link = userInfo[EARLY_ACTION_VALUE];
        NSURL *url = [NSURL URLWithString:link];
        if (url)
        {
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
    }
    
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:kEarlyNotificationKey
                                                                                      flagsBlock:nil
     ];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
