//
//  LMDaemonStartupHelper.h
//  Lemon
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define REPORT_KEY_ACTIVATE_DAEMON_ERROR             9901
#define REPORT_KEY_ACTIVATE_DAEMON_AGAIN_ERROR       9902
#define REPORT_KEY_ACTIVATE_DAEMON_FAIL              9903

@interface LMDaemonStartupHelper : NSObject
@property (nonatomic, strong) NSString *agentPath;
@property (nonatomic, strong) NSArray *arguments;
@property (nonatomic, strong) NSString *cmdPath;
+ (LMDaemonStartupHelper *)shareInstance;
- (int) activeDaemon;
- (int) notiflyDaemonClientExit;
@end

NS_ASSUME_NONNULL_END
