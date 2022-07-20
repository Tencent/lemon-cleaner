//
//  LGBaseLoginItem.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMBaseLoginItem.h"
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>

///base login item
@implementation QMBaseLoginItem

- (instancetype)initWithAppPath: (NSString *)appPath
{
    self = [super init];
    if (self) {
        self.appPath = appPath;
        self.appName = [appPath lastPathComponent];
    }
    return self;
}

- (instancetype)initWithAppPath: (NSString *)appPath loginItemType: (LoginItemType)type
{
    self = [super init];
    if (self) {
        self.appPath = appPath;
        self.appName = [appPath lastPathComponent];
        self.loginItemType = type;
    }
    return self;
}

- (void)disableLoginItem {
    switch (self.loginItemType) {
        case LoginItemTypeSystemItem:
            [[QMLoginItemManager shareInstance] removeSystemLoginItemWithAppPath:self.appPath];
            break;
        case LoginItemTypeAppItem:
            [[QMLoginItemManager shareInstance] disableAppLoginItemWithBundleId: ((QMAppLoginItem*)self).loginItemBundleId];
            break;
        case LoginItemTypeService:
            [[QMLoginItemManager shareInstance] disableLaunchItem:self];
            break;
        default:
            break;
    }
}

- (void)enableLoginItem {
    switch (self.loginItemType) {
        case LoginItemTypeSystemItem:
            [[QMLoginItemManager shareInstance] addSystemLoginItemWithAppPath:self.appPath];
            break;
        case LoginItemTypeAppItem:
            [[QMLoginItemManager shareInstance] enableAppLoginItemWithBundleId: ((QMAppLoginItem*)self).loginItemBundleId];
            break;
        case LoginItemTypeService:
            [[QMLoginItemManager shareInstance] enableLaunchItem:self];
            break;
        default:
            break;
    }
}

@end
