//
//  OutlineItemCellView.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/19.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CheckBoxUpdateDelegate.h"

@interface DuplicateSubItemCellView : NSTableCellView

@property(nonatomic) NSString *path;
@property(nonatomic) NSButton *checkBox;
@property(nonatomic) NSTextField *sizeText;
@property(nonatomic) NSTextField *modifyTimeText;
@property(nonatomic, weak) id <CheckBoxUpdateDelegate> checkBoxUpdateDelegate;

@property(nonatomic) QMDuplicateFile *item;
@property(nonatomic) NSButton *openFolderBtn;

- (void)updateViewsWithItem:(QMDuplicateFile *)item withPreview:(BOOL)isPreview;
@end
