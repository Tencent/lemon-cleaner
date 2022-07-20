//
//  LMSystemFeatureViewController.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMValueHistory.h"
#import "QMNetworkPlotView.h"
#import <QMUICommon/QMBaseWindowController.h>
#import <QMUICommon/QMBaseViewController.h>
#import <LemonHardware/DiskModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ToolCongireDelegate<NSObject>

-(QMBaseWindowController *)getControllerByClassName:(NSString *)clsName;

@end

@interface LMSystemFeatureViewController : QMBaseViewController


@property (strong, nonatomic)  QMNetworkPlotView *downSpeedPlotView;
@property (strong, nonatomic)  QMNetworkPlotView *upSpeedPlotView;
@property (strong, nonatomic)  NSTextField *upSpeedLabel;
@property (strong, nonatomic)  NSTextField *downSpeedLabel;
@property (strong, nonatomic)  NSTextField *upSpeedKbLabel;
@property (strong, nonatomic)  NSTextField *downSpeedKbLabel;

@property (assign, nonatomic, getter = isWindowVisible) BOOL windowVisible;


@property (assign, nonatomic) QMValueHistory *downSpeedHistory;
@property (assign, nonatomic) QMValueHistory *upSpeedHistory;
@property (nonatomic, assign) float upSpeed;
@property (nonatomic, assign) float downSpeed;

@property (nonatomic, weak) id<ToolCongireDelegate> delegate;

@property (assign, nonatomic, getter = isLoading) BOOL loading; // show loading view

@property (nonatomic) DiskModel *diskModel;

+ (NSDictionary *)networkInfoItemWithPid:(id)pid name:(NSString *)processName icon:(NSImage *)image upSpeed:(NSNumber *)upSpeed downSpeed:(NSNumber *)downSpeed;

- (void)startMonitor;
- (void)stopMonitor;



@end

NS_ASSUME_NONNULL_END
