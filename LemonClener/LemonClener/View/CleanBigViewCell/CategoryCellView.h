//
//  CategoryCellView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BigCleanParaentCellView.h"
#import "CategoryProgressView.h"

@interface CategoryCellView : BigCleanParaentCellView

@property (weak, nonatomic) IBOutlet CategoryProgressView *categoryProgessView;
@property (weak, nonatomic) IBOutlet NSTextField *sizeSelectLabel;

@end
