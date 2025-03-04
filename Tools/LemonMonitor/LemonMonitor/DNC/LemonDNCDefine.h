//
//  LemonDNCDefine.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#ifndef LemonDNCDefine_h
#define LemonDNCDefine_h

#define LemonDNCRestartNotificationName @"LemonDNCRestartNotificationName" // 重启当前进程
#define LemonDNCHelpStartNotificationName @"LemonDNCHelpStartNotificationName" // 帮助拉起通知

#define LemonDNCRestartUserInfoTypeKey @"type" // LemonDNCRestartType 在userInfo中的key值
typedef NS_ENUM(NSUInteger, LemonDNCRestartType) {
    LemonDNCRestartTypeMonitor = 1, // 重启monitor
};

#define LemonDNCRestartUserInfoReasonKey @"reason" // LemonDNCRestartReason 在userInfo中的key值
typedef NS_ENUM(NSUInteger, LemonDNCRestartReason) {
    LemonDNCRestartReasonFullDiskAccess = 1, // 完全磁盘访问权限
};

#endif /* LemonDNCDefine_h */
