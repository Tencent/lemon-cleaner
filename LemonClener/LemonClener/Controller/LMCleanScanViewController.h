//
//  LMCleanScanViewController.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/QMBaseViewController.h>
#define MAS_CLEAN_TRASH_FINISH @"mac_clean_trash_finish"  //垃圾清理

@class LMButton;
@class LMBorderButton;

@interface LMCleanScanViewController : QMBaseViewController

@property (nonatomic, assign) long long fileMoveTotalNum;
@property (nonatomic, weak, readonly) IBOutlet LMButton *startScanBtn;
@property (nonatomic, weak, readonly) IBOutlet LMButton *resultBtn;
@property (nonatomic, weak, readonly) IBOutlet NSTextField *mainViewTitleLabel;
@property (nonatomic, weak, readonly) IBOutlet NSTextField *mainViewDescLabel;
@property (nonatomic, weak, readonly) IBOutlet NSTextField *resultTitleLabel;
@property (nonatomic, weak, readonly) IBOutlet LMBorderButton *showBIgBtn;
@property (nonatomic, weak, readonly) IBOutlet NSView *guideView;

- (void)showAnimate;

@end
