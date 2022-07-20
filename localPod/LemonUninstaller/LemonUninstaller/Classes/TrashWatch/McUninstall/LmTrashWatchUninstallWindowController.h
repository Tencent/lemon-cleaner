//
//  McUninstallWindowController.h
//  QQMacMgrAgent
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMCoreFunction/McUninstallSoft.h>
#import "LMLocalApp.h"

@protocol McUninstallWindowControllerDelegate <NSObject>
- (void)uninstallFinished:(id)sender;
@end

@class McUninstallProgressView;
@interface LmTrashWatchUninstallWindowController : NSWindowController
{
    IBOutlet NSView *alertView;
    IBOutlet NSImageView *alertIconView;
    IBOutlet NSButton *alertCancelButton;
    IBOutlet NSButton *alertOKButton;
    IBOutlet NSTextField *alertTitleView;
    IBOutlet NSTextField *alertMessageView;
    __weak IBOutlet NSView *alertLineView;
    
    IBOutlet NSView *progressView;
    IBOutlet NSImageView *progressIconView;
    IBOutlet NSTextField *progressTitleView;
    IBOutlet McUninstallProgressView *progressLoadingView;
    
    IBOutlet NSView *sucessView;
    IBOutlet NSButton *sucessButton;
    IBOutlet NSTextField *sucessTitleView;
    
    __weak IBOutlet NSView *successLineView;
    
    
    
}
@property (nonatomic, strong) LMLocalApp *soft;
@property (nonatomic, assign) id<McUninstallWindowControllerDelegate> delegate;

- (void)show;

@end
