//
//  LMAppLaunchItem.h
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseLoginItem.h"

NS_ASSUME_NONNULL_BEGIN

//plist文件中的属性名称
#define LAUNCH_SERVICE_PROGRAM_ARGUMENTS @"ProgramArguments"
#define LAUNCH_SERVICE_LABEL @"Label"

typedef enum {
    LaunchServiceDomainTypeSystem = 1,
    LaunchServiceDomainTypeUser,
}LaunchServiceDomainType;

/*
 launch service item
 */
@interface QMAppLaunchItem : QMBaseLoginItem
/**
 plist文件地址
 */
@property NSString *filePath;

/**
plist文件名
*/
@property NSString *fileName;

/**
 plist文件中的lable属性
 */
@property NSString *label;

/**
 system or usr
 */
@property LaunchServiceDomainType domainType;

- (instancetype)initWithLaunchFilePath:(NSString *)path;

- (instancetype)initWithLaunchFilePath:(NSString *)path itemType:(LoginItemType)itemType;

@end

NS_ASSUME_NONNULL_END
