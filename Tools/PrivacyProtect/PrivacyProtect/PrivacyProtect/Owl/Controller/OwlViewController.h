//
//  OwlViewController.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>

@interface OwlViewController : QMBaseViewController

@property (nonatomic, strong) NSWindowController *wlWindowController;
@property (nonatomic, strong) NSWindowController *logWindowController;
@property (nonatomic, strong) NSWindowController *npWindowController;

- (instancetype)initWithFrame:(NSRect)frame;

- (void)removeNotifyDelegate;

// 一键开启
- (void)oneClick;

@end
