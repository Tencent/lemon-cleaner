//
//  LemonDNCServier.m
//  Lemon
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "LemonDNCServier.h"
#import "LemonDNCDefine.h"
#import "LemonDaemonConst.h"

@implementation LemonDNCServier


- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static LemonDNCServier *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)addServer {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(helpStartNotification:) name:LemonDNCHelpStartNotificationName object:nil];
}

- (void)helpStartNotification:(NSNotification *)notify {
    NSString *appPath = notify.userInfo[@"appPath"];
    NSTimeInterval delay = [notify.userInfo[@"delay"] floatValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self __openAppWithAppPath:appPath];
    });
}

-(void)__openAppWithAppPath:(NSString *)appPath {
    NSLog(@"%s, open app path %@", __PRETTY_FUNCTION__, appPath);
    if (![appPath isKindOfClass:NSString.class] && appPath.length != 0) {
        return;
    }
    NSError *error = NULL;
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:appPath]
                                                                              options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation
                                                                        configuration:@{NSWorkspaceLaunchConfigurationArguments: @[[NSString stringWithFormat:@"%lu", LemonAppRunningNormal]]}
                                                                                error:&error];
    NSLog(@"%s, open app: %@, %@", __PRETTY_FUNCTION__, app, error);
}


@end
