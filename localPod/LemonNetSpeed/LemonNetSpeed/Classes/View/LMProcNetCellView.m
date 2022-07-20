//
//  LMProcNetCellView.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMProcNetCellView.h"
#import <QMUICommon/LMAppThemeHelper.h>

@implementation LMProcNetCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [LMAppThemeHelper setTitleColorForTextField: self.nameLabel];
    // Drawing code here.
}

@end
