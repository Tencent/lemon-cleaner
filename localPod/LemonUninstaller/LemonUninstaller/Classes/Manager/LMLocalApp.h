//
//  LMLocalApp.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMSafeMutableArray.h"
#import "LMFileGroup.h"
#import <QMCoreFunction/LoginItemManager.h>
#import "LMUninstallXMLParseManager.h"

NS_ASSUME_NONNULL_BEGIN



#define LMNotificationDelectProgress        @"notification_delected_progress"
#define LMNotificationKeyDelProgress        @"key_del_progress"
#define LMNotificationKeyDelObject          @"key_del_object"
#define LMNotificationKeyIsDelFinished      @"key_is_del_finished"
#define LMNotificationKeyListChangedReason  @"key_listChangedReason"
#define LMNotificationKeyDelItem            @"key_delItem"

#define LMChangedReasonDel                    1
#define LMChangedReasonPartialDel             2
#define LMChangedReasonScanEnd                3
#define LMChangedReasonScanInit               4   //初次扫描完,只扫描了App名路径等,未开始扫描大小,残留项.


typedef enum {
    AppTrashLeftover = 0, //卸载残留模块扫描(用户主动拖 app 到Trash目录)
    AppUninstall = 1,   //软件卸载模块扫描
}AppScanType;

@interface LMLocalApp : NSObject <NSCopying>
- (instancetype)initWithPath:(NSString *)bundlePath;
- (void) scanFileItems:(AppScanType)scanType;

- (LMFileGroup *)groupByType:(LMFileType)type;
- (void) setAllSystemLoginItems:(NSArray<LMLoginItem *> *)loginItem;
- (void) simpleMerge:(LMLocalApp *)app;
- (void) bothScanCompleteMerge:(LMLocalApp *)app;
- (void) resetScanStateMerge:(LMLocalApp *)app;

- (void) delSelectedItem;
- (void) cleanDeletedItems;
- (NSString *) getNameWithBundleId;  //  返回String格式 name#bundleId

@property (nonatomic, readonly) NSString                   *bundleID;
@property (nonatomic, readonly, strong) NSString            *appName;
@property (nonatomic, readonly, strong) NSString            *showName;
@property (nonatomic, readonly, strong) NSString            *executableName;
@property (nonatomic, readonly, strong) NSString            *version;
//@property (nonatomic, readonly, strong) NSString          *buildVersion;
//@property (nonatomic, readonly, strong) NSString          *copyright;
@property (nonatomic, readonly, strong) NSString            *bundlePath;
//@property (nonatomic, readonly, strong) NSString          *minSystem;
@property (nonatomic, readonly, strong) NSNumber            *bundleSize;
@property (nonatomic, readonly, strong) NSDate              *lastUsedDate;
//@property (nonatomic, readonly, strong) NSDate            *createDate;
@property (nonatomic, readonly, strong) NSImage             *icon;
@property (nonatomic, readonly, assign) NSInteger           totalSize;
@property (nonatomic, readonly) NSInteger                   fileItemCount;
@property (nonatomic, readonly) NSInteger                   selectedSize;
@property (nonatomic, readonly) NSInteger                   selectedCount;
@property (nonatomic, readonly) BOOL                        isBundleItemDelected;
@property (nonatomic, assign) BOOL                          isScanComplete;
@property (nonatomic, readonly, strong) NSArray<LMFileGroup *> *fileItemGroup;
@property (nonatomic, readonly, strong) NSArray<LMFileGroup *> *validFileItemGroup;
// 相同 bundleid 的 app 需要 merge(显示为一条)
@property (nonatomic, readonly, strong) NSArray<LMLocalApp *> *otherSameBundleApps;

@end



@interface LMDateWrapper : NSObject
@property(nonatomic, strong) NSDate *date;

- (instancetype)initWithDate:(NSDate *)date;
@end
NS_ASSUME_NONNULL_END
