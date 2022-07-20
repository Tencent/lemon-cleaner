//
//  BaseHoverTableCellView.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyResultViewController.h"

@interface BaseHoverTableCellView : NSTableCellView

@property (weak)PrivacyResultViewController *delegate;

- (void) addFullDiskAccessSetttingBtn;
- (void) removeFullDiskAccessViews;
@end
