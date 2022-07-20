//
//  ToolCellView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ToolModel.h"
#import <QMUICommon/LMBorderButton.h>

@interface ToolCellView : NSTableCellView

@property (strong, nonatomic) IBOutlet NSTextField* toolDesc;
@property (strong, nonatomic) IBOutlet LMBorderButton* experienceBtn;

-(void)setCellWithToolModel:(ToolModel *)toolModel;

@end
