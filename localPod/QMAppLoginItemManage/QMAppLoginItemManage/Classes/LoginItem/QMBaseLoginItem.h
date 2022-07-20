//
//  LGBaseLoginItem.h
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum{
    LoginItemTypeSystemItem = 0,
    LoginItemTypeAppItem,
    LoginItemTypeService,
}LoginItemType;

/*
 base login item
 */
@interface QMBaseLoginItem : NSObject

///app path
@property NSString *appPath;

///app name
@property NSString *appName;

///login item type
@property LoginItemType loginItemType;

///login item is enabled
@property BOOL isEnable;

- (instancetype)initWithAppPath: (NSString *)appPath;

- (instancetype)initWithAppPath: (NSString *)appPath loginItemType: (LoginItemType)type;

- (void)disableLoginItem;

- (void)enableLoginItem;

@end

NS_ASSUME_NONNULL_END
