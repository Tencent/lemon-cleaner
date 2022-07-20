//
//  LoginItemManager.h
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMAppLaunchItem.h"
NS_ASSUME_NONNULL_BEGIN

///QMLoginItemManagerDelegate
@protocol QMLoginItemManagerDelegate <NSObject>

- (NSString *)exeCommonCmd:(NSString *)cmdString;

- (void)enabelSystemLaunchItemWithFilePath:(NSString *)path label:(NSString *)label;

- (void)disableSystemLaunchItemWithFilePath:(NSString *)path label:(NSString *)label;

- (BOOL)isEnableForLaunchServiceLabel:(NSString *)label;

@optional
//自定义需要过滤的plist文件，不需要过滤返回NO
- (BOOL)needFilterLaunchServiceFile:(NSString *)fileName;

//自定义需要过滤的login item，不需要过滤返回NO, bundleId: main App的bundleId
- (BOOL)needFilterLoginItemBundleId:(NSString *)bundleId;

@end

/*
 Login item manager
 */
@interface QMLoginItemManager : NSObject

///delegate
@property id<QMLoginItemManagerDelegate> delegate;

+ (instancetype)shareInstance;

-(NSMutableArray *)getLaunchServiceItems;

-(NSMutableArray *)getAppLoginItems;

-(NSMutableArray *)getSystemLoginItems;

-(void)disableLaunchItem:(QMBaseLoginItem *)item;

-(void)enableLaunchItem:(QMBaseLoginItem *)item;

-(void)removeSystemLoginItemWithAppPath: (NSString *)appPath;

-(void)addSystemLoginItemWithAppPath: (NSString *)appPath;

-(void)enableAppLoginItemWithBundleId: (NSString *)itemPath;

-(void)disableAppLoginItemWithBundleId: (NSString *)itemPath;

@end

NS_ASSUME_NONNULL_END
