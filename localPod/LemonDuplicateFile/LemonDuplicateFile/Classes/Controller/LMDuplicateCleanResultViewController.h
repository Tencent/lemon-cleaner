//
//  LMDuplicateCleanedViewController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/26.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMDuplicateFileNotFoundViewController.h"
#import <QMUICommon/QMBaseViewController.h>
@interface LMDuplicateCleanResultViewController : QMBaseViewController

@property(assign) double cleanSize;

@property(strong, nonatomic) NSImageView *imageView;
@property(strong, nonatomic) NSTextField *cleanTitleLabel;
@property(strong, nonatomic) NSTextField *cleanSubTitleLabel;

@end
