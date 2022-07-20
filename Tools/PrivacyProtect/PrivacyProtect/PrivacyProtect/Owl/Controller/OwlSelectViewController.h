//
//  OwlSelectViewController.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
@interface OwlSelectViewController : QMBaseViewController
@property (nonatomic, strong) NSMutableArray *wlModelArray;
- (instancetype)initWithFrame:(NSRect)frame;
- (void)clickCancel;
- (void)reloadData;
@end
