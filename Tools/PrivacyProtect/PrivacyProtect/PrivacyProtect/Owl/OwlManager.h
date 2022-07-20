//
//  OwlManager.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSNotificationName const OwlWhiteListChangeNotication;
extern NSNotificationName const OwlLogChangeNotication;
extern NSNotificationName const OwlShowWindowNotication;
extern NSNotificationName const OwlWatchVedioStateChange;
extern NSNotificationName const OwlWatchAudioStateChange;

@interface OwlManager : NSObject {
    
}

@property (nonatomic, strong) NSMutableArray *wlArray;
@property (nonatomic, strong) NSMutableArray *logArray;
@property (nonatomic, assign) BOOL isWantShowOwlWindow;
@property (nonatomic, assign) BOOL isWatchVedio;
@property (nonatomic, assign) BOOL isWatchAudio;
@property (nonatomic, assign) BOOL isFetchDataFinish;
+ (OwlManager *)shareInstance;

- (NSMutableArray*)getAllAppInfoWithIndexArray:(NSArray*)indexArray;

- (BOOL)isMonitorRunning;
- (BOOL)isLemonRunning;
- (void)startOwlProtect;
- (void)stopOwlProtect;

- (void)loadDB;
- (void)closeDB;

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB;
- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB;
- (void)loadOwlDataFromMonitor;
- (void)addAppWhiteItem:(NSDictionary*)dic;
- (void)removeAppWhiteItemIndex:(NSInteger)index;
- (void)replaceAppWhiteItemIndex:(NSInteger)index;
- (void)resaveWhiteList;

- (void)startCameraWatchTimer;
- (void)stopCameraWatchTimer;
- (void)startAudioWatchTimer;
- (void)stopAudioWatchTimer;
@end
