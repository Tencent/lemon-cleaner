//
//  ResultCellView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMPathBarView.h>
#import "BigCleanParaentCellView.h"
#import "QMResultItem.h"

@interface ResultCellView : BigCleanParaentCellView

@property (weak, nonatomic) IBOutlet LMPathBarView *pathBarView;
@property (weak, nonatomic) IBOutlet NSButton *showInFinderButton;
@property (strong, nonatomic) QMResultItem *resultItem;

@end
