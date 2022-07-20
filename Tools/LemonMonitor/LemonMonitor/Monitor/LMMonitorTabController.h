//
//  MainTabController.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
NS_ASSUME_NONNULL_BEGIN

@interface LMMonitorTabController : QMBaseViewController

/// tabIndex为-1，说明没有tab项, Bind到view中的segmentedControl的selectedIndex
@property (assign, nonatomic) NSInteger tabIndex;
@property (readonly) NSArray *viewControllers;

@property (strong, nonatomic) NSArray *tabItems;
@property (readonly) NSSegmentedControl *segmentedControl;



- (instancetype)initWithControllers:(NSArray *)controllers titles:(NSArray *)titles;
- (NSViewController *)selectedController;
- (void)setSelectedController:(NSViewController *)controller;
@end



@interface LMSettingsViewController : NSViewController
@end


NS_ASSUME_NONNULL_END
