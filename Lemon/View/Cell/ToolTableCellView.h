//
//  ToolTableCellView.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LemonClener/ToolModel.h>

#define MORE_FUNCTION @"lemon_community"
#define LEMON_LAB @"lemon_lab"

extern const int LMToolWidth;
extern const int LMToolHeight;
extern const int LMToolTopSpace;
extern const int LMToolCellTopSpace;

typedef void (^ClickToolBlock)(NSString *className);

@interface ToolTableCellView : NSTableCellView

@property (nonatomic, strong) NSImageView *tagImage;

-(void)setCellWithToolModel:(ToolModel *) toolModel toolBlock:(ClickToolBlock) toolBlock;

@end
