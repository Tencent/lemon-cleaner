//
//  LMMainTableCellView.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMMainTableCellView.h"

@implementation LMMainTableCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)showRootItemType {
    self.rootItemView.hidden = NO;
    self.subItemView.hidden = YES;
}

- (void)showSubItemType { 
    self.rootItemView.hidden = YES;
    self.subItemView.hidden = NO;
}

@end
