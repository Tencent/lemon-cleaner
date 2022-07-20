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

- (instancetype)initWithFrame:(NSRect)frame;

- (void)removeNotifyDelegate;
@end
