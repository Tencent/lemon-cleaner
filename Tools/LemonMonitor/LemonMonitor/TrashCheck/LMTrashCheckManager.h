//
//  LMTrashCheckManager.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/QMTaskScheduler.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMTrashCheckManager : NSObject
+ (instancetype)manager;
@property (nonatomic, strong) QMTaskScheduler *task;
@end

NS_ASSUME_NONNULL_END
