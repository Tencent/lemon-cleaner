//
//  LMPhotoCleanViewController.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMSimilarPhotoGroup.h"
#import <QMUICommon/QMBaseViewController.h>

@interface LMPhotoCleanViewController : QMBaseViewController

- (void)deleteSelectItem:(NSMutableArray <LMSimilarPhotoGroup *>*)similarPhotoGroups;

@end
