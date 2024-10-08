//
//  QMXMLItemDefine.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#ifndef QMCleanDemo_QMXMLItemDefine_h
#define QMCleanDemo_QMXMLItemDefine_h

#ifdef DEBUG
#define debug_NSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define debug_NSLog(format, ...)
#endif

// 清理XML相关字段
#define kXMLKeyID            @"id"
#define kXMLKeyColumn        @"column"
#define kXMLKeyRelation      @"relation"
#define kXMLKeyValue         @"value"
#define kXMLKeyValue1        @"value1"
#define kXMLKeyAction        @"action"
#define kXMLKeySandboxType   @"sandbox"

#define kXMLKeyType                 @"type"
#define kXMLKeyFile                 @"file"
#define kXMLKeyLeftCache            @"leftcache"
#define kXMLKeyLeftLog              @"leftlog"
#define kXMLKeyLaunguage            @"language"
#define kXMLKeyOS                   @"os"
#define kXMLKeyCleanEmptyFolder     @"cleanemptyfolder"
#define kXMLKeyCleanHiddenFile      @"cleanhiddenfile"
#define kXMLKeyMail                 @"mail"
#define kXMLKeySoft                 @"soft"
#define kXMLKeyDerivedApp           @"derivedapp"
#define kXMLKeyArchives             @"archive"
#define kXMLKeyAppCache             @"appcache"
#define kXMLKeyWechatAvatar         @"wechatAvatar"
#define kXMLKeyWechatImage          @"wechatImage"
#define kXMLKeyWechatImage90        @"wechatImage90"
#define kXMLKeyWechatFile           @"wechatFile"
#define kXMLKeyWechatVideo          @"wechatVideo"
#define kXMLKeyWechatAudio          @"wechatAudio"

#define kXMLKeyAppPath              @"apppath"
#define kXMLKeyBundle               @"bundle"
#define kXMLKeyAppVersion           @"appversion"
#define kXMLKeyBuildVersion         @"buildversion"

#define kXMLKeyBundleId             @"bundleid"
#define kXMLKeyAppStoreBundleId     @"appstorebundleid"
#define kXMLKeyRecommend            @"recommend"
#define kXMLKeyDefaultState         @"defaultstate"
#define kXMLKeyFastMode             @"fastmode"
#define kXMLKeyShowAction           @"showaction"
#define kXMLKeyClean                @"clean"

#define kXMLKeyTruncate     @"truncate"
#define kXMLKeyMoveTrash    @"movetrash"
#define kXMLKeyCutBinary    @"cutbinary"
#define kXMLKeyDeleteBinary    @"deleteBinary"
#define kXMLKeyDeletePackage    @"deletePackage"
#define kXMLKeyRemoveLanguage    @"removelanguage"
#define KXMLKeySafariCookies     @"safaricookie"

#define kXMLKeyAtom         @"atom"
#define kXMLKeyFileName     @"filename"
#define kXMLKeyFilePath     @"filepath"
#define kXMLKeyLevel        @"level"
#define kXMLKeyCleaner      @"cleaner"

#define kXMLKeyPath         @"path"

#define kXMLKeyGarbage      @"garbage"
#define kXMLKeyFilters      @"filters"
#define kXMLKeyFilter       @"filter"
#define kXMLKeyCautions     @"cautions"
#define kXMLKeyCaution      @"caution"
#define kXMLKeyAppName      @"appname"
#define kXMLKeyCategory     @"category"
#define kXMLKeyItem         @"item"

#define kXMLKeyTitle     @"title"
#define kXMLKeyTips      @"tips"

#define kXMLKeySpecial   @"special"
#define kXMLKeyTemp      @"SystemTempDir"
#define kXMLKeyFireFoxProfiles      @"FireFoxProfiles"

#define kXMLKeyLanguage  @"laungeuagekey"

#define kXMLKeyDeveloper    @"developer"
#define kXMLKeyBrokenRegister @"brokenregister"
#define kXMLKeyBrokenPlist     @"brokenplist"
#define kXMLKeyDir        @"dir"
#define kXMLKeyAppLeft    @"appleft"
#define kXMLKeyBinary     @"binary"
#define kXMLKeyOtherBinary     @"otherBinary"
#define kXMLKeyInstallPackage     @"InstallPackage"


#define kXMLKeySearchName @"searchname"
#define kXMLKeySearchBundle @"searchbundle"
#define kXMLKeyAbs        @"abs"


#define kIconImageSize    16

// 扫描类型
typedef enum
{
    QMActionFileType,
    QMActionLeftCacheType,
    QMActionLeftLogType,
    QMActionDirType,
    QMActionLanguageType,
    QMActionBrokenReigisterType,
    QMActionBrokenPlistType,
    QMActionAppLeftType,
    QMActionBinarBinaryType,
    QMActionBinarOtherBinaryType,
    QMActionInstallPackage,
    QMActionDeveloperType,
    QMActionMailType,
    QMActionSoftType,
    QMActionSoftAppCacheType,
    QMActionDerivedAppType,
    QMActionArchivesType,
    QMActionWechatAvatar,
    QMActionWechatImage,
    QMActionWechatImage90,
    QMActionWechatFile,
    QMActionWechatVideo,
    QMActionWechatAudio,
}QMActionType;

// 删除类型
typedef enum
{
    QMCleanTypeNone = 0,
    QMCleanRemove,
    QMCleanMoveTrash,
    QMCleanCutBinary,
    QMCleanDeleteBinary,
    QMCleanDeletePackage,
    QMCleanTruncate,
    QMCleanRemoveLogin,
    QMCleanRemoveLanguage,
    QMCleanSafariCookies,
    QMCleanDBRecord,
}QMCleanType;

@class QMResultItem;
@protocol QMScanDelegate <NSObject>

- (NSDictionary *)xmlFilterDict;
- (BOOL)needStopScan;
- (BOOL)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item;
- (void)scanActionCompleted;
- (NSString *)currentScanCategoryKey;

@end


#endif
