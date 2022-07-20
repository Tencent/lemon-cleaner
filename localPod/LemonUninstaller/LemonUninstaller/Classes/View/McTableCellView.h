//
//  McTableCellView.h
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/QMProgressView.h>
#import "McUninstallSoftManager.h"
#import "LMLocalApp.h"

@interface McTableCellView : NSTableCellView
@property (weak) IBOutlet NSTextField *appName;
@property (weak) IBOutlet NSTextField *lastOpen;
@property (weak) IBOutlet NSTextField *sizeLabel;
@property (weak) IBOutlet LMBorderButton *btnRemove;
@property (weak) IBOutlet NSImageView *appIcon;
@property (nonatomic, copy) void(^actionHandler)(void);
@property (weak) IBOutlet NSProgressIndicator *sizeProgressView;
@property (weak) IBOutlet NSProgressIndicator *timeprogressView;

@property (weak) LMLocalApp *soft;
- (void)uninstallClick:(id)sender;

@end

