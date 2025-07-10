//
//  OwlWindowController.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

@interface OwlWindowController : QMBaseWindowController

- (instancetype)initViewController:(NSViewController*)viewController;

// 一键开启
- (void)oneClick;

- (void)onClickVideo:(BOOL)state;
- (void)onClickAudio:(BOOL)state;
- (void)onClickScreen:(BOOL)state;
- (void)onClickAutomatic:(BOOL)state;

@end
