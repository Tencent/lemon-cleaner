//
//  OutlineItemRootCellView.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/21.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "DuplicateSubItemCellView.h"
#import "LMDuplicateScanResultViewController.h"
#import "QMDuplicateBatch.h"

//最顶层的 Cell
@interface DuplicateRootCellView : NSTableCellView

@property(nonatomic) NSTextField *fileNameLabel;
@property(nonatomic) NSTextField *totalItemLabel;
@property(nonatomic) QMDuplicateBatch *item;
@property(nonatomic) NSButton *expandButton;

@property(nonatomic, weak) id <ExpandItemDelegate> expandItemDelegate;
@property(nonatomic, weak) id <CheckBoxUpdateDelegate> checkBoxUpdateDelegate;


- (void)updateViewsWithItem:(QMDuplicateBatch *)item withPreview:(BOOL)isPreview;

@end

