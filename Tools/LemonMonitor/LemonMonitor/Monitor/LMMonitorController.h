//
//  LMMonitorController.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN



@interface LMMonitorController : NSWindowController

@property (assign, readonly) BOOL isShow;  // monitor 是否在显示
@property(nonatomic, strong) NSStatusItem *statusItem;

- (void)load;
- (void)show;
- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
