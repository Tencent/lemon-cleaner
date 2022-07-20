//
//  LemonBizManager.m
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LemonBizManager.h"
#import <AppKit/AppKit.h>
#import "McUninstall.h"
#import "LMLemonXPCProtocol.h"

@interface NSTimer(DaemonBlock)
@end
@implementation NSTimer(DaemonBlock)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo handler:(void(^)(void))handler
{
    return [self timerWithTimeInterval:ti target:self selector:@selector(_timerHandler:) userInfo:[handler copy] repeats:yesOrNo];
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo handler:(void(^)(void))handler
{
    return [self scheduledTimerWithTimeInterval:ti target:self selector:@selector(_timerHandler:) userInfo:[handler copy] repeats:yesOrNo];
}

+ (void)_timerHandler:(NSTimer *)inTimer;
{
    if (inTimer.userInfo)
    {
        void(^handler)(void) = [inTimer userInfo];
        handler();
    }
}

@end

@interface LemonBizManager()
@property (nonatomic, assign) BOOL mgrUpdate;
@end

@implementation LemonBizManager

+ (LemonBizManager *)shareInstance{
    static LemonBizManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    NSLog(@"LemonBizManager init begin");
    if (self) {
        [[NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES handler:^{
            if (!self.mgrUpdate && ![[NSFileManager defaultManager] fileExistsAtPath:DEFAULT_APP_PATH] &&
                [NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count==0)
            {
                //NSLog(@"LemonBizManager remove to trash");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self removeDockIcon];
                    uninstallCastle();
                });
            }
        }] fire];        
    }
    return self;
}

- (void)mgrUpdateNotificaton:(NSNotification *)notify
{
    self.mgrUpdate = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.mgrUpdate = NO;
    });
}

// 用于删除Dock上的图标
- (void)removeDockIcon
{
    //读取Dock的配置文件，通过CFPreferences的API可以避免直接读文件不同步的问题
    CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
    NSArray *apps = (__bridge_transfer NSArray *)CFPreferencesCopyAppValue( CFSTR("persistent-apps"), CFSTR("com.apple.dock") );
    
    if (!apps || ![apps isKindOfClass:[NSArray class]])
        return;
    
    NSMutableArray *removeApps = [[NSMutableArray alloc] init];
    for (NSDictionary *appInfo in apps)
    {
        if (![appInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *titleInfo = [appInfo objectForKey:@"tile-data"];
        if (!titleInfo || ![titleInfo isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *fileInfo = [titleInfo objectForKey:@"file-data"];
        if (!fileInfo || ![fileInfo isKindOfClass:[NSDictionary class]])
            continue;
        
        NSString *fileURLString = [fileInfo objectForKey:@"_CFURLString"];
        NSURL *fileURL = [NSURL URLWithString:fileURLString];
        NSString *filePath = [fileURL path];
        if (!filePath)
            continue;
        
        if ([[filePath lastPathComponent] isEqualToString:MAIN_APP_NAME])
        {
            [removeApps addObject:appInfo];
        }
    }
    
    if ([removeApps count] > 0)
    {
        NSMutableArray *tempApps = [apps mutableCopy];
        [tempApps removeObjectsInArray:removeApps];
        
        //写入Dock的配置文件
        //通过CFPreferences的API可以避免直接读文件不同步的问题
        CFPreferencesSetAppValue(CFSTR("persistent-apps"), (__bridge CFArrayRef)tempApps, CFSTR("com.apple.dock"));
        CFPreferencesAppSynchronize(CFSTR("com.apple.dock"));
        
        //杀死Dock进程(重启)
        system("killall Dock");
    }
}

@end
