//
//  LMDuplicateResultViewController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/20.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMDuplicateBatch.h"
#import "ExpandItemDelegate.h"
#import "CheckBoxUpdateDelegate.h"
#import <QMUICommon/QMBaseViewController.h>

@interface LMDuplicateScanResultViewController : QMBaseViewController<ExpandItemDelegate,CheckBoxUpdateDelegate>

@property(nonatomic) NSArray *resultArray;

@end
