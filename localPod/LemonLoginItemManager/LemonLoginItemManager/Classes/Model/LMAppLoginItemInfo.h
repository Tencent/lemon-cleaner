//
//  LMAppLoginItemInfo.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMAppLoginItemManage/QMBaseLoginItem.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum LMAppLoginItemEnableStatus {
    LMAppLoginItemEnableStatusAllEnabled = 1,
    LMAppLoginItemEnableStatusSomeEnabled,
    LMAppLoginItemEnableStatusAllDisabled
}LMAppLoginItemEnableStatus;

//启动项类型
@interface LMAppLoginItemTypeInfo : NSObject

@property (nonatomic) LoginItemType itemType;
@property (nonatomic) NSInteger itemCount;
@property (nonatomic) NSArray *loginItemData;
@end

@interface LMAppLoginItemInfo : NSObject

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appPath;
@property (nonatomic) LMAppLoginItemEnableStatus enableStatus;
@property (nonatomic) NSInteger totalItemCount;
@property (nonatomic) NSInteger selectedCount;

- (instancetype)initWithAppName:(NSString *)appName;

- (void)addLaunchItem:(QMBaseLoginItem *)launchItem;

- (void)addAppLoginItem:(QMBaseLoginItem *)loginItem;

- (NSArray *)getLoginItemData;

- (NSArray *)getLaunchItemData;

- (NSArray *)getLoginItemTypeData;

- (void)addAppLoginItemTypeInfoWithArray:(NSArray *)dataArray;

- (void)addLaunchItemTypeInfoWithArray:(NSArray *)dataArray;

- (void)updateEnableStatus;

@end



NS_ASSUME_NONNULL_END
