//
//  ItemResultTableCellView.h
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrivacyData.h"
#import "BaseHoverTableCellView.h"


@interface PrivacyItemTableCellView : BaseHoverTableCellView

@property NSButton *checkButton;
@property NSTextField *itemLabel;
@property NSTextField *itemNumLabel;

- (void)updateViewBy:(PrivacyItemData *)itemData;

@end
