//
//  LMSimilarPhotoResultViewContoller.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMSimilarPhotoGroup.h"
#import <QMUICommon/LMImageButton.h>
#import <QMUICommon/QMBaseViewController.h>

@interface LMSimilarPhotoResultViewContoller : QMBaseViewController
@property NSMutableArray<LMSimilarPhotoGroup *> *similarPhotoGroups;

-(void)removeNotification;

- (void)updateScanResult:(NSMutableArray *)result;

@end
