//
//  LMPreviewTableCellView.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMPreviewTableCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSView* rootItemView;
@property (nonatomic, strong) IBOutlet NSView* subItemView;

@property (nonatomic, strong) IBOutlet NSButton* checkButton;

@end
