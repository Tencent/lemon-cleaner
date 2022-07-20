//
//  BrowserAppTableCellView.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BaseHoverTableCellView.h"
#import "BrowserApp.h"
#import "RunningAppPopViewController.h"


@interface BrowserAppTableCellView : BaseHoverTableCellView

@property(strong) NSImageView *appImageView;
@property(strong) NSTextField *appNameLabel;
@property(weak) RunningAppPopViewController *controller;

- (void)updateViewsBy:(BrowserApp *)browserApp;
@end
