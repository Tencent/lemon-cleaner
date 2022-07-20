//
//  CategoryReultTableCellView.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyData.h"
#import "BaseHoverTableCellView.h"


@interface PrivacyCategoryTableCellView : BaseHoverTableCellView


@property NSButton    *checkButton;
@property NSImageView *categoryImageView;
@property NSTextField *categoryLabel;
@property NSTextField *selectedNumLabel;
@property NSTextField *descLabel;

@property BOOL        belongSafari; //是否属于 safari 项,用于权限判断.
@property BOOL        hasFullDiskAccessAuthority; //是否有完全磁盘访问权限(10.14(不含)系统下默认有).


- (void)updateViewByItem:(PrivacyCategoryData *)categoryData;

@end
