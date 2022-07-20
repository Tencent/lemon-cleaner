//
//  LMMonitorPoppverController.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMSystemFeatureViewController.h"
#import "LMCleanViewController.h"
#import "LMMonitorTabController.h"
#import <QMUICommon/QMBubble.h>
#import <LemonHardware/DiskModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMMonitorPoppverController : NSObject


@property (nonatomic, readonly) NSWindow *bubbleWindow;
@property (strong, nonatomic) QMBubble *bubble;


@property (nonatomic, strong) LMMonitorTabController *tabViewController;
@property (nonatomic, strong) LMCleanViewController *cleanViewController;
@property (nonatomic, strong) LMSystemFeatureViewController *systemFeatureViewController;
@property (nonatomic, strong) LMCleanViewController *memoryViewController;
@property (nonatomic, strong) LMSystemFeatureViewController *networkViewController;

@property (strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSView *statusView;

@property (nonatomic, readonly) BOOL attached;

@property (nonatomic) DiskModel *diskModel;

- (void)showPopover;
- (void)dismissPopover;

- (NSPoint)configBubbleWithCurrentState;

NS_ASSUME_NONNULL_END

@property (nonatomic, copy) void (^dismissCompletion)(void); //popover dimisss的时候回调.
@end
