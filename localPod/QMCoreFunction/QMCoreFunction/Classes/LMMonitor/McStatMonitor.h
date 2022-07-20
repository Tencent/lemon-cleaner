//
//  McStatMonitor.h
//  McStat
//
//  Created by developer on 12-4-6.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface McStatMonitor : NSObject
{
    int refreshInterval;
    
    // check thread esc
    BOOL escThread;
    
    // battery is available or not
    BOOL isExistBattery;
}

@property (readonly, getter=isProcessSamplerOn) BOOL processSamplerOn;
//各种标志位
@property (atomic, assign) NSInteger trayType;//托盘icon上相应的功能是否打开
@property (atomic, assign) BOOL isTrayPageOpen;//打开了托盘页面，获取所有的功能

+ (McStatMonitor *)shareMonitor;

- (void)startRunMonitor;
- (void)stopRunMonitor;

/// @ret array of McProcessInfoData
- (NSArray *)processInfo;
- (void)refreshProcessInfo;
- (NSArray *)fetchCacheProcessInfo;
- (void)setProcessPortStat:(BOOL)isStat;

- (NSDictionary*)getDiskInfoDict;
@end
