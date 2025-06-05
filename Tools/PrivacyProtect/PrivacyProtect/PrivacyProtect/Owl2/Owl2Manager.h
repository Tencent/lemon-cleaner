//
//  Owl2Manager.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
@class Owl2AppItem;

extern NSNotificationName const OwlWhiteListChangeNotication;
extern NSNotificationName const OwlLogChangeNotication;
extern NSNotificationName const OwlShowWindowNotication;

@interface Owl2Manager : NSObject {
    NSString *dbPath;
    FMDatabase *db;
}

@property (nonatomic, strong) NSMutableDictionary<NSString * /*bundleId*/, Owl2AppItem *> *wlDic;
@property (nonatomic, strong) NSMutableArray *logArray;
@property (nonatomic, assign) BOOL isWantShowOwlWindow;
@property (nonatomic, assign) BOOL isWatchVideo;
@property (nonatomic, assign) BOOL isWatchAudio;
@property (nonatomic, assign) BOOL isWatchScreen;
@property (nonatomic, assign) BOOL isFetchDataFinish;

//protected
@property (nonatomic, assign) int notificationCount;
@property (nonatomic, strong) NSMutableDictionary *owlVideoItemDic;
@property (nonatomic, strong) NSMutableDictionary *owlAudioItemDic;
@property (nonatomic, strong) NSMutableDictionary *owlSystemAudioItemDic;
@property (nonatomic, strong) NSMutableArray *owlScreenItemArray;
@property (nonatomic, strong) NSMutableDictionary *owlScreenItemDic;

+ (Owl2Manager *)sharedManager;

- (NSArray<Owl2AppItem *>*)getAllAppInfo;

- (BOOL)isMonitorRunning;
- (BOOL)isLemonRunning;
- (void)startOwlProtect;
- (void)stopOwlProtect;

- (void)setWatchVedio:(BOOL)state toDb:(BOOL)toDB;
- (void)setWatchAudio:(BOOL)state toDb:(BOOL)toDB;
- (void)setWatchScreen:(BOOL)state toDb:(BOOL)toDB;
- (void)loadOwlDataFromMonitor;
- (void)addWhiteWithAppItem:(Owl2AppItem *)appItem;
- (void)removeAppWhiteItemWithIdentifier:(NSString *)identifier;
- (void)killAppWithDictItem:(NSDictionary *)dictItem;

// 为通知创建
@property (nonatomic, strong) NSMutableDictionary *notificationInsertLogList;

@end
