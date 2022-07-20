//
//  AppResultTableCellView.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyData.h"
#import "BaseHoverTableCellView.h"

#define AFTER_FULL_DISK_PRIVACY_SEETING_NEED_RESCAN @"AFTER_FULL_DISK_PRIVACY_SEETING_NEED_RESCAN"

@interface PrivacyAppTableCellView : BaseHoverTableCellView

@property NSImageView *appImageView;
@property NSTextField *appNameLabel;
@property NSTextField *accountLabel;
@property NSTextField *countLabel;
@property NSButton    *checkButton;
@property BOOL        hasFullDiskAccessAuthority; //是否有完全磁盘访问权限(10.14(不含)系统下默认有).

- (void)updateViewBy:(PrivacyAppData *)appData;

@end
