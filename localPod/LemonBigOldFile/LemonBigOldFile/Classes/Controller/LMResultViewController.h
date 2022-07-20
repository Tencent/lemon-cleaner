//
//  LMResultViewController.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMBaseViewController.h"
#import <QMUICommon/LMGradientTitleButton.h>
#import <QMUICommon/LMPathBarView.h>
#import <QMUICommon/COSwitch.h>

@interface LMResultViewController : LMBaseViewController
{
    __weak IBOutlet NSTextField *totalSizeText;
    __weak IBOutlet NSTextField *selectedSizeText;
    __weak IBOutlet NSButton *cleanBtn;
    __weak IBOutlet NSButton *backBtn;
    
    __weak IBOutlet NSView *titleView;
    __weak IBOutlet NSButton *filterBtnAll;
    __weak IBOutlet NSButton *filterBtnMusic;
    __weak IBOutlet NSButton *filterBtnVideo;
    __weak IBOutlet NSButton *filterBtnDocument;
    __weak IBOutlet NSButton *filterBtnInstall;
    __weak IBOutlet NSButton *filterBtnOther;
    __weak IBOutlet COSwitch *previewBtn;
    
    __weak IBOutlet NSScrollView *outlineScrollView;
    __weak IBOutlet NSOutlineView *outlineView;
    
    __weak IBOutlet NSView *previewFrame;
    __weak IBOutlet NSView *previewContainer;
    __weak IBOutlet NSTextField *previewItemName;
    __weak IBOutlet NSTextField *previewItemSize;
    __weak IBOutlet LMPathBarView *previewItemPath;
    
    __weak IBOutlet NSView *topLineView;
    __weak IBOutlet NSView *bottomLineView;
    __weak IBOutlet NSView *previewLineView;
    
    __weak IBOutlet NSView *noFileView;
    __weak IBOutlet NSTextField *noFileDescLabel;
    
    __weak IBOutlet NSTextField *previewDescText;
}



- (void)reloadDataView;

@end
