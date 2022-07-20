//
//  LMUninstallItem.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMUninstallItem : NSObject

@property NSString *bundleId;
@property NSString *applicationSupportName;
@property NSString *containerName;  //沙盒目录下的文件名称
@property NSString *cacheName;
@property NSString *preferenceName;
@property NSString *logName;
@property NSString *daemonName;
@property NSString *otherName;
@property NSString *crashReporterName;
@property NSString *launchServiceName;


@end

NS_ASSUME_NONNULL_END
