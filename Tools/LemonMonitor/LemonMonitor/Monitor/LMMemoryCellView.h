//
//  LMMemoryCellView.h
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMUICommon.h>
#import "LMCleanViewController.h"

#define KILL_PROCESS_AT_MONITOR @"kill_process_at_monitor"

NS_ASSUME_NONNULL_BEGIN

@interface LMMemoryCellView : NSTableCellView {
    NSBundle *bundle;
    NSGradient *gradient;
    CGFloat _closeButtonWidth;
}

@property (nonatomic, assign) double progress;
@property (nonatomic, assign) NSInteger cellRow;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, weak) id<KillProcessDelegate> killDelegate;



@property (nonatomic, strong) NSTextField *memoryField;
@property (nonatomic, strong) NSTextField *procField;
@property (nonatomic, strong) NSImageView *procImageView;
@property (nonatomic, strong) NSView *closeContainer;
@property (nonatomic, strong) NSImageView *closeImageView;


- (void)updateView:(LMMemoryItem *)memoryItem;

@end

NS_ASSUME_NONNULL_END
