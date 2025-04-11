//
//  LMPhotoItem.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LMPhotoItem;

#define LM_NOTIFICATION_ITEM_DELECTED       @"LMNotificaitonItemDelected"
#define LM_KEY_ITEM                         @"delItem"
#define LM_KEY_INDEX                        @"delIndex"
#define LM_NOTIFICATION_ITEM_UPDATESELECT       @"LMNotificaitonItemUpdateSelect"
#define LM_NOTIFICATION_ITEM_UPDATESELECT_PATH       @"LM_NOTIFICATION_ITEM_UPDATESELECT_PATH"
#define LM_NOTIFICATION_PREVIEWITEM_UPDATESELECT       @"LMNotificaitonPreviewItemUpdateSelect"
#define LM_NOTIFICATION_RELOAD       @"LMNotificaitonReload"
#define LM_NOTIFCATION_CREAT_ALBUM_FINISHED      @"LMNotificationCreatAlbumFinished"
#define LM_NOTIFACTION_SCAN_SYSTEM_PHOTO         @"LMNotifactionScanSystemPhoto"


typedef void(^ValueDidChangeBlock)(LMPhotoItem *item);

@interface LMPhotoItem : NSObject {
    NSURL *url;
}
@property NSString* path;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isDeleted;
@property (nonatomic) BOOL isPrefer;
@property (nonatomic) BOOL canRemove; 
@property (nonatomic) BOOL externalStorage; // 是否为外接磁盘
@property (nonatomic, strong) NSImage *previewImage;
@property (nonatomic) long long imageSize;

- (void)requestPreviewImage;

- (instancetype)mutableCopyWithZone:(NSZone *)zone;

+ (void )cancelAllPreviewLoadingOperationQueue;

@property (nonatomic, copy) ValueDidChangeBlock isSelectedDidChangeBlock;
@property (nonatomic, copy) ValueDidChangeBlock previewImageDidChangeBlock;


@end
