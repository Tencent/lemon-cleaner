//
//  OwlWhiteListViewController.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>

@interface OwlWhiteListViewController : QMBaseViewController

@property (nonatomic, strong) NSWindowController *selectWindowController;
- (instancetype)initWithFrame:(NSRect)frame;

- (void)reloadWhiteList;

@end
