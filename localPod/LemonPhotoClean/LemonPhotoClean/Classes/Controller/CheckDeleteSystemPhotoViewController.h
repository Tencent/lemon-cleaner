//
//  CheckDeleteSystemPhotoViewController.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMImageButton.h>
#import "LMSimilarPhotoGroup.h"
#import <QMUICommon/QMBaseViewController.h>
/**
 提示系统相册扫描结果需要手动清理
 */
@interface CheckDeleteSystemPhotoViewController : QMBaseViewController
//所有图片
@property (atomic,nonnull) NSMutableArray <LMSimilarPhotoGroup*>* result;
//是否有创建相册的权限
@property (nonatomic) Boolean authorizedForCreateAlbum;
//系统相册中的图片
@property (nonnull)NSMutableArray *systemPhotoArray;

@end
