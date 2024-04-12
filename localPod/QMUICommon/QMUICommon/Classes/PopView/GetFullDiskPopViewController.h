//
//  GetFullDiskPopViewController.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMBaseViewController.h"

typedef NS_ENUM(NSUInteger, GetFullDiskPopVCStyle) {
    GetFullDiskPopVCStyleDefault = 0, // 默认。 扫描结束详情页，下载、邮箱无权限时的弹窗
    GetFullDiskPopVCStylePreScan, // macOS 14.0 及以上，扫描前提示用户开启【完全磁盘访问权限】。访问其它App的弹窗。
    GetFullDiskPopVCStyleMonitor, // LemonMonitor
};

typedef void(^CLoseBLock)(void);

@interface GetFullDiskPopViewController : QMBaseViewController

@property (nonatomic, assign) GetFullDiskPopVCStyle style;

-(id)initWithCLoseSetting:(CLoseBLock) closeBlock;

@end
