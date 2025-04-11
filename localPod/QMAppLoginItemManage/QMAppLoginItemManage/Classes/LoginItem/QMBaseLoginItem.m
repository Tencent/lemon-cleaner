//
//  LGBaseLoginItem.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMBaseLoginItem.h"
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>
#import "QMLoginItemCacheHelper.h"

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


#pragma mark -

- (NSString *)uid {
    if (!_uid) {
        if ([self.appPath isKindOfClass:NSString.class] && self.appPath.length > 0) {
            _uid = self.appPath;
        }
    }
    return _uid;
}

- (BOOL)isDisabledByUser {
    if (!self.uid) return NO;
    return [self.cacheDict[self.uid] boolValue];
}

- (void)setIsDisabledByUser:(BOOL)isDisabledByUser {
    if (!self.uid) return;
    
    BOOL lastValue = [self.cacheDict[self.uid] boolValue];
    
    if (isDisabledByUser) {
        self.cacheDict[self.uid] = @(YES);
    } else {
        [self.cacheDict removeObjectForKey:self.uid];
    }
    
    if (lastValue != isDisabledByUser) {
        [[QMLoginItemCacheHelper sharedInstance] updateUserDefaultsWithCacheKey:self.cacheKey];
    }
}

- (NSString *)cacheKey {
    return @"QMBaseLoginItemCacheKey";
}

- (NSMutableDictionary *)cacheDict {
    QMLoginItemCacheHelper *helper = [QMLoginItemCacheHelper sharedInstance];
    return [helper dictForCacheKey:self.cacheKey];
}

@end
