//
//  McUninstallSelectedViewController.h
//  LemonMonitor
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMTrackScrollView.h>
#import "LMLocalApp.h"
#import <QMUICommon/QMBaseViewController.h>

@class McUninstallSelectedViewController;
@protocol McUninstallSelectedDelegate <NSObject>

- (void)selectedDidCancel:(McUninstallSelectedViewController*)viewController;
- (void)selectedDidDone:(McUninstallSelectedViewController*)viewController withSoft:(LMLocalApp *)soft;

@end

@class QMTrackOutlineView;
@interface McUninstallSelectedViewController : QMBaseViewController
{
    IBOutlet NSImageView *iconView;
    IBOutlet NSTextField *titleView;
    IBOutlet QMTrackOutlineView *listView;
    IBOutlet NSButton *checkAllButton;
    
    IBOutlet NSButton *uninstallButton;
    IBOutlet NSButton *cancelButton;
    
    __weak IBOutlet NSView *lineView;
    
}
@property (nonatomic, assign) id<McUninstallSelectedDelegate> delegate;
@property (nonatomic, strong) LMLocalApp *soft;

@property (nonatomic, assign) IBOutlet QMTrackScrollView *scrollView;

@end
