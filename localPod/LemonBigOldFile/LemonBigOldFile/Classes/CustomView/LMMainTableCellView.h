//
//  LMMainTableCellView.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMMainTableCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSView* rootItemView;
@property (nonatomic, strong) IBOutlet NSView* subItemView;

@property (nonatomic, strong) IBOutlet NSTextField* rootTitleText;

@property (nonatomic, strong) IBOutlet NSButton* checkButton;
@property (nonatomic, strong) IBOutlet NSTextField* dateTextField;

- (void)showRootItemType;
- (void)showSubItemType;

@end
