//
//  QMBaseOutlineView.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMBaseOutlineView.h"

@implementation QMBaseOutlineView
@synthesize hideGroupMark;

//分组没有折叠的三角形
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
{
    if (hideGroupMark)
    {
        return NSZeroRect;
    }else
    {
        return [super frameOfOutlineCellAtRow:row];
    }
}

@end
