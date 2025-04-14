//
//  Owl2Manager.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

extern NSNotificationName const OwlWhiteListChangeNotication;
extern NSNotificationName const OwlLogChangeNotication;
extern NSNotificationName const OwlShowWindowNotication;
extern NSNotificationName const OwlWatchVedioStateChange;
extern NSNotificationName const OwlWatchAudioStateChange;

@interface Owl2Manager : NSObject {
    NSString *dbPath;
    FMDatabase *db;
}

@property (nonatomic, strong) NSMutableArray *wlArray;
@property (nonatomic, strong) NSMutableArray *logArray;
@property (nonatomic, assign) BOOL isWantShowOwlWindow;
@property (nonatomic, assign) BOOL isWatchVideo;
@property (nonatomic, assign) BOOL isWatchAudio;
@property (nonatomic, assign) BOOL isFetchDataFinish;

//protected
@property (nonatomic, strong) NSMutableArray *allApps;
@property (nonatomic, assign) int notificationCount;
@property (nonatomic, strong) NSMutableDictionary *owlVedioItemDic;
@property (nonatomic, strong) NSMutableDictionary *owlAudioItemDic;

+ (Owl2Manager *)sharedManager;

- (NSMutableArray*)getAllAppInfoWithIndexArray:(NSArray*)indexArray;
- (NSMutableDictionary *)getAppInfoWithPath:(NSString*)appPath appName:(NSString*)name;

- (BOOL)isMonitorRunning;
- (BOOL)isLemonRunning;
- (void)startOwlProtect;
- (void)stopOwlProtect;

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB;
- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB;
- (void)loadOwlDataFromMonitor;
- (void)addAppWhiteItem:(NSDictionary*)dic;
- (void)removeAppWhiteItemIndex:(NSInteger)index;
- (void)replaceAppWhiteItemIndex:(NSInteger)index;
- (void)resaveWhiteList;

@end
