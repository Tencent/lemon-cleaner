//
//  AppDelegate.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QMMonitorController;

typedef NS_ENUM(NSInteger, CurrentNetworkStatus) {
    CurrentNetworkStatusUnknown          = -2, //初始化
    CurrentNetworkStatusNotReachable     = 0,  //无网络
    CurrentNetworkStatusReachable        = 1   //有网络
};

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) CurrentNetworkStatus currentNet;
@property (assign) IBOutlet NSWindow *window;

@end
