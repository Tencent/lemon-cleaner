//
//  LMRootCellView.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMCheckboxButton.h"

@interface LMRootCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSTextField* titleLabel;
@property (nonatomic, strong) IBOutlet NSTextField* descLabel;

-(void)setCellData:(id)item;

@end
