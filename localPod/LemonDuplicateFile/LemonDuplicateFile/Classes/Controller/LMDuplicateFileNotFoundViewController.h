//
//  LMDuplicateFileNotFoundViewController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/28.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>

@interface LMDuplicateFileNotFoundViewController : QMBaseViewController

@property(nonatomic) NSTextField *descLabel;
@property(nonatomic) NSImageView *imageView;
@property(nonatomic) BOOL isScanCancel;

@end
