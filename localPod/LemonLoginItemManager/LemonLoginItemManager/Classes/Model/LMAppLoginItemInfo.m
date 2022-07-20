//
//  LMAppLoginItemInfo.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMAppLoginItemInfo.h"
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>

@interface LMAppLoginItemInfo ()

@property (nonatomic) NSMutableArray *loginItemData;
@property (nonatomic) NSMutableArray *launchItemData;
//保存App中启动项类型和对应的数量，如：应用启动项：5个，后台服务：3个
@property (nonatomic) NSMutableArray *loginItemTypeData;

@end

@implementation LMAppLoginItemInfo

- (instancetype)initWithAppName:(NSString *)appName;
{
    self = [super init];
    if (self) {
        self.appName = appName;
    }
    return self;
}

- (void)addAppLoginItem:(QMBaseLoginItem *)loginItem {
    if (!self.loginItemData) {
        self.loginItemData = [[NSMutableArray alloc] init];
    }
    [self.loginItemData addObject:loginItem];
}

- (void)addLaunchItem:(QMBaseLoginItem *)launchItem {
    if (!self.launchItemData) {
        self.launchItemData = [[NSMutableArray alloc] init];
    }
    [self.launchItemData addObject:launchItem];
}

//添加应用启动项类型信息
- (void)addAppLoginItemTypeInfoWithArray:(NSArray *)dataArray {
    if (!self.loginItemTypeData) {
        self.loginItemTypeData = [[NSMutableArray alloc] init];
    }
    LMAppLoginItemTypeInfo *typeInfo = [[LMAppLoginItemTypeInfo alloc] init];
    typeInfo.itemCount = dataArray.count;
    typeInfo.itemType = LoginItemTypeAppItem;
    typeInfo.loginItemData = dataArray;
    [self.loginItemTypeData addObject:typeInfo];
}

//添加launch Item类型信息
- (void)addLaunchItemTypeInfoWithArray:(NSArray *)dataArray {
    if (!self.loginItemTypeData) {
        self.loginItemTypeData = [[NSMutableArray alloc] init];
    }
    LMAppLoginItemTypeInfo *typeInfo = [[LMAppLoginItemTypeInfo alloc] init];
    typeInfo.itemCount = dataArray.count;
    typeInfo.itemType = LoginItemTypeService;
    typeInfo.loginItemData = dataArray;
    [self.loginItemTypeData addObject:typeInfo];
}


- (NSArray *)getLoginItemData {
    return self.loginItemData;
}

- (NSArray *)getLaunchItemData {
    return self.launchItemData;
}

- (NSArray *)getLoginItemTypeData {
    return self.loginItemTypeData;
}

- (void)updateEnableStatus {
    NSInteger enabledCount = 0;
    for (QMBaseLoginItem *loginItem in self.launchItemData) {
        if (loginItem.isEnable) {
            enabledCount++;
        }
    }
    for (QMBaseLoginItem *loginItem in self.loginItemData) {
        if (loginItem.isEnable) {
            enabledCount++;
        }
    }
    if (enabledCount == 0) {
        self.enableStatus = LMAppLoginItemEnableStatusAllDisabled;
        return;
    }
    if (enabledCount < self.totalItemCount) {
        self.enableStatus = LMAppLoginItemEnableStatusSomeEnabled;
        return;
    }
    if (enabledCount == self.totalItemCount) {
        self.enableStatus = LMAppLoginItemEnableStatusAllEnabled;
    }
}


@end

@implementation LMAppLoginItemTypeInfo


@end
