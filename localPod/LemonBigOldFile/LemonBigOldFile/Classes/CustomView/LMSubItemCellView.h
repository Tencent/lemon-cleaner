//
//  LMSubItemCellView.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/LMPathBarView.h>

@interface LMSubItemCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet LMCheckboxButton* checkButton;
@property (nonatomic, strong) IBOutlet NSImageView* iconView;
@property (nonatomic, strong) IBOutlet NSTextField* titleLabel;
@property (nonatomic, strong) IBOutlet LMPathBarView *pathBarView;
@property (nonatomic, strong) IBOutlet NSButton* finderButton;
@property (nonatomic, strong) IBOutlet NSTextField* sizeLabel;

-(void)setCellData:(id)item;

@end
