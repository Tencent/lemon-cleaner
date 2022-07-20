//
//  LemonCleanViewController.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMMonitorTabController.h"
#import <LemonClener/QMLiteCleanerManager.h>
#import <QMUICommon/QMBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMMemoryItem : NSObject
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, assign) uint64 memorySize;

@end

@protocol KillProcessDelegate <NSObject>
- (void)killProcess:(id)sender;
@end

@interface LMCleanViewController : NSViewController <KillProcessDelegate, QMLiteCleanerDelegate>
@property (nonatomic, weak) LMMonitorTabController *tabController;
- (void)startMonitor;
- (void)stopMonitor;
- (void)changeTrashViewState;
@end

NS_ASSUME_NONNULL_END
