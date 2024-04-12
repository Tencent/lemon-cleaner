//
//  AppTrashDel.h
//  LemonMonitor
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppTrashDel : NSObject
- (void)delTrashOfApps:(NSArray *)apps;
+ (BOOL)enableTrashWatch:(BOOL)isEnable;
+ (void)keepTrashWatcherAlive;
@end

NS_ASSUME_NONNULL_END
