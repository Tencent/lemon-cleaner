//
//  LMPhotoItem.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LM_NOTIFICATION_ITEM_DELECTED       @"LMNotificaitonItemDelected"
#define LM_KEY_ITEM                         @"delItem"
#define LM_KEY_INDEX                        @"delIndex"
#define LM_NOTIFICATION_ITEM_UPDATESELECT       @"LMNotificaitonItemUpdateSelect"
#define LM_NOTIFICATION_ITEM_UPDATESELECT_PATH       @"LM_NOTIFICATION_ITEM_UPDATESELECT_PATH"
#define LM_NOTIFICATION_PREVIEWITEM_UPDATESELECT       @"LMNotificaitonPreviewItemUpdateSelect"
#define LM_NOTIFICATION_RELOAD       @"LMNotificaitonReload"
#define LM_NOTIFCATION_CREAT_ALBUM_FINISHED      @"LMNotificationCreatAlbumFinished"
#define LM_NOTIFACTION_SCAN_SYSTEM_PHOTO         @"LMNotifactionScanSystemPhoto"

@interface LMPhotoItem : NSObject {
    NSURL *url;
}
@property NSString* path;
@property BOOL isSelected;
@property BOOL isDeleted;
@property BOOL isPrefer;
@property(strong) NSImage *previewImage;
@property long long imageSize;

- (void)requestPreviewImage;

- (instancetype)mutableCopyWithZone:(NSZone *)zone;

+ (void )cancelAllPreviewLoadingOperationQueue;
@end
